{ ... }:
{
  flake.homeManagerModules.fizzy =
    { pkgs, lib, ... }:
    let
      runtime_libs = with pkgs; [
        gtk3
        wayland
        libxkbcommon
        libdecor
        libx11
        libxext
        libxcursor
        libxi
        libxfixes
        libxrandr
        libglvnd
        vulkan-loader
        dbus
      ];

      fizzy = pkgs.stdenv.mkDerivation (finalAttrs: {
        pname = "fizzy";
        version = "0.1.1";

        src = pkgs.fetchFromGitHub {
          owner = "fizzyedit";
          repo = "fizzy";
          rev = "8dbe4d12d84702fa704c2440d9951981d1e1d86e";
          hash = "sha256-0PP4iNEd6PC9aLYP6RcdCxg1DlymPKijQnbqSgnx8p8=";
        };

        # Two upstream fixes; TODO: drop when fixed upstream
        # (github.com/fizzyedit/fizzy). First: SDL passes files == NULL when
        # the dialog backend fails to launch; upstream walks it unchecked and
        # segfaults. Second: singleton shutdown close()s the listening socket
        # expecting the blocked accept() to return, but close() never wakes an
        # in-flight accept on Linux, so every quit hangs in thread.join with
        # the dead window left on screen; a self-connect wakes the listener.
        postPatch = ''
          substituteInPlace src/backend/backend_native.zig \
            --replace-fail \
              'while (files[path_count] != null) : (path_count += 1) {}' \
              'if (files != null) while (files[path_count] != null) : (path_count += 1) {};'
          substituteInPlace libs/dvui-singleton-app/src/unix_impl.zig \
            --replace-fail \
              'self.running.store(0, .release);' \
              'self.running.store(0, .release);
                  if (connectUnixClient(self.path)) |fd| _ = std.c.close(fd);'
        '';

        # `zig build --help` runs build.zig, which fetches the lazy deps the
        # native build actually needs; `zig_0_16.fetchDeps` misses those and
        # `fetchAll` drags in broken wasm-only git deps.
        zigDeps =
          pkgs.runCommand "${finalAttrs.pname}-${finalAttrs.version}-zig-pkg"
            {
              inherit (finalAttrs) src;
              nativeBuildInputs = [ pkgs.zig_0_16 ];
              outputHashAlgo = null;
              outputHashMode = "recursive";
              outputHash = "sha256-SBgxI236EN0tFXYw3feby6x8IrcxDUdTTJ0nswVJ550=";
            }
            ''
              export ZIG_GLOBAL_CACHE_DIR=$(mktemp -d)
              cp -r $src source
              chmod -R u+w source
              cd source
              zig build --help > /dev/null
              mv zig-pkg $out
            '';

        nativeBuildInputs = [
          pkgs.zig_0_16.hook
          pkgs.makeWrapper
          pkgs.git
        ];

        # Store plugins are published ReleaseFast only and the plugin ABI
        # fingerprint folds in the optimize mode, so the app must match.
        dontSetZigDefaultFlags = true;
        zigBuildFlags = [
          "-Dcpu=baseline"
          "-Doptimize=ReleaseFast"
        ];

        # The empty pinned commit satisfies nightwatch's `git describe` version
        # probe, which panics without a repository.
        postConfigure = ''
          cp -r ${finalAttrs.zigDeps} zig-pkg
          chmod -R u+w zig-pkg

          git init -q
          GIT_AUTHOR_DATE='1970-01-01T00:00:00Z' GIT_COMMITTER_DATE='1970-01-01T00:00:00Z' \
            git -c user.email=nix -c user.name=nix commit -q --allow-empty -m nix-build
        '';

        installPhase = ''
          runHook preInstall

          mkdir -p $out/bin $out/lib $out/share/pixmaps
          cp -r zig-out/x86-64-linux $out/lib/fizzy
          cp assets/icon.png $out/share/pixmaps/fizzy.png

          makeWrapper $out/lib/fizzy/fizzy $out/bin/fizzy \
            --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtime_libs}:/run/opengl-driver/lib

          runHook postInstall
        '';

        meta = {
          description = "Cross-platform modular editor with pixel art support via the pixi plugin";
          homepage = "https://github.com/fizzyedit/fizzy";
          license = lib.licenses.gpl3Only;
          mainProgram = "fizzy";
          platforms = [ "x86_64-linux" ];
        };
      });
    in
    {
      home.packages = [ fizzy ];

      xdg.desktopEntries.fizzy = {
        name = "Fizzy";
        comment = "Modular pixel art and text editor";
        exec = "fizzy";
        icon = "fizzy";
        categories = [
          "Graphics"
          "2DGraphics"
        ];
        terminal = false;
      };
    };
}
