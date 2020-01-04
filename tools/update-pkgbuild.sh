#!/bin/bash

set -e

PKGBUILD_FILE=${1:?"Usage: $0 <PKGBUILD FILE>"}

rm -f ektoplayer-*.gem
source "$PKGBUILD_FILE"
wget "$source"
SHA1SUM=$(sha1sum ektoplayer-*.gem | cut -d ' ' -f1)
sed -i "s/sha1sums=(.*)/sha1sums=('$SHA1SUM')/" "$PKGBUILD_FILE"
rm -f ektoplayer-*.gem

echo "Version of PKGBUILD is $pkgname-$pkgver"
