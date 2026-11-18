{
  description = "Claude Desktop pour Linux, repackagé depuis le dépôt apt signé d'Anthropic";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system}.default = pkgs.callPackage ./package.nix { };
      overlays.default = final: _: { claude-desktop = final.callPackage ./package.nix { }; };

      # Outils de scripts/update.sh.
      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [ curl gnupg jq dpkg ];
      };
    };
}
