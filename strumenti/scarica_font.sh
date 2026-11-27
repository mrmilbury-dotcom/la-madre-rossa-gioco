#!/usr/bin/env bash
# Scarica i font del gioco (licenza SIL OFL) dal registro npm di Fontsource.
# Lo usa la pubblicazione automatica; in locale basta lanciarlo una volta.
set -euo pipefail
DEST="$(cd "$(dirname "$0")/.." && pwd)/assets/font"
TMP="$(mktemp -d)"
cd "$TMP"
npm pack --silent @fontsource/cormorant-garamond@5.3.0 @fontsource/ibm-plex-mono@5.3.0 >/dev/null
mkdir c p
tar -xzf fontsource-cormorant-garamond-5.3.0.tgz -C c
tar -xzf fontsource-ibm-plex-mono-5.3.0.tgz -C p
mkdir -p "$DEST"
for v in 400-normal 500-normal 400-italic 600-normal; do
  cp "c/package/files/cormorant-garamond-latin-$v.woff2" "$DEST/"
  cp "c/package/files/cormorant-garamond-latin-ext-$v.woff2" "$DEST/"
done
for v in 400-normal 500-normal; do
  cp "p/package/files/ibm-plex-mono-latin-$v.woff2" "$DEST/"
  cp "p/package/files/ibm-plex-mono-latin-ext-$v.woff2" "$DEST/"
done
echo "Font copiati in $DEST"
