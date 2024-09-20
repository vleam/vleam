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
        lib = nixpkgs.lib;
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs, lib }:
        let
          gleam_150 = pkgs.rustPlatform.buildRustPackage rec {
            pname = "gleam";
            version = "1.5.0";
            src = pkgs.fetchFromGitHub {
              owner = "gleam-lang";
              repo = pname;
              rev = "refs/tags/v${version}";
              hash = "sha256-buMnbBg+/vHXzbBuMPuV8AfdUmYA9J6WTXP7Oqrdo34=";
            };
            nativeBuildInputs = [ pkgs.git pkgs.pkg-config ];
            buildInputs = [ pkgs.openssl ];
            cargoHash = "sha256-0Vtf9UXLPW5HuqNIAGNyqIXCMTITdG7PuFdw4H4v6a4=";
            passthru.updateScript = pkgs.nix-update-script { };
          };
        in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            vscodium
            gleam_150
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
