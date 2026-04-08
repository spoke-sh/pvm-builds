{
  linux-pvm-src,
  linuxPackages_custom,
  stdenv,
  writeText,
  ...
}:
let
  version = "6.12.33";
  modDirVersion = version;
  baseConfig = builtins.readFile ../configs/linux-port-pvm-x86_64.config;
  configfile = writeText "linux-port-pvm-guest-x86_64.config" ''
    ${baseConfig}

    CONFIG_X86_PIE=y
    CONFIG_PVM_GUEST=y
    # CONFIG_KVM is not set
    # CONFIG_KVM_SW_PROTECTED_VM is not set
    # CONFIG_KVM_PVM is not set
  '';

  kernel =
    (linuxPackages_custom {
      inherit version modDirVersion;
      src = linux-pvm-src;
      inherit configfile;
    }).kernel;
in
kernel.overrideAttrs (previous: {
  enableParallelBuilding = false;
  postInstall = (previous.postInstall or "") + ''
    if [ -f vmlinux ]; then
      cp vmlinux "$out/vmlinux"
    elif [ -f "$buildRoot/vmlinux" ]; then
      cp "$buildRoot/vmlinux" "$out/vmlinux"
    else
      echo "missing guest vmlinux in build output" >&2
      exit 1
    fi
  '';
})
