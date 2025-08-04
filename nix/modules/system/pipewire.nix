{ pkgs, ... }:

let
  hwSink = "alsa_output.pci-0000_02_02.0.analog-stereo";
  hwSource = "alsa_input.pci-0000_02_02.0.analog-stereo";

  mkAppChain =
    {
      name,
      desc,
      thresh ? -14.0,
    }:
    {
      name = "libpipewire-module-filter-chain";
      args = {
        "capture.props" = {
          "node.name" = "App: ${name}";
          "node.description" = "App: ${desc}";
          "media.class" = "Audio/Sink";
          "audio.position" = "FL,FR";
        };
        "playback.props" = {
          "node.name" = "${name}(Processed)";
          "node.description" = "${desc} (Processed)";
          "media.class" = "Audio/Source";
        };
        "filter.graph" = {
          nodes = [
            {
              type = "ladspa";
              plugin = "${pkgs.ladspaPlugins}/lib/ladspa/fast_lookahead_limiter_1913.so";
              label = "fastLookaheadLimiter";
              control = {
                "Input gain (dB)" = 0.0;
                "Limit (dB)" = thresh;
                "Release time (s)" = 0.1;
              };
            }
          ];
        };
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
  ];
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire-pulse."99-app-routing.conf" = {
      "pulse.rules" = [
        {
          matches = [ { "application.process.binary" = "librewolf"; } ];
          actions = {
            "update-props" = {
              "node.target" = "App: Browser";
            };
          };
        }
        {
          matches = [ { "application.process.binary" = "firefox"; } ];
          actions = {
            "update-props" = {
              "node.target" = "App: Browser";
            };
          };
        }
        {
          matches = [ { "application.process.binary" = "spotify"; } ];
          actions = {
            "update-props" = {
              "node.target" = "App: Music";
            };
          };
        }
        {
          matches = [ { "application.process.binary" = "discord"; } ];
          actions = {
            "update-props" = {
              "node.target" = "App: Discord";
            };
          };
        }
        {
          matches = [ { "media.class" = "Stream/Output/Audio"; } ];
          actions = {
            "update-props" = {
              "node.target" = "App: System";
            };
          };
        }
      ];
    };

    extraConfig.pipewire = {
      "10-virtual-devices.conf" = {
        "context.objects" = [
          {
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "Mix: Main";
              "node.description" = "Mix: Main (for Headphones)";
              "media.class" = "Audio/Sink";
              "audio.position" = "FL,FR";
            };
          }
          {
            factory = "adapter";
            args = {
              "factory.name" = "support.null-audio-sink";
              "node.name" = "Mix: Stream";
              "node.description" = "Mix: Stream (for OBS)";
              "media.class" = "Audio/Sink";
              "audio.position" = "FL,FR";
            };
          }
        ];
      };

      "20-processing-and-linking.conf" = {
        "context.modules" = [
          (mkAppChain {
            name = "Browser";
            desc = "Browser";
          })
          (mkAppChain {
            name = "Music";
            desc = "Music";
            thresh = -12.0;
          })
          (mkAppChain {
            name = "Discord";
            desc = "Discord";
          })
          (mkAppChain {
            name = "System";
            desc = "System";
          })

          {
            name = "libpipewire-module-filter-chain";
            args = {
              "capture.props" = {
                "node.name" = "MicRaw";
                "node.target" = hwSource;
                "node.description" = "Mic (Raw)";
              };
              "playback.props" = {
                "node.name" = "MicFiltered";
                "node.description" = "Source: Mic (Filtered)";
                "media.class" = "Audio/Source";
              };
              "filter.graph" = {
                nodes = [
                  {
                    type = "ladspa";
                    plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                    label = "noise_suppressor_stereo";
                    control = {
                      "VAD Threshold (%)" = 50.0;
                    };
                  }
                ];
              };
            };
          }

          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Browser -> Main Mix";
              "capture.props" = {
                "node.target" = "Browser(Processed)";
              };
              "playback.props" = {
                "node.target" = "Mix: Main";
              };
            };
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Music -> Main Mix";
              "capture.props" = {
                "node.target" = "Music(Processed)";
              };
              "playback.props" = {
                "node.target" = "Mix: Main";
              };
            };
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Discord -> Main Mix";
              "capture.props" = {
                "node.target" = "Discord(Processed)";
              };
              "playback.props" = {
                "node.target" = "Mix: Main";
              };
            };
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "System -> Main Mix";
              "capture.props" = {
                "node.target" = "System(Processed)";
              };
              "playback.props" = {
                "node.target" = "Mix: Main";
              };
            };
          }

          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Browser -> Stream Mix";
              "capture.props" = {
                "node.target" = "Browser(Processed)";
              };
              "playback.props" = {
                "node.target" = "Mix: Stream";
              };
            };
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Music -> Stream Mix";
              "capture.props" = {
                "node.target" = "Music(Processed)";
              };
              "playback.props" = {
                "node.target" = "Mix: Stream";
              };
            };
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Discord -> Stream Mix";
              "capture.props" = {
                "node.target" = "Discord(Processed)";
              };
              "playback.props" = {
                "node.target" = "Mix: Stream";
              };
            };
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "System -> Stream Mix";
              "capture.props" = {
                "node.target" = "System(Processed)";
              };
              "playback.props" = {
                "node.target" = "Mix: Stream";
              };
            };
          }
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "Mic -> Stream Mix";
              "capture.props" = {
                "node.target" = "MicFiltered";
              };
              "playback.props" = {
                "node.target" = "Mix: Stream";
              };
            };
          }

          # --- Final Output Chains ---
          # Main Mix -> EQ -> Hardware Sink
          {
            name = "libpipewire-module-filter-chain";
            args = {
              "capture.props" = {
                "node.name" = "MainMixEQ";
                "node.description" = "EQ for Headphones";
                "media.class" = "Audio/Sink";
                "audio.channels" = 2;
                "node.target" = "Mix: Main";
                "stream.monitor" = true;
              };
              "playback.props" = {
                "node.target" = hwSink;
              };
              "filter.graph" = {
                nodes = [
                  {
                    type = "ladspa";
                    plugin = "${pkgs.cmt}/lib/ladspa/cmt.so";
                    label = "amp_stereo";
                    control = {
                      Gain = 0.5;
                    };
                  }
                  {
                    type = "ladspa";
                    plugin = "${pkgs.lsp-plugins}/lib/ladspa/lsp-plugins-ladspa.so";
                    label = "http://lsp-plug.in/plugins/ladspa/para_equalizer_x16_stereo";
                    control = {
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
            name = "libpipewire-module-loopback";
            args = {
              "capture.props" = {
                "node.target" = "Mix: Stream";
                "stream.monitor" = true;
              };
              "playback.props" = {
                "media.class" = "Audio/Source";
                "node.name" = "VirtualMic";
                "node.description" = "Input: Stream Mix";
              };
            };
          }
        ];
      };
    };
  };
}
