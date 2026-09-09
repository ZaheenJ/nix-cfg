# Ghostty terminal emulator. Launches Nushell as the shell.
# Repeated Ghostty keys such as palette and keybind are represented as lists by
# Home Manager and rendered as duplicate config entries.
{ ... }:
{
  programs.ghostty = {
    enable = true;
    settings = {
      command = "direct:nu";
      scrollback-limit = 3023;
      mouse-hide-while-typing = true;
      copy-on-select = false;
      confirm-close-surface = false;
      app-notifications = "no-clipboard-copy,no-config-reload";
      keybind = [
        "ctrl+shift+n=new_window"
        "ctrl+t=new_tab"
        "ctrl+plus=increase_font_size:1"
        "ctrl+minus=decrease_font_size:1"
        "ctrl+zero=reset_font_size"
        "shift+enter=text:\\n"
      ];
      shell-integration = "detect";
      shell-integration-features = "cursor,sudo,title,no-cursor";
      gtk-single-instance = true;
    };
  };
}
