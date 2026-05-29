{ ... }:
{
  flake.nixosModules.yubikey-pam =
    { pkgs, ... }:
    let
      # Public key handle + pubkey from `pamu2fcfg --origin pam://nixos --appid pam://nixos`.
      # Not secret (the private key never leaves the YubiKey). Registered with a fixed
      # origin so the same mapping validates on every host. Append a second key as an
      # extra colon-separated credential when the backup YubiKey arrives.
      u2fMappings = pkgs.writeText "u2f-mappings" ''
        ethanthoma:6S0IPlHejT2f3PZPS/K4KI7TyjCyxa+Sk6uMdYuH4j6w3XjbN5u560tgBdpNouKn8kTVdxml9bmYdxxABUc/xw==,mWHGpVNVcYN1Fv4PnO0XfOLLlSgG3A9rhEvJn/je+oGf5HxyZMx1aGTT1+0PPYxm5IpJ0U0bnzeKEE05xwdcNA==,es256,+presence
      '';
    in
    {
      security.pam.u2f = {
        enable = true;
        control = "sufficient"; # touch OR password — password stays as fallback
        settings = {
          authfile = u2fMappings;
          origin = "pam://nixos";
          appid = "pam://nixos";
          cue = true; # print "touch your key" so the prompt doesn't look hung
        };
      };

      security.pam.services = {
        sudo.u2f.enable = true;
        su.u2f.enable = true;
        polkit-1.u2f.enable = true;
      };
    };
}
