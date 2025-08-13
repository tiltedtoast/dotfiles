self: super:

let
  fetch = super.fetchFromGitHub;
in
{
  rtl8761bFirmwareWithBu = super.stdenvNoCC.mkDerivation {
    pname = "rtl8761b-firmware-with-bu";
    version = "1.0";
    src = fetch {
      owner = "Realtek-OpenSource";
      repo = "android_hardware_realtek";
      rev = "rtk1395";
      sha256 = "sha256-vd9sZP7PGY+cmnqVty3sZibg01w8+UNinv8X85B+dzc=";
    };

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/lib/firmware/rtl_bt

      # install original files
      install -m644 bt/rtkbt/Firmware/BT/rtl8761b_fw \
        $out/lib/firmware/rtl_bt/rtl8761b_fw.bin

      install -m644 bt/rtkbt/Firmware/BT/rtl8761b_config \
        $out/lib/firmware/rtl_bt/rtl8761b_config.bin

      cp $out/lib/firmware/rtl_bt/rtl8761b_fw.bin  \
        $out/lib/firmware/rtl_bt/rtl8761bu_fw.bin

      cp $out/lib/firmware/rtl_bt/rtl8761b_config.bin \
        $out/lib/firmware/rtl_bt/rtl8761bu_config.bin
    '';

    meta = with super.lib; {
      description = "Firmware for Realtek RTL8761b (also provides rtl8761bu_* names)";
      license = licenses.unfreeRedistributableFirmware;
      platforms = platforms.linux;
    };
  };
}
