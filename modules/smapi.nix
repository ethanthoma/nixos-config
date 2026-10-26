{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.smapi = pkgs.stdenvNoCC.mkDerivation (final: {
        pname = "smapi";
        version = "4.5.2";

        src = pkgs.fetchurl {
          url = "https://github.com/Pathoschild/SMAPI/releases/download/${final.version}/SMAPI-${final.version}-installer.zip";
          hash = "sha256-3QHdyntWa/4NOz0tA4M0lqvFbFPal2JB8qtEP1SErMQ=";
        };

        nativeBuildInputs = [
          pkgs.unzip
          pkgs.makeWrapper
        ];

        dontConfigure = true;
        dontBuild = true;
        dontFixup = true;

        installPhase = ''
          runHook preInstall
          mkdir -p "$out/lib/smapi" "$out/bin"
          cp -r internal/linux/. "$out/lib/smapi/"
          chmod +x "$out/lib/smapi/SMAPI.Installer"
          makeWrapper ${lib.getExe pkgs.steam-run} "$out/bin/smapi" \
            --add-flags env \
            --add-flags TMPDIR=/tmp \
            --add-flags "$out/lib/smapi/SMAPI.Installer"
          runHook postInstall
        '';

        meta = {
          description = "Stardew Valley mod loader installer with a NixOS runtime";
          homepage = "https://smapi.io/";
          license = lib.licenses.lgpl3Only;
          platforms = [ "x86_64-linux" ];
          mainProgram = "smapi";
        };
      });
    };
}
