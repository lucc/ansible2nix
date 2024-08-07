{
  description = "Converts ansible requirements.yml into nix expression";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-compat = {
      url = "github:teto/flake-compat/support-packages";
      flake = false;
    };
    poetry2nix.url = "github:nix-community/poetry2nix";
  };

  outputs = { self, nixpkgs, flake-utils, poetry2nix, ... }:
    flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ self.overlay ];
      };

    in {
      packages = {
        ansible2nix = pkgs.ansible2nix;
        test = pkgs.callPackage ./tests/test.nix {};
      };

      defaultPackage = self.packages.${system}.ansible2nix;

      devShell = self.defaultPackage.${system}.overrideAttrs(oa: {
        postShellHook = ''
          export PYTHONPATH="$PWD:$PYTHONPATH"
        '';
      });
    }) // {

      overlay = final: prev:
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
