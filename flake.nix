{
  description = "Converts ansible requirements.yml into nix expression";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    flake-utils.inputs.systems.follows = "systems";
    nixpkgs.url = "github:NixOS/nixpkgs";
    pyproject-nix.url = "github:pyproject-nix/pyproject.nix";
    pyproject-nix.inputs.nixpkgs.follows = "nixpkgs";
    systems.url = "github:nix-systems/x86_64-linux";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pyproject-nix,
    systems,
    ...
  }: let
    project = pyproject-nix.lib.project.loadPyproject {projectRoot = ./.;};
    mkAnsible2nix = python: let
      attrs = project.renderers.buildPythonPackage {inherit python;};
    in
      python.pkgs.buildPythonApplication attrs;
  in
    flake-utils.lib.eachSystem (import systems) (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [self.overlays.default];
      };
      ansible2nix = mkAnsible2nix pkgs.python3;
    in {
      packages = {
        inherit ansible2nix;
        default = ansible2nix;
      };

      devShells.default = ansible2nix.overrideAttrs (oa: {
        postShellHook = ''
          export PYTHONPATH="$PWD:$PYTHONPATH"
        '';
        nativeBuildInputs = oa.nativeBuildInputs ++ [pkgs.poetry];
      });
      checks.test = pkgs.callPackage ./tests/test.nix {};
    })
    // {
      overlays.default = final: prev: {
        ansible2nix = mkAnsible2nix final.python3;
        ansibleGenerateCollection = final.callPackage ./ansible.nix {};
      };
    };
}
