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
kernel.overrideAttrs (previous: {
  enableParallelBuilding = false;
  configurePhase = ''
    runHook preConfigure

    rm -rf /tmp/linux-port-pvm-build
    mkdir -p /tmp/linux-port-pvm-build
    export buildRoot="/tmp/linux-port-pvm-build"

    echo "manual-config configurePhase buildRoot=$buildRoot pwd=$PWD"

    if [ -f "$buildRoot/.config" ]; then
      echo "Could not link $buildRoot/.config : file exists"
      exit 1
    fi
    ln -sv ${configfile} $buildRoot/.config

    make "''${makeFlags[@]}" oldconfig
    runHook postConfigure

    make "''${makeFlags[@]}" prepare
    actualModDirVersion="$(cat $buildRoot/include/config/kernel.release)"
    if [ "$actualModDirVersion" != "${modDirVersion}" ]; then
      echo "Error: modDirVersion ${modDirVersion} specified in the Nix expression is wrong, it should be: $actualModDirVersion"
      exit 1
    fi

    buildFlags+=("KBUILD_BUILD_TIMESTAMP=$(date -u -d @$SOURCE_DATE_EPOCH)")

    cd $buildRoot
  '';
})
