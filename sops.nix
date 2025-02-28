{ config, ... }:

{
  config.sops = {
    age = {
      keyFile = "/var/lib/sops-nix/key.txt";
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      generateKey = true;
    };

    secrets =
      let
        owner = config.users.users.ethanthoma.name;

        mode = {
          read = "0400";
          read_write = "0600";
          full = "0700";
        };
      in
      {
        cwlUsername = {
          inherit owner;
          mode = mode.read;
          sopsFile = ./keys/cwl_secrets.enc.yaml;
          key = "username";
        };
        cwlPassword = {
          inherit owner;
          mode = mode.read;
          sopsFile = ./keys/cwl_secrets.enc.yaml;
          key = "password";
        };
      };

    templates = {
      ubcVPN = {
        content = ''
          ${config.sops.placeholder.cwlUsername}
          ${config.sops.placeholder.cwlPassword}
        '';
      };
    };
  };
}
