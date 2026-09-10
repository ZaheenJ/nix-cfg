_final: prev:
let
  patchDriver =
    driver:
    driver.overrideAttrs (oldAttrs: {
      passthru = oldAttrs.passthru // {
        open = driver.open.overrideAttrs (openAttrs: {
          patches = (openAttrs.patches or [ ]) ++ [ ./nvidia-nvpcf-1299.patch ];
        });
      };
    });
in
{
  linuxPackages_latest = prev.linuxPackages_latest.extend (
    _kernelFinal: kernelPrev: {
      nvidiaPackages = kernelPrev.nvidiaPackages // {
        stable = patchDriver kernelPrev.nvidiaPackages.stable;
      };
    }
  );
}
