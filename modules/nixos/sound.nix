{ ... }:
{
  flake.nixosModules.sound =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.lxqt.pavucontrol-qt
      ];

      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;

        extraLadspaPackages = [ pkgs.deepfilternet ];

        extraConfig.pipewire."99-noise-canceling-source" = {
          "context.modules" = [
            {
              name = "libpipewire-module-filter-chain";
              args = {
                "node.description" = "Noise Canceling Source";
                "media.name" = "Noise Canceling Source";
                "filter.graph" = {
                  nodes = [
                    {
                      type = "ladspa";
                      name = "deepfilter";
                      plugin = "libdeep_filter_ladspa";
                      label = "deep_filter_mono";
                      control = {
                        "Attenuation Limit (dB)" = 100.0;
                      };
                    }
                  ];
                };
                "capture.props" = {
                  "node.name" = "capture.deepfilter_source";
                  "node.passive" = true;
                  "audio.rate" = 48000;
                };
                "playback.props" = {
                  "node.name" = "deepfilter_source";
                  "media.class" = "Audio/Source";
                  "audio.rate" = 48000;
                };
              };
            }
            {
              name = "libpipewire-module-filter-chain";
              args = {
                "node.description" = "Noise Canceling Sink";
                "media.name" = "Noise Canceling Sink";
                "filter.graph" = {
                  nodes = [
                    {
                      type = "ladspa";
                      name = "deepfilter";
                      plugin = "libdeep_filter_ladspa";
                      label = "deep_filter_stereo";
                      control = {
                        "Attenuation Limit (dB)" = 100.0;
                      };
                    }
                  ];
                  inputs = [
                    "deepfilter:Audio In L"
                    "deepfilter:Audio In R"
                  ];
                  outputs = [
                    "deepfilter:Audio Out L"
                    "deepfilter:Audio Out R"
                  ];
                };
                "capture.props" = {
                  "node.name" = "deepfilter_sink";
                  "media.class" = "Audio/Sink";
                  "audio.rate" = 48000;
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                };
                "playback.props" = {
                  "node.name" = "playback.deepfilter_sink";
                  "node.passive" = true;
                  "audio.rate" = 48000;
                  "audio.position" = [
                    "FL"
                    "FR"
                  ];
                };
              };
            }
          ];
        };
      };
    };
}
