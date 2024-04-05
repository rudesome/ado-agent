{
  description = "Nix Azure DevOps Agent";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    let
      agent = import ./agents/agents.nix { };
    in
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
        "aarch64-darwin"
      ];

      #flake = {
      #pkgs = import ((builtins.getEnv "HOME") + "/github/nixpkgs") { };
      #};

      perSystem = { pkgs, system, self', inputs', ... }: {

        devShells.default =
          with pkgs;
          mkShell
            {
              buildInputs = with pkgs; [
                dotnet-sdk
                git
                gnumake
                nuget-to-nix
                which
              ];
            };

        packages = {
          agent = agent.agent {
            inherit pkgs;
              #lib
              #buildDotnetModule
              #dotnetCorePackages
              #stdenv
              #fetchFromGitHub
              #which
              #git
              #nodejs_20
              #autoPatchelfHook
              #glibcLocales
              #buildPackages
              #runtimeShell;
          };
        };
      };
    };
}
