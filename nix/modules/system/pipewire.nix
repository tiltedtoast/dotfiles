{ pkgs, ... }:

################################################################################
#  0.  Hardware devices  ───────────────────────────────────────────────────────
################################################################################
let
  hwSink = "alsa_output.pci-0000_02_02.0.analog-stereo"; # headphones / DAC
  hwSource = "alsa_input.pci-0000_02_02.0.analog-stereo"; # microphone

  ################################################################################
  #  1.  Helpers  ────────────────────────────────────────────────────────────────
  ################################################################################

  # 1.1  Per-application limiter
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
                "Input gain (dB)" = 0.0;
                "Limit (dB)" = thresh;
                "Release time (s)" = 0.1;
              };
            }
          ];
        };
      };
    };

  # 1.2  Loopback that feeds a processed stream into the Main mix
  mkMainLoopback = name: {
    name = "libpipewire-module-loopback";
    args = {
      "node.description" = "${name} ➜ Main";
      "capture.props"."node.target" = "${name}Processed";
      "playback.props"."node.target" = "Mix_Main";
    };
  };

in
################################################################################
#  2.  Module proper  ──────────────────────────────────────────────────────────
################################################################################
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

    # 2.1  Pulse routing rules
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

    # 2.2  Virtual sinks for the two mixes
    extraConfig.pipewire."10-virtual-devices.conf" = {
      "context.objects" = [
        {
          factory = "adapter";
          args = {
            "factory.name" = "support.null-audio-sink";
            "node.name" = "Mix_Main";
            "node.description" = "Mix: Main (Headphones)";
            "media.class" = "Audio/Sink";
            "audio.position" = "FL,FR";
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
      ];
    };

    # 2.3  All processing modules & connections
    extraConfig.pipewire."20-processing-and-linking.conf" = {
      "context.modules" = [

        # --- Application Limiters ---
        (mkAppChain { name = "Browser"; })
        (mkAppChain {
          name = "Music";
          thresh = -12;
        })
        (mkAppChain { name = "Discord"; })
        (mkAppChain { name = "System"; })

        # --- Microphone Processing (RNNoise) ---
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

        # --- Route Apps to Main Mix ---
        (mkMainLoopback "Browser")
        (mkMainLoopback "Music")
        (mkMainLoopback "Discord")
        (mkMainLoopback "System")

        # --- Route Mic to Stream Mix ---
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.description" = "Mic ➜ Stream mix";
            "capture.props"."node.target" = "MicFiltered";
            "playback.props"."node.target" = "Mix_Stream";
          };
        }

        # --- Main Mix EQ Processing ---
        # NOTE: The loopback from the previous attempt has been REMOVED.
        # We now configure the filter-chain to capture directly.
        {
          name = "libpipewire-module-filter-chain";
          args = {
            # THIS IS THE CRITICAL CHANGE: We capture directly from the monitor source.
            "capture.props" = {
              "node.name" = "HeadphoneEQ";
              "target.object" = "Mix_Main.monitor";
            };
            "playback.props" = {
              "node.name" = "HeadphoneSignal";
              "node.description" = "Headphone EQ (Output)";
              "media.class" = "Audio/Source";
            };
            "filter.graph" = {
              nodes = [
                {
                  type = "ladspa";
                  plugin = "${pkgs.cmt}/lib/ladspa/cmt.so";
                  label = "amp_stereo";
                  control.Gain = 0.5;
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
        # This final loopback remains the same and is correct.
        {
          name = "libpipewire-module-loopback";
          args = {
            "node.description" = "EQ Output ➜ Hardware DAC";
            "capture.props"."node.target" = "HeadphoneSignal";
            "playback.props"."node.target" = hwSink;
          };
        }

        # --- Expose Stream Mix as Virtual Mic ---
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
