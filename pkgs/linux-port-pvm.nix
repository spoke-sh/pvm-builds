{
  lib,
  linux-pvm-src,
  linux_6_12,
  ...
}:
(
  linux_6_12.override {
    argsOverride = {
      src = linux-pvm-src;
      version = "6.12.33";
      modDirVersion = "6.12.33";
      ignoreConfigErrors = true;
      structuredExtraConfig = with lib.kernel; {
        RUST = lib.mkForce no;
        KVM_SW_PROTECTED_VM = yes;
        KVM_PVM = module;
      };
    };
  }
).overrideAttrs (_previous: {
  enableParallelBuilding = false;
})
