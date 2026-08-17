# Package overrides and custom packages, applied as a nixpkgs overlay.
# (Currently empty — gaze moved to its upstream flake input.)
final: prev: {
  ananicy-cpp = prev.ananicy-cpp.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        sed -i '1i #include <cstdint>\n#include <cstring>' src/platform/linux/backtrace.cpp
        sed -i '1i #include <cstring>' src/utility/argument_parsing/argument.cpp
        sed -i '1i #include <cstring>' src/platform/linux/singleton_process.cpp
      '';
   });
}
