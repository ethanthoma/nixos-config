{
  inputs,
  pkgs,
  username,
  ...
}:

let
  rocm-merged = pkgs.symlinkJoin {
    name = "rocm-merged";
    paths = with pkgs.rocmPackages; [
      clr
      hipcc
      rocm-core
      rocm-runtime
      rocm-comgr
      rocm-device-libs
      rocm-smi
      rocminfo
      rocblas
      hipblas
      hipblas-common
      hipblaslt
      rocfft
      hipfft
      rocrand
      hiprand
      rocsolver
      hipsolver
      rocsparse
      hipsparse
      rocprim
      hipcub
      rocthrust
      miopen
      rccl
      roctracer
      rocprofiler-register
      rocprofiler-sdk
      aqlprofile
    ];
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ./tailscale.nix
    ./tailnet.nix
    ./minecraft.nix
    ./minecraft-terra.nix
    "${inputs.tether}/tether.nix"
    ./codex-web.nix
    ./training-queue.nix
    ./pueue.nix
    ./runboard.nix
    ./nix-builder.nix
    ./home-alias.nix
    ./torrent.nix
  ];

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users = {
    root.hashedPassword = "!";

    ${username} = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "render"
        "video"
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHiAN7eu9G4A1OerVYGf+ixTU/gQJPtyRIBq5z/CRLex ethanthoma@gmail.com"
      ];
    };
  };

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    zstd
    openssl
    expat
    libxml2
    ncurses
    numactl
    elfutils
    libdrm
    libffi
    util-linux
  ];

  hardware.graphics.enable = true;
  hardware.graphics.extraPackages = [ pkgs.rocmPackages.clr.icd ];

  # Training held the RX 7900 XTX junction at 110-111 C (its critical limit) at the 339 W default cap. 305 W is the
  # firmware minimum. The cap is lost on reboot, so a oneshot sets it at boot, before the training queue starts.
  systemd.services.amdgpu-power-cap = {
    description = "Cap the amdgpu board power at 305 W";
    wantedBy = [ "multi-user.target" ];
    before = [ "training-queue.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      cap_microwatts=305000000
      found=0
      for hwmon in /sys/class/drm/card*/device/hwmon/hwmon*; do
        [ "$(cat "$hwmon/name" 2>/dev/null)" = amdgpu ] || continue
        minimum=$(cat "$hwmon/power1_cap_min")
        if [ "$cap_microwatts" -lt "$minimum" ]; then
          echo "cap $cap_microwatts is below the firmware minimum $minimum for $hwmon" >&2
          exit 1
        fi
        echo "$cap_microwatts" > "$hwmon/power1_cap"
        echo "$hwmon power1_cap now $(cat "$hwmon/power1_cap")"
        found=1
      done
      if [ "$found" -ne 1 ]; then
        echo "no amdgpu hwmon found" >&2
        exit 1
      fi
    '';
  };

  systemd.tmpfiles.rules = [
    "L+ /opt/rocm - - - - ${rocm-merged}"
  ];

  environment.variables.ROCM_PATH = "/opt/rocm";

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  networking.firewall.allowedTCPPorts = [
    22
    3000
    3001
  ];

  users.users.open-historia = {
    isSystemUser = true;
    group = "open-historia";
  };
  users.groups.open-historia = { };

  systemd.services.open-historia = {
    description = "Open Historia game server (node, port 3000)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    unitConfig.ConditionPathExists = "/var/lib/open-historia/server/server.js";
    serviceConfig = {
      ExecStart = "${pkgs.nodejs_22}/bin/node server/server.js";
      WorkingDirectory = "/var/lib/open-historia";
      EnvironmentFile = "/var/lib/open-historia.env";
      User = "open-historia";
      Group = "open-historia";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  users.users.dojo = {
    isSystemUser = true;
    group = "dojo";
  };
  users.groups.dojo = { };

  systemd.services.dojo = {
    description = "dojo self-study server (port 3001)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    unitConfig.ConditionPathExists = "/var/lib/dojo/dojo";
    serviceConfig = {
      ExecStart = "/var/lib/dojo/dojo";
      WorkingDirectory = "/var/lib/dojo";
      EnvironmentFile = "/var/lib/dojo.env";
      User = "dojo";
      Group = "dojo";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  time.timeZone = "America/Vancouver";
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  environment.systemPackages = [
    pkgs.git
    pkgs.neovim
    pkgs.tmux
    pkgs.fzf
    pkgs.lm_sensors
    pkgs.ipmitool
    pkgs.uv
    pkgs.amdgpu_top
    pkgs.rocmPackages.rocminfo
    pkgs.rocmPackages.rocm-smi
  ];

  boot.kernelModules = [
    "ipmi_devintf"
    "ipmi_si"
  ];

  services.cloudflared = {
    enable = true;
    tunnels."93c151d8-b148-4fb8-b256-e1a67e45c601" = {
      credentialsFile = "/var/lib/cloudflared/atlas-llm.json";
      default = "http_status:404";
    };
  };

  systemd.services.bmc-fan-fix = {
    description = "pin FAN2/FAN3 at 50% duty so the BMC fan-fail boost never triggers";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ipmi() { for i in 1 2 3 4 5; do ${pkgs.ipmitool}/bin/ipmitool "$@" && return 0; sleep 5; done; return 1; }
      ipmi raw 0x3a 0xd0 0x11 0x0 0x2 0x2 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0 0x0
      ipmi raw 0x3a 0xd0 0x0e 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32 0x32
      ipmi sensor thresh FAN2 lower 0 0 0
      ipmi sensor thresh FAN3 lower 0 0 0
    '';
  };

  system.stateVersion = "25.05";
}
