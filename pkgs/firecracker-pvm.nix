{
  lib,
  stdenv,
  cmake,
  gcc,
  libseccomp,
  rust-bindgen,
  rustPlatform,
  versionCheckHook,
  src,
}:
let
  firecrackerCargo = lib.importTOML "${src}/src/firecracker/Cargo.toml";
in
rustPlatform.buildRustPackage {
  pname = "firecracker-pvm";
  version = firecrackerCargo.package.version;

  inherit src;

  cargoHash = "sha256-s65GQb5gfvdQfxpcuRsyEfmIXslUD52ZJs2Og9cnlSA=";

  env.AWS_LC_SYS_EXTERNAL_BINDGEN = "true";

  postPatch = ''
    substituteInPlace $cargoDepsCopy/*/aws-lc-sys-*/aws-lc/crypto/asn1/a_bitstr.c \
      --replace-warn '(len > INT_MAX - 1)' '(len < 0 || len > INT_MAX - 1)'

    substituteInPlace src/cpu-template-helper/build.rs \
      --replace-warn '"gcc"' "\"$CC\""

    substituteInPlace src/seccompiler/build.rs \
      --replace-warn "/usr/local/lib" "${lib.getLib libseccomp}/lib"
  '';

  nativeBuildInputs = [
    cmake
    gcc
    rust-bindgen
    rustPlatform.bindgenHook
  ];

  cargoBuildFlags = [ "--workspace" ];
  cargoTestFlags = [
    "--package"
    "firecracker"
    "--package"
    "jailer"
  ];

  checkFlags = [
    "--skip=fingerprint::dump::tests::test_read_valid_sysfs_file"
    "--skip=template::dump::tests::test_dump"
    "--skip=tests::test_filter_apply"
    "--skip=tests::test_fingerprint_dump_command"
    "--skip=tests::test_template_dump_command"
    "--skip=tests::test_template_verify_command"
    "--skip=utils::tests::test_build_microvm"
    "--skip=env::tests::test_copy_cache_info"
    "--skip=env::tests::test_dup2"
    "--skip=env::tests::test_mknod_and_own_dev"
    "--skip=env::tests::test_setup_jailed_folder"
    "--skip=env::tests::test_userfaultfd_dev"
    "--skip=env::tests::test_copy_exec_to_chroot"
    "--skip=resource_limits::tests::test_set_resource_limits"
  ];

  doCheck = false;
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    releaseDir="build/cargo_target/${stdenv.hostPlatform.rust.rustcTarget}/release"
    for bin in $(find "$releaseDir" -maxdepth 1 -type f -executable); do
      install -Dm555 -t $out/bin "$bin"
    done

    runHook postInstall
  '';

  meta = {
    description = "PVM-capable Firecracker build for AWS hosted lanes";
    homepage = "https://github.com/loopholelabs/firecracker";
    mainProgram = "firecracker";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
