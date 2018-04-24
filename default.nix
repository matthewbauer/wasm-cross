{ debugLlvm ? false }:

(import ./nixpkgs {}).lib.makeExtensible (project: {
  nixpkgsArgs = {
    overlays = [(self: super: {
      fib-example = self.callPackage ./fib-example {};

      hello-example = self.callPackage ./hello-example {};

      llvmPackages_HEAD = self.callPackage ./llvm-head {
        buildTools = self.buildPackages.llvmPackages_HEAD;
        debugVersion = debugLlvm;
      };

      llvmPackages = self.llvmPackages_HEAD;

      wabt = self.callPackage ./wabt.nix {};
      binaryen = self.callPackage ./binaryen.nix {};

      webabi = (self.callPackage ./webabi-nix {}).package.overrideAttrs (_: {
        src = self.fetchFromGitHub {
          owner = "WebGHC";
          repo = "webabi";
          rev = "7e70d2ea79f3d90ab9ba5638cb46d97a4e159150";
          sha256 = "0g6a4sg02r1skndjxa6n2af2mw375p3ca2p785hipkjl8z57vdjn";
        };
      });

      build-wasm-app = www: drv: self.buildEnv {
        name = "wasm-app-${drv.name}";
        paths = [
          www
          "${self.buildPackages.buildPackages.webabi}/lib/node_modules/webabi"
          "${drv}/bin"
        ];

        passthru = { inherit drv; };
      };
    })];
  };
  nixpkgsCrossArgs = project.nixpkgsArgs // {
    stdenvStages = import ./cross.nix;
  };

  nixpkgs = import ./nixpkgs project.nixpkgsArgs;
  nixpkgsWasm = import ./nixpkgs (project.nixpkgsCrossArgs // {
    crossSystem = {
      config = "wasm32-unknown-unknown-wasm";
      arch = "wasm32";
      libc = null;
      disableDynamicLinker = true;
      thread-model = "single";
      # entry = "main";
      # target-cpu = "bleeding-edge";
    };
  });
  nixpkgsArm = import ./nixpkgs (project.nixpkgsCrossArgs // {
    crossSystem = (import "${(import ./nixpkgs {}).path}/lib/systems/examples.nix" { inherit (project.nixpkgs) lib; }).aarch64-multiplatform;
  });
  # nixpkgsRpi = import ./nixpkgs (project.nixpkgsCrossArgs // {
  #   crossSystem = (import "${(import ./nixpkgs {}).path}/lib/systems/examples.nix" { inherit (project.nixpkgs) lib; }).raspberryPi // { disableDynamicLinker = true; };
  # });
})
