# Claude Desktop pour Linux, repackagé depuis le .deb officiel d'Anthropic.
# Version, adresse et empreinte : sources.json, écrit par scripts/update.sh
# depuis l'index apt signé par Anthropic.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  xdg-utils,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  expat,
  fontconfig,
  freetype,
  gdk-pixbuf,
  glib,
  gtk3,
  libayatana-appindicator,
  libcap_ng,
  libdrm,
  libglvnd,
  libnotify,
  libsecret,
  libseccomp,
  libuuid,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxkbcommon,
  libxrandr,
  libxscrnsaver,
  libxshmfence,
  libxtst,
  mesa,
  nspr,
  nss,
  pango,
  pipewire,
  systemd,
}:
let
  sources = lib.importJSON ./sources.json;
in
stdenv.mkDerivation {
  pname = "claude-desktop";
  inherit (sources) version;

  src = fetchurl { inherit (sources) url hash; };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  # Bibliothèques chargées par Electron (vérifiées par autoPatchelfHook).
  buildInputs = [
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
    libcap_ng
    libdrm
    libglvnd
    libnotify
    libsecret
    libseccomp
    libuuid
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxkbcommon
    libxrandr
    libxscrnsaver
    libxshmfence
    libxtst
    mesa
    nspr
    nss
    pango
    pipewire
    systemd
  ];

  unpackPhase = ''
    dpkg-deb --fsys-tarfile $src | tar -x --no-same-permissions
  '';

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib $out/bin $out/share
    cp -r usr/lib/claude-desktop $out/lib/claude-desktop
    # Sans setuid dans le store : Electron passe par le sandbox des
    # namespaces utilisateur.
    chmod u-s $out/lib/claude-desktop/chrome-sandbox
    cp -r usr/share/applications usr/share/icons $out/share/
    runHook postInstall
  '';

  postFixup = ''
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      --prefix PATH : ${lib.makeBinPath [ xdg-utils ]} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libglvnd ]} \
      --add-flags "--ozone-platform-hint=auto"
  '';

  meta = {
    description = "Claude Desktop (application officielle d'Anthropic, .deb repackagé)";
    homepage = "https://claude.ai/download";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude-desktop";
  };
}
