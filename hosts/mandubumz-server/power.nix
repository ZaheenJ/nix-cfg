{
  launchd.daemons.caffeinate = {
    # Prevent system sleep on AC power while allowing the display to sleep.
    command = "/usr/bin/caffeinate -s";
    serviceConfig = {
      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
