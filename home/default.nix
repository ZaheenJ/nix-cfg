# Full profile for the personal laptop (home-g16).
# Non-NixOS hosts (school/work) will import ./common plus their own extras.
{ ... }:
{
  imports = [
    ./common
    ./personal
  ];
}
