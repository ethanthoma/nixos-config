{ inputs, self, ... }:
{
  flake.nixosConfigurations.k3s-test = inputs.nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    modules = [
      ({ modulesPath, ... }: {
        imports = [ (modulesPath + "/virtualisation/qemu-vm.nix") ];
        networking.hostName = "k3s-test";
        system.stateVersion = "26.11";
        virtualisation = {
          graphics = false;
          cores = 4;
          memorySize = 4096;
          diskSize = 32768;
          diskImage = "/home/ethanthoma/.local/share/k3s-test/root.qcow2";
          forwardPorts = [
            {
              host.address = "127.0.0.1";
              host.port = 16443;
              guest.port = 16443;
            }
          ];
          sharedDirectories.kubeconfig = {
            source = "/home/ethanthoma/.config/k3s-test";
            target = "/host-kubeconfig";
            writable = true;
          };
        };
        services.k3s = {
          enable = true;
          role = "server";
          extraFlags = [
            "--write-kubeconfig=/host-kubeconfig/config"
            "--write-kubeconfig-mode=0600"
            "--https-listen-port=16443"
            "--snapshotter=native"
            "--tls-san=127.0.0.1"
          ];
        };
        systemd.services.k3s.unitConfig.RequiresMountsFor = [ "/host-kubeconfig" ];
        networking.firewall = {
          allowedTCPPorts = [ 16443 ];
          trustedInterfaces = [
            "cni0"
            "flannel.1"
          ];
        };
      })
    ];
  };

  flake.nixosModules.k3s = { config, pkgs, ... }: {
    environment.systemPackages = [ pkgs.kubectl ];
    users.users.ethanthoma.extraGroups = [ "kvm" ];
    systemd.tmpfiles.rules = [
      "d /home/ethanthoma/.local/share/k3s-test 0700 ethanthoma users -"
      "d /home/ethanthoma/.config/k3s-test 0700 ethanthoma users -"
    ];
    systemd.services.k3s-test = {
      description = "Local k3s test VM";
      after = [ "systemd-tmpfiles-setup.service" ];
      serviceConfig = {
        User = "ethanthoma";
        Group = "users";
        SupplementaryGroups = [ "kvm" ];
        RuntimeDirectory = "k3s-test";
        RuntimeDirectoryMode = "0700";
        ExecStart = "${self.nixosConfigurations.k3s-test.config.system.build.vm}/bin/run-k3s-test-vm -monitor unix:/run/k3s-test/monitor,server,nowait";
        ExecStop = [
          "${pkgs.socat}/bin/socat -u OPEN:${pkgs.writeText "k3s-test-powerdown" "system_powerdown\n"},rdonly UNIX-CONNECT:/run/k3s-test/monitor"
          "${pkgs.coreutils}/bin/timeout 110 ${pkgs.coreutils}/bin/tail --pid=$MAINPID -f /dev/null"
        ];
        WorkingDirectory = "/home/ethanthoma/.local/share/k3s-test";
        Restart = "on-failure";
        RestartSec = 10;
        TimeoutStopSec = 120;
      };
    };
    home-manager.users.ethanthoma.home.sessionVariables.KUBECONFIG =
      "${config.users.users.ethanthoma.home}/.config/k3s-test/config";
  };
}
