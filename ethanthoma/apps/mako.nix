{ ... }:

{
  services.mako = {
    enable = true;
    defaultTimeout = 4000;
    extraConfig = ''
      border-radius=10
      border-size=2

      background-color=#191724
      text-color=#e0def4
      border-color=#f6c177
      progress-color=over #1f1d2e

      [urgency=high]
      border-color=#eb6f92
    '';
  };
}
