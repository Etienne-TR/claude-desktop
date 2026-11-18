#!/usr/bin/env bash
# Met sources.json à la dernière version de Claude Desktop publiée par
# Anthropic, en ne croyant que ce qu'Anthropic a signé :
#
#   anthropic-archive-keyring.asc (empreinte vérifiée ci-dessous)
#     -> dists/stable/InRelease   (signature PGP vérifiée)
#       -> Packages               (SHA256 listé dans InRelease, vérifié)
#         -> .deb                 (SHA256 listé dans Packages, écrit dans
#                                  sources.json ; Nix le vérifie au
#                                  téléchargement)
#
# Adapté de github.com/danielbodart/claude-desktop (licence MIT).
# Usage : scripts/update.sh (dans `nix develop`, ou avec curl, gpg, jq, dpkg
# et nix dans le PATH). Code 0, sources.json écrit seulement s'il change.
set -euo pipefail

repo="https://downloads.claude.ai/claude-desktop/apt/stable"
# Anthropic Claude Code Release Signing <security@anthropic.com>
fingerprint="31DDDE24DDFAB679F42D7BD2BAA929FF1A7ECACE"

root="$(cd "$(dirname "$0")/.." && pwd)"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export GNUPGHOME="$work/gnupg"
mkdir -m 700 "$GNUPGHOME"

die() { echo "erreur : $*" >&2; exit 1; }

# 1. La clé du dépôt est bien celle d'Anthropic.
fpr=$(gpg --show-keys --with-colons "$root/anthropic-archive-keyring.asc" | awk -F: '$1 == "fpr" { print $10; exit }')
[ "$fpr" = "$fingerprint" ] || die "clé inattendue : $fpr"
gpg --dearmor <"$root/anthropic-archive-keyring.asc" >"$work/keyring.gpg"

# 2. Index signé par cette clé.
curl -fsSL --retry 3 "$repo/dists/stable/InRelease" >"$work/InRelease"
gpgv --keyring "$work/keyring.gpg" "$work/InRelease" 2>/dev/null ||
  die "signature de InRelease invalide"

# 3. Liste des paquets, dont l'empreinte est dans l'index signé.
expected=$(awk '/^SHA256:/ { s = 1; next } /^[^ ]/ { s = 0 }
  s && $3 == "main/binary-amd64/Packages" { print $1; exit }' "$work/InRelease")
[ -n "$expected" ] || die "Packages absent de InRelease"
curl -fsSL --retry 3 "$repo/dists/stable/main/binary-amd64/Packages" >"$work/Packages"
[ "$(sha256sum "$work/Packages" | cut -d' ' -f1)" = "$expected" ] ||
  die "empreinte de Packages différente de celle signée"

# 4. Dernière version de claude-desktop (ordre des versions Debian).
version=""
while read -r v; do
  if [ -z "$version" ] || dpkg --compare-versions "$v" gt "$version"; then version="$v"; fi
done < <(awk '/^Package: claude-desktop$/ { p = 1 } p && /^Version: / { print $2; p = 0 }' "$work/Packages")
[ -n "$version" ] || die "claude-desktop absent de Packages"
field() { # champ de la fiche de cette version
  awk -v v="$version" -v f="$1: " 'BEGIN { RS = "" }
    /(^|\n)Package: claude-desktop\n/ && $0 ~ ("\nVersion: " v "\n") {
      n = split($0, l, "\n"); for (i = 1; i <= n; i++) if (index(l[i], f) == 1) { print substr(l[i], length(f) + 1); exit } }' "$work/Packages"
}
file=$(field Filename)
sha=$(field SHA256)
[ -n "$file" ] && [ -n "$sha" ] || die "fiche incomplète pour $version"

current=$(jq -r .version "$root/sources.json")
if [ "$current" = "$version" ]; then
  echo "Déjà à jour : $version"
  exit 0
fi
jq -n --arg v "$version" --arg u "$repo/$file" --arg h "$(nix hash convert --hash-algo sha256 --to sri "$sha")" \
  '{version: $v, url: $u, hash: $h}' >"$root/sources.json"
echo "Claude Desktop : $current -> $version"
