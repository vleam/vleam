{
  description = "A Nix-flake-based Gleam development environment";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
        lib = nixpkgs.lib;
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs, lib }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            vscodium
            gleam
            node2nix
            nodejs_24
            pnpm

            typescript
            nodePackages.typescript-language-server
            vue-language-server
            prettier
          ];
        };
      });
    };
}
