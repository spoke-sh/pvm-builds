{
  linux-pvm-src,
  linuxPackages_custom,
  stdenv,
  ...
}:
let
  version = "6.12.33";
  modDirVersion = version;
  configfile = ../configs/linux-port-pvm-x86_64.config;

  kernel =
    (linuxPackages_custom {
      inherit version modDirVersion;
      src = linux-pvm-src;
      inherit configfile;
    }).kernel;
in
kernel.overrideAttrs (_previous: {
  enableParallelBuilding = false;
})
