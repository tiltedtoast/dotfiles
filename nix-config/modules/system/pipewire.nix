{
  pkgs,
  lib,
  ...
}:

let
  hwSink = "alsa_output.pci-0000_02_02.0.analog-stereo";

  allSlaves = [
    "Music"
    "Browser"
    "Discord"
    "System"
    "MicFilteredOut.monitor"
  ];
  mkLoopbackModule = slave: {
    name = "module-loopback";
    args = {
      source = slave;
      sink = "PhysicalEQ";
      latency_msec = 8;
    };
  };
  mkSink = name: {
    factory = "adapter";
    args = {
      "factory.name" = "support.null-audio-sink";
      "node.name" = name;
      "node.description" = "${name} Sink";
      "media.class" = "Audio/Sink";
      "audio.position" = "FL,FR";
    };
  };
  limiterNode = thresh: {
    type = "ladspa";
    plugin = "${pkgs.ladspaPlugins}/lib/ladspa/fast_lookahead_limiter_1913.so";
    label = "fastLookaheadLimiter";
    control = {
      "Input gain (dB)" = 0.0;
      "Limit (dB)" = thresh;
      "Release time (s)" = 0.1;
    };
  };

  mkLimiterChain = name: thresh: {
    name = "libpipewire-module-filter-chain";
    args = {
      "filter.graph" = {
        nodes = [ (limiterNode thresh) ];
      };

      # The “capture” side is the input of the virtual sink:
      "capture.props" = {
        "node.name" = "${name}LimiterIn";
        "media.class" = "Audio/Sink";
      };

      # The “playback” side is what apps will see as the sink:
      "playback.props" = {
        "node.name" = "${name}";
        "node.description" = "${name} (Limited)";
        "media.class" = "Audio/Sink";
      };
    };
  };
in
{

  environment.systemPackages = with pkgs; [
    rnnoise-plugin
    ladspaPlugins
  ];

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
  };

  services.pipewire.extraConfig."pipewire-pulse" = {
    "30-link-sinks-to-physical.conf" = {
      pulse.modules = lib.mkForce (map mkLoopbackModule allSlaves);
    };
  };

  services.pipewire.extraConfig."pipewire-pulse" = {
    "31-link-physicaleq-to-hw.conf" = {
      pulse.modules = lib.mkForce [
        {
          name = "module-loopback";
          args = {
            source = "PhysicalEQ.monitor";
            sink = hwSink;
            latency_msec = 8;
          };
        }
      ];
    };
  };

  services.pipewire.extraConfig.pipewire."50-virtual-sinks.conf" = {
    "context.objects" = [
      (mkSink "Music")
      (mkSink "Browser")
      (mkSink "Discord")
      (mkSink "System")
      (mkSink "StreamMix")
    ];
  };

  services.pipewire.extraConfig.pipewire."60-sink-limiters.conf" = {
    context.modules = [
      (mkLimiterChain "Music" (-12.0))
      (mkLimiterChain "Browser" (-14.0))
      (mkLimiterChain "Discord" (-14.0))
      (mkLimiterChain "System" (-14.0))
    ];
  };

  services.pipewire.extraConfig."pipewire-pulse"."20-mic-to-streammix.conf" = {
    pulse.modules = [
      {
        name = "module-loopback";
        args = {
          source = "MicFilteredOut.monitor";
          sink = "StreamMix";
          latency_msec = 8;
        };
      }
    ];
  };

  services.pipewire.extraConfig.pipewire."95-dac-eq.conf" = {
    context.modules = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "filter.graph" = {
            nodes = [
              {
                type = "ladspa";
                plugin = "${pkgs.ladspaPlugins}/lib/ladspa/amp_1181.so";
                label = "amp";
                control = {
                  "Amplification (dB)" = -6.0;
                };
              }
              {
                type = "ladspa";
                plugin = "${pkgs.ladspaPlugins}/lib/ladspa/mbeq_1197.so";
                label = "multi_voice_multi_band_eq";
                control = {
                  "Gain @ 42Hz (dB)" = 7.3;
                  "Gain @ 143Hz (dB)" = -5;
                  "Gain @ 1524Hz (dB)" = -3.8;
                  "Gain @ 3845Hz (dB)" = -9.9;
                  "Gain @ 6520Hz (dB)" = 7.8;
                  "Gain @ 2492Hz (dB)" = 2;
                  "Gain @ 3108Hz (dB)" = -2.5;
                  "Gain @ 4006Hz (dB)" = 2.1;
                  "Gain @ 4816Hz (dB)" = -1.3;
                  "Gain @ 6050Hz (dB)" = 1.2;
                };
              }
            ];
          };

          capture.props = {
            "node.name" = "PhysicalEQIn";
            "media.class" = "Audio/Sink";
          };
          playback.props = {
            "node.name" = "PhysicalEQ";
            "node.description" = "Physical (Pre-amp + EQ)";
            "media.class" = "Audio/Sink";
          };
        };
      }
    ];
  };

  services.pipewire.wireplumber.extraConfig."01-app-routing.lua".content = ''
    local rules = {

      -- Spotify → Music
      {
        matches = { { ["application.process.binary"] = "spotify" } };
        apply_properties = { ["node.target"] = "Music"; };
      },

      -- Librewolf/Firefox → Browser
      {
        matches = { { ["application.process.binary"] = "Librewolf" } };
        apply_properties = { ["node.target"] = "Browser"; };
      },

      -- Discord → Discord
      {
        matches = { { ["application.name"] = "discord" } };
        apply_properties = { ["node.target"] = "Discord"; };
      },

      -- Everything else → System
      {
        matches = { };
        apply_properties = { ["node.target"] = "System"; };
      }
    }

    table.insert(alsa_monitor.rules, unpack(rules))
  '';

  services.pipewire.extraConfig.pipewire."90-mic-filter-chain.conf" = {
    context.modules = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "filter.graph" = {
            nodes = [
              # RNNoise
              {
                type = "ladspa";
                plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                label = "noise_suppressor_mono";
                control = {
                  "VAD Threshold (%)" = 50.0;
                };
              }
              # Compressor
              {
                type = "ladspa";
                plugin = "${pkgs.ladspaPlugins}/lib/ladspa/dyson_compress_1403.so";
                label = "dyson_compress";
                control = {
                  "Attack (ms)" = 10.0;
                  "Release (ms)" = 500.0;
                  "Threshold (dB)" = -18.3;
                  "Ratio" = 4.0;
                  "Makeup (dB)" = 5.9;
                };
              }
            ];
          };

          "capture.props" = {
            "node.name" = "MicFilteredIn";
          };

          "playback.props" = {
            "node.name" = "MicFilteredOut";
            "node.description" = "Microphone (Filtered)";
            "media.class" = "Audio/Source";
          };
        };
      }
    ];
  };
}
