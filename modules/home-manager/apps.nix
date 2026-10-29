{ inputs, ... }:
{
  flake.homeManagerModules.apps =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      hatchzip = pkgs.appimageTools.wrapType2 rec {
        pname = "hatchzip";
        version = "0.1.8";
        src = pkgs.fetchurl {
          url = "https://github.com/xevrion/hatchzip/releases/download/v${version}/HatchZip-x86_64.AppImage";
          hash = "sha256-OgbZLcGg+kt+mIbKLup7j+GKXshrCDY567YLespJfy0=";
        };
        extraInstallCommands =
          let
            contents = pkgs.appimageTools.extract { inherit pname version src; };
          in
          ''
            install -Dm644 ${contents}/io.github.xevrion.hatchzip.desktop $out/share/applications/io.github.xevrion.hatchzip.desktop
            substituteInPlace $out/share/applications/io.github.xevrion.hatchzip.desktop --replace-fail 'Exec=hatchzip-gui' 'Exec=hatchzip'
            cp -r ${contents}/usr/share/icons $out/share/
          '';
      };
    in
    {
      home.packages = [
        hatchzip
        pkgs.gh
        pkgs.tre
        pkgs.wget
        pkgs.zip
        pkgs.entr
        pkgs.trashy
        pkgs.yq-go
        pkgs.bat
        pkgs.ripgrep
        pkgs.fd
        pkgs.sd
        pkgs.unzip
        pkgs.fastfetch
        pkgs.nix-index
        pkgs.brightnessctl
        pkgs.jq
        pkgs.nil
        pkgs.dust
        pkgs.duf

        # recording
        # obs dlopens libnvidia-encode.so.1 by name; nixpkgs' wrapper doesn't put
        # /run/opengl-driver/lib on the search path, so nvenc is invisible.
        (pkgs.symlinkJoin {
          name = "obs-studio-nvenc";
          paths = [ pkgs.obs-studio ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/obs --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
          '';
        })
        pkgs.mpv
        pkgs.kdePackages.dolphin

        # meetings
        pkgs.zoom-us

        # audio
        pkgs.spotify
        pkgs.ardour
        pkgs.qpwgraph

        # games
        pkgs.prismlauncher
        inputs.r2modman.legacyPackages.${pkgs.stdenv.hostPlatform.system}.r2modman

        # backup
        pkgs.rclone
      ];

      home.activation.hatchzipSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -e "$HOME/.config/hatchzip/settings.json" ]; then
          run mkdir -p "$HOME/.config/hatchzip"
          run cp ${
            pkgs.writeText "hatchzip-settings.json" (builtins.toJSON { keep_archive = true; })
          } "$HOME/.config/hatchzip/settings.json"
          run chmod u+w "$HOME/.config/hatchzip/settings.json"
        fi
      '';

      xdg.portal = {
        enable = lib.mkForce true;
        extraPortals = [
          pkgs.xdg-desktop-portal-hyprland
          pkgs.xdg-desktop-portal-gtk
          pkgs.kdePackages.xdg-desktop-portal-kde
        ];
        config.common = {
          default = [
            "hyprland"
            "gtk"
          ];
          "org.freedesktop.impl.portal.AppChooser" = [ "gtk" ];
          "org.freedesktop.impl.portal.FileChooser" = [ "kde" ];
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "application/zip" = [ "io.github.xevrion.hatchzip.desktop" ];
          "application/x-zip-compressed" = [ "io.github.xevrion.hatchzip.desktop" ];
          "application/x-7z-compressed" = [ "io.github.xevrion.hatchzip.desktop" ];
          "application/x-tar" = [ "io.github.xevrion.hatchzip.desktop" ];
          "application/x-compressed-tar" = [ "io.github.xevrion.hatchzip.desktop" ];
          "application/vnd.rar" = [ "io.github.xevrion.hatchzip.desktop" ];
          "application/x-rar" = [ "io.github.xevrion.hatchzip.desktop" ];
          "application/x-rar-compressed" = [ "io.github.xevrion.hatchzip.desktop" ];
          "inode/directory" = [ "org.kde.dolphin.desktop" ];
          "application/x-extension-htm" = [ "zen.desktop" ];
          "application/x-extension-html" = [ "zen.desktop" ];
          "application/x-extension-shtml" = [ "zen.desktop" ];
          "application/x-extension-xht" = [ "zen.desktop" ];
          "application/x-extension-xhtml" = [ "zen.desktop" ];
          "application/xhtml+xml" = [ "zen.desktop" ];
          "text/html" = [ "zen.desktop" ];
          "x-scheme-handler/about" = [ "helium.desktop" ];
          "x-scheme-handler/chrome" = [ "zen.desktop" ];
          "x-scheme-handler/claude-cli" = [ "claude-code-url-handler.desktop" ];
          "x-scheme-handler/codex" = [ "chatgpt.desktop" ];
          "x-scheme-handler/http" = [ "zen.desktop" ];
          "x-scheme-handler/https" = [ "zen.desktop" ];
          "x-scheme-handler/ror2mm" = [ "r2modman.desktop" ];
          "x-scheme-handler/unknown" = [ "helium.desktop" ];
          "video/mp4" = [ "mpv.desktop" ];
          "video/mpeg" = [ "mpv.desktop" ];
          "video/ogg" = [ "mpv.desktop" ];
          "video/quicktime" = [ "mpv.desktop" ];
          "video/webm" = [ "mpv.desktop" ];
          "video/x-flv" = [ "mpv.desktop" ];
          "video/x-matroska" = [ "mpv.desktop" ];
          "video/x-msvideo" = [ "mpv.desktop" ];
          "video/x-ms-wmv" = [ "mpv.desktop" ];
        };
        associations.added = {
          "application/x-extension-htm" = [ "userapp-Zen-FHKEL3.desktop" ];
          "application/x-extension-html" = [ "userapp-Zen-FHKEL3.desktop" ];
          "application/x-extension-shtml" = [ "userapp-Zen-FHKEL3.desktop" ];
          "application/x-extension-xht" = [ "userapp-Zen-FHKEL3.desktop" ];
          "application/x-extension-xhtml" = [ "userapp-Zen-FHKEL3.desktop" ];
          "application/xhtml+xml" = [ "userapp-Zen-FHKEL3.desktop" ];
          "text/html" = [
            "userapp-Zen-FHKEL3.desktop"
            "zen.desktop"
          ];
          "x-scheme-handler/chrome" = [
            "zen.desktop"
            "userapp-Zen-FHKEL3.desktop"
          ];
          "x-scheme-handler/http" = [
            "zen.desktop"
            "userapp-Zen-FHKEL3.desktop"
          ];
          "x-scheme-handler/https" = [
            "zen.desktop"
            "userapp-Zen-FHKEL3.desktop"
          ];
        };
      };

      programs.bash = {
        enable = true;
        enableCompletion = true;
        bashrcExtra = ''
          mkdir -p ${config.home.homeDirectory}/.config

          # trashy speaks the freedesktop trash spec, so `rm` and oil.nvim share
          # one ~/.local/share/Trash and `trash list`/`trash restore` see both.
          # trashy errors on rm-style flags, so drop them before handing it paths.
          rm() {
            local paths=()
            for arg in "$@"; do
              [[ $arg == -* ]] || paths+=("$arg")
            done
            trash put -- "''${paths[@]}"
          }

          alias cat='bat'
          alias find='fd'
          alias du='dust'
          alias df='duf'
        '';
      };
    };
}
