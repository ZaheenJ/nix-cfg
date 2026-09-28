{ config, ... }:
{
  system.keyboard = {
    enableKeyMapping = true;
    remapCapsLockToEscape = true;
  };

  launchd.user.agents.caps-lock-to-escape.serviceConfig = {
    ProgramArguments = [
      "/usr/bin/hidutil"
      "property"
      "--set"
      (builtins.toJSON { UserKeyMapping = config.system.keyboard.userKeyMapping; })
    ];
    RunAtLoad = true;
  };
}
