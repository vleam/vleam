{
  description = "A Nix-flake-based Gleam development environment";

  inputs.nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1.*.tar.gz";

  outputs = { self, nixpkgs }:
    let
      overlays = [
        (final: prev: {
          nodejs = prev.nodejs_latest;
        })
      ];
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit overlays system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [
            vscodium
            gleam
            node2nix
            nodejs
            pnpm

            typescript
            nodePackages.typescript-language-server
            vue-language-server
          ];
        };
      });
    };
}
