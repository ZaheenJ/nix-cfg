let
  laptop = "eDP-1";
  monitor = "Samsung Electric Company C32R50x H4CX605453Y";
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
              criteria = monitor;
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
    ];
  };
}
