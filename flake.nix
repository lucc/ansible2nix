{
  description = "Converts ansible requirements.yml into nix expression";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-compat = {
      url = "github:teto/flake-compat/support-packages";
      flake = false;
    };
    poetry2nix.url = "github:nix-community/poetry2nix";
    poetry2nix.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.inputs.flake-utils.follows = "flake-utils";
    poetry2nix.inputs.systems.follows = "systems";
    systems.url = "github:nix-systems/x86_64-linux";
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix, systems, ... }:
    flake-utils.lib.eachSystem (import systems) (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlays.default ];
      };

    in {
      packages = rec {
        default = ansible2nix;
        ansible2nix = pkgs.ansible2nix;
        test = pkgs.callPackage ./tests/test.nix {};
      };

      devShells.default = self.packages.${system}.default.overrideAttrs(oa: {
        postShellHook = ''
          export PYTHONPATH="$PWD:$PYTHONPATH"
        '';
      });
    }) // {

      overlays.default = final: prev:
        let
          inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = final; }) mkPoetryApplication;
        in {
          ansible2nix = mkPoetryApplication {
            projectDir = ./.;
            buildInputs = [ ];
          };

      ansibleGenerateCollection = final.callPackage ./ansible.nix {};
    };
  };
}
