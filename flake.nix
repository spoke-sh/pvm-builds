{
  description = "Concrete AWS PVM kernel and Firecracker builds for Spoke";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    linux-pvm-src = {
      url = "github:virt-pvm/linux/pvm-612";
      flake = false;
    };
    firecracker-pvm-src = {
      url = "github:loopholelabs/firecracker/main-live-migration-pvm";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      linux-pvm-src,
      firecracker-pvm-src,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        linux-port-pvm = pkgs.callPackage ./pkgs/linux-port-pvm.nix {
          inherit linux-pvm-src;
        };
        linux-port-pvm-guest = pkgs.callPackage ./pkgs/linux-port-pvm-guest.nix {
          inherit linux-pvm-src;
        };
        firecracker-pvm = pkgs.callPackage ./pkgs/firecracker-pvm.nix {
          src = firecracker-pvm-src;
        };
      in
      {
        packages = {
          inherit linux-port-pvm linux-port-pvm-guest firecracker-pvm;
          default = firecracker-pvm;
        };

        formatter = pkgs.nixfmt-rfc-style;
      }
    );
}
