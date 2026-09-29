let
  laptop = "eDP-1";
  samsung = "Samsung Electric Company C32R50x H4CX605453Y";
  dell = "Dell Inc. DELL D2721H 7C0JQ23";
in
{
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile = {
          name = "mobile";
          outputs = [
            {
              criteria = laptop;
              status = "enable";
              position = "0,0";
              scale = 1.5;
            }
          ];
        };
      }
      {
        profile = {
          name = "monitor-left";
          outputs = [
            {
              criteria = samsung;
              status = "enable";
              position = "0,0";
              scale = 1.0;
            }
            {
              criteria = laptop;
              status = "enable";
              position = "1920,0";
              scale = 1.5;
            }
          ];
        };
      }
      {
        profile = {
          name = "monitor-right";
          outputs = [
            {
              criteria = laptop;
              status = "enable";
              position = "0,0";
              scale = 1.5;
            }
            {
              criteria = dell;
              status = "enable";
              # Niri rounds the laptop's scaled width up to 1707 for overlap checks.
              position = "1707,0";
              scale = 1.0;
            }
          ];
        };
      }
    ];
  };
}
