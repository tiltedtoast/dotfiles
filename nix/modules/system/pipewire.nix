{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  cfg = config.audio;
  pow = inputs.nix-math.lib.math.pow;

  # Helper function to convert a dB value to a linear gain value
  # Formula: G = 10^(dB / 20)
  dbToGain = db: pow 10 (db / 20);

  mkEqBands =
    settings:
    let
      bandAttrs = imap0 (index: band: {
        "Frequency ${toString index} (Hz)" = band.freq;
        "Gain ${toString index} (G)" = dbToGain band.gain;
        "Quality factor ${toString index}" = band.quality;
      }) settings;
    in
    mergeAttrsList bandAttrs;

in
{
  options.audio = {
    enable = mkEnableOption "the custom PipeWire audio configuration";

    input = mkOption {
      type = types.str;
      description = "The name of the hardware source (microphone) device.";
      example = "alsa_input.pci-0000_01_00.1.analog-stereo";
    };

    output = mkOption {
      type = types.str;
      description = "The name of the hardware sink (output) device.";
      example = "alsa_output.pci-0000_00_1f.3.analog-stereo";
    };

    micProcess = {
      enable = mkEnableOption "RNNoise-based microphone noise suppression";

      vadThreshold = mkOption {
        type = types.float;
        default = 50.0;
        description = "Voice Activity Detection (VAD) threshold percentage for RNNoise.";
        example = 75.0;
      };
    };

    eq = {
      enable = mkEnableOption "a parametric equalizer on the main output";

      preamp = mkOption {
        type = types.float;
        default = 0.0;
        description = "Preamp gain in decibels (dB). Use a negative value to prevent clipping.";
        example = -6.0;
      };

      settings = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              freq = mkOption {
                type = types.int;
                description = "Center frequency of the EQ band in Hz.";
              };
              gain = mkOption {
                type = types.float;
                description = "Gain of the EQ band in decibels (dB).";
              };
              quality = mkOption {
                type = types.float;
                default = 1.0;
                description = "Quality factor (Q) of the EQ band.";
              };
            };
          }
        );
        default = [ ];
        example = ''[ { freq = 42.0; gain = 7.3; } ]'';
        description = "A list of bands to configure for the parametric equalizer.";
      };
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages =
      with pkgs;
      [
        helvum
        qpwgraph
        ladspaPlugins
      ]
      ++ (optional cfg.micProcess.enable rnnoise-plugin)
      ++ (optional cfg.eq.enable lsp-plugins);

    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    services.pipewire.wireplumber.extraConfig."99-alsa-rules" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = cfg.output; } ];
          actions.update-props = {
            "api.alsa.period-num" = 32;
            "api.alsa.headroom" = 8192;
            "api.alsa.disable-tsched" = true;
          };
        }
        {
          matches = [ { "node.name" = cfg.input; } ];
          actions.update-props = {
            "api.alsa.period-num" = 32;
            "api.alsa.headroom" = 8192;
            "api.alsa.disable-tsched" = true;
          };
        }
      ];
    };

    # PulseAudio routing rules
    services.pipewire.extraConfig.pipewire-pulse."99-app-routing" = {
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

    services.pipewire.extraConfig.pipewire."10-processing-and-linking" =
      let
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
            "playback.props"."node.target" = if cfg.eq.enable then "MainEQ" else cfg.output;
          };
        };

      in
      {
        "context.modules" = [
          # --- Application Limiters ---
          (mkAppChain { name = "Browser"; })
          (mkAppChain {
            name = "Music";
            thresh = -12;
          })
          (mkAppChain { name = "Discord"; })
          (mkAppChain { name = "System"; })

          # --- Route Apps to the Main Mix ---
          (mkMainLoopback "Browser")
          (mkMainLoopback "Music")
          (mkMainLoopback "Discord")
          (mkMainLoopback "System")

          # --- Microphone Processing ---
          (
            # TODO: Add a compressor when you get the chance
            if cfg.micProcess.enable then
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
                        control."VAD Threshold (%)" = cfg.micProcess.vadThreshold;
                      }
                    ];
                  };
                };
              }
            else
              {
                # If mic processing is off, create a simple pass-through virtual device
                name = "libpipewire-module-adapter";
                args = {
                  "factory.name" = "support.null-audio-sink";
                  "node.name" = "MicRaw";
                  "media.class" = "Audio/Sink";
                };
              }
          )
          {
            name = "libpipewire-module-loopback";
            args = {
              "node.description" = "HW-Mic ➜ Mic Processing";
              "capture.props"."node.target" = cfg.input;
              "playback.props"."node.target" = if cfg.micProcess.enable then "MicRaw" else "MicFiltered";
            };
          }
          # This creates the final "MicFiltered" source, even if processing is disabled.
          (
            if !cfg.micProcess.enable then
              {
                name = "libpipewire-module-adapter";
                args = {
                  "factory.name" = "support.null-audio-sink";
                  "node.name" = "MicFiltered";
                  "media.class" = "Audio/Source";
                };
              }
            else
              { }
          )

          # --- Headphone EQ and Final Output  ---
          (
            if cfg.eq.enable then
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
                    "node.target" = cfg.output;
                  };
                  "filter.graph" = {
                    nodes = [
                      {
                        type = "ladspa";
                        plugin = "${pkgs.lsp-plugins}/lib/ladspa/lsp-plugins-ladspa.so";
                        label = "http://lsp-plug.in/plugins/ladspa/para_equalizer_x16_stereo";
                        control = {
                          "Input gain (G)" = dbToGain cfg.eq.preamp;
                        }
                        // (mkEqBands cfg.eq.settings);
                      }
                    ];
                  };
                };
              }
            else
              {
                # If EQ is disabled, create a simple sink that acts as the main mix and outputs directly to hardware.
                name = "libpipewire-module-loopback";
                args = {
                  "capture.props" = {
                    "node.name" = "MainEQ";
                    "node.description" = "Main Mix (Passthrough)";
                    "media.class" = "Audio/Sink";
                    "audio.position" = "FL,FR";
                  };
                  "playback.props" = {
                    "node.target" = cfg.output;
                  };
                };
              }
          )

          # --- Stream Mix and Virtual Mic ---
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
