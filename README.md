# claude-desktop

Claude Desktop (application officielle d'Anthropic pour Linux) pour NixOS,
repackagé depuis le `.deb` du dépôt apt d'Anthropic.

- `package.nix` : le paquet (dépaquetage du `.deb`, bibliothèques, lanceur).
- `sources.json` : version, adresse et empreinte du `.deb`.
- `scripts/update.sh` : met `sources.json` à la dernière version publiée, en
  vérifiant la signature PGP d'Anthropic sur l'index apt.
- `.github/workflows/update.yml` : lance ce script toutes les heures et
  committe une nouvelle version après l'avoir construite.

Utilisation :

```nix
inputs.claude-desktop = {
  url = "github:Etienne-TR/claude-desktop";
  inputs.nixpkgs.follows = "nixpkgs";
};
# Home Manager
home.packages = [ inputs.claude-desktop.packages.x86_64-linux.default ];
```

La vérification de la signature est adaptée de
[danielbodart/claude-desktop](https://github.com/danielbodart/claude-desktop)
(licence MIT).
