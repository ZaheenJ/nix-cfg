# Syncthing: home-manager user service (mirrors the Arch user service).
# Devices + folders are declared here (ported from the Arch config); the TLS
# keys / local device ID are still machine state Syncthing generates on first
# run. Folder `id`s are preserved exactly — Syncthing matches folders across
# devices by id, so the tablet/phone reconnect without re-sharing.
#
# overrideDevices/overrideFolders default to true: this file is authoritative,
# so devices/folders added later via the web GUI get reverted on rebuild. Add
# them here instead.
{ config, ... }:
let
  mobileDevices = [
    "Galaxy Tab S9 FE"
    "Pixel 9a"
  ];
in
{
  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        "Galaxy Tab S9 FE".id = "POB7G6L-HWSD7IU-RIXGF7D-UVWQUYZ-BVWZE2D-ND22VGS-SHE5YWT-AK3MLAG";
        "Pixel 9a".id = "HOWKQOW-GNLMFXV-3HPVSNL-S76WNTC-SQ3YKJN-P7GAMML-4ZIPV22-3VHJSQP";
      };

      folders = {
        "Books" = {
          id = "jxukx-5b3g6";
          path = "${config.xdg.userDirs.documents}/books";
          devices = mobileDevices;
        };
        "College" = {
          id = "jyzny-mtyip";
          path = "${config.xdg.userDirs.documents}/college";
          devices = mobileDevices;
        };
        "Music" = {
          id = "y2jmg-haren";
          path = config.xdg.userDirs.music;
          devices = mobileDevices;
        };
        "Piano Sheets" = {
          id = "7veaf-dk6wr";
          path = "${config.xdg.userDirs.documents}/piano";
          devices = mobileDevices;
        };
      };
    };
  };
}
