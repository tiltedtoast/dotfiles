{ pkgs, ... }:

let
  hwSink = "alsa_output.pci-0000_02_02.0.analog-stereo";
  hwSource = "alsa_input.pci-0000_02_02.0.analog-stereo";

  mkAppChain =
    {
      name,
      thresh ? -14.0,
    }:
    {
      name = "libpipewire-module-filter-chain";
      args = {
        "capture.props" = {
          "node.name" = "App_${name}";
          "node.description" = "App ${name} (raw)";
          "media.class" = "Audio/Sink";
          "audio.position" = "FL,FR";
        };
        "playback.props" = {
          "node.name" = "${name}Processed";
          "node.description" = "${name} (processed)";
          "media.class" = "Audio/Source";
        };
        "filter.graph" = {
          nodes = [
            {
              type = "ladspa";
              plugin = "${pkgs.ladspaPlugins}/lib/ladspa/fast_lookahead_limiter_1913.so";
              label = "fastLookaheadLimiter";
              control = {
                "Limit (dB)" = thresh;
                "Release time (s)" = 0.1;
              };
            }
          ];
        };
      };
    };

  mkMainLoopback = name: {
    name = "libpipewire-module-loopback";
    args = {
      "node.description" = "${name} ➜ Main";
      "capture.props"."node.target" = "${name}Processed";
      "playback.props"."node.target" = "MainEQ";
    };
  };

in
{
  environment.systemPackages = with pkgs; [
    helvum
    qpwgraph
    ladspaPlugins
    rnnoise-plugin
    cmt
    lsp-plugins
  ];
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    wireplumber.extraConfig."99-alsa-rules" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = hwSink; } ];
          actions.update-props = {
            "api.alsa.period-num" = 32;
            "api.alsa.headroom" = 8192;
            "api.alsa.disable-tsched" = true;
          };
        }
        {
          matches = [ { "node.name" = hwSource; } ];
          actions.update-props = {
            "api.alsa.period-num" = 32;
            "api.alsa.headroom" = 8192;
            "api.alsa.disable-tsched" = true;
          };
        }
      ];
    };

    # PulseAudio routing rules
    extraConfig.pipewire-pulse."99-app-routing.conf" = {
      "pulse.rules" = [
        {
          matches = [ { "application.name" = "~.*"; } ];
          actions.update-props."node.target" = "App_System";
        }
        {
          matches = [ { "application.name" = "~(LibreWolf|Firefox)"; } ];
          actions.update-props."node.target" = "App_Browser";
        }
        {
          matches = [ { "application.process.binary" = "spotify"; } ];
          actions.update-props."node.target" = "App_Music";
        }
        {
          matches = [ { "application.process.binary" = "discord"; } ];
          actions.update-props."node.target" = "App_Discord";
        }
      ];
    };

    extraConfig.pipewire."10-processing-and-linking.conf" = {
      "context.modules" = [

        # --- Application Limiters ---
        (mkAppChain { name = "Browser"; })
        (mkAppChain {
          name = "Music";
          thresh = -12;
        })
        (mkAppChain { name = "Discord"; })
        (mkAppChain { name = "System"; })

        # --- Route Apps to the Main EQ Sink ---
        (mkMainLoopback "Browser")
        (mkMainLoopback "Music")
        (mkMainLoopback "Discord")
        (mkMainLoopback "System")

        # --- Microphone Processing ---
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "capture.props" = {
              "node.name" = "MicRaw";
              "media.class" = "Audio/Sink";
            };
            "playback.props" = {
              "node.name" = "MicFiltered";
              "media.class" = "Audio/Source";
            };
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                  label = "noise_suppressor_stereo";
                  control."VAD Threshold (%)" = 50.0;
                }
              ];
            };
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.description" = "HW-Mic ➜ MicRaw";
            "capture.props"."node.target" = hwSource;
            "playback.props"."node.target" = "MicRaw";
          };
        }

        # --- Headphone EQ + Preamp ---
        {
          name = "libpipewire-module-filter-chain";
          args = {
            "capture.props" = {
              "node.name" = "MainEQ";
              "node.description" = "Main Mix (Post-EQ)";
              "media.class" = "Audio/Sink";
              "audio.position" = "FL,FR";
            };
            "playback.props" = {
              "node.target" = hwSink;
            };
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "${pkgs.lsp-plugins}/lib/ladspa/lsp-plugins-ladspa.so";
                  label = "http://lsp-plug.in/plugins/ladspa/para_equalizer_x16_stereo";
                  control = {
                    "Input gain (G)" = 0.5;

                    "Frequency 0 (Hz)" = 42.0;
                    "Gain 0 (G)" = 2.317;
                    "Quality factor 0" = 1.0;

                    "Frequency 1 (Hz)" = 143.0;
                    "Gain 1 (G)" = 0.562;
                    "Quality factor 1" = 1.0;

                    "Frequency 2 (Hz)" = 1524.0;
                    "Gain 2 (G)" = 0.649;
                    "Quality factor 2" = 1.0;

                    "Frequency 3 (Hz)" = 3845.0;
                    "Gain 3 (G)" = 0.316;
                    "Quality factor 3" = 1.0;

                    "Frequency 4 (Hz)" = 6520.0;
                    "Gain 4 (G)" = 2.455;
                    "Quality factor 4" = 1.0;

                    "Frequency 5 (Hz)" = 2492.0;
                    "Gain 5 (G)" = 1.259;
                    "Quality factor 5" = 1.0;

                    "Frequency 6 (Hz)" = 3108.0;
                    "Gain 6 (G)" = 0.750;
                    "Quality factor 6" = 1.0;

                    "Frequency 7 (Hz)" = 4006.0;
                    "Gain 7 (G)" = 1.275;
                    "Quality factor 7" = 1.0;

                    "Frequency 8 (Hz)" = 4816.0;
                    "Gain 8 (G)" = 0.859;
                    "Quality factor 8" = 1.0;

                    "Frequency 9 (Hz)" = 6050.0;
                    "Gain 9 (G)" = 1.148;
                    "Quality factor 9" = 1.0;
                  };
                }
              ];
            };
          };
        }

        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "Mix_Stream";
            "node.description" = "Mix: Stream (OBS)";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.description" = "Mic ➜ Stream mix";
            "capture.props"."node.target" = "MicFiltered";
            "playback.props"."node.target" = "Mix_Stream";
          };
        }
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.description" = "Stream mix ➜ VirtualMic";
            "capture.props" = {
              "node.target" = "Mix_Stream";
              "stream.monitor" = true;
            };
            "playback.props" = {
              "media.class" = "Audio/Source";
              "node.name" = "VirtualMic";
              "node.description" = "Input: Stream mix";
            };
          };
        }
      ];
    };
  };
}
