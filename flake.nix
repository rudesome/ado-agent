{
  description = "Nix Azure DevOps Agent";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    container-image.url = "github:rudesome/minimal-nix-container";
  };
  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    let
      agent = import ./agents/agents.nix { };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
      ];

      perSystem = { pkgs, system, ... }: {
        devShells.default =
          with pkgs;
          mkShell
            {
              buildInputs = with pkgs; [
                gnumake
              ];
            };

        packages = {
          agent = agent.agent {
            inherit (pkgs) lib buildDotnetModule fetchFromGitHub which git;
          };
        };
      };
    };
}