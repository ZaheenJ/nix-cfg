{
  # Mesh VPN (WireGuard) for reaching the server over SSH from anywhere.
  # Auth is interactive via GitHub on first run — see `tailscale up` below.
  services.tailscale = {
    enable = true;
    # openFirewall punches UDP 41641 for direct (non-relayed) connections.
    openFirewall = true;
  };
}
