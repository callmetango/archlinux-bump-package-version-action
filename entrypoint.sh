#!/bin/bash

set -eu

# Constants
HOME=/home/builder
BUILDDIR="$HOME"/work

INPUT_PGKREL="${INPUT_PGKREL:-1}"

mkdir -p "$BUILDDIR"
cd "$BUILDDIR"

cp -rTfv "$GITHUB_WORKSPACE"/ ./
test "x$INPUT_PATH" != 'x' && cd "$INPUT_PATH"

echo "Updating pkgver and pkgrel of PKGBUILD"
sed -i "s/^pkgver=.*$/pkgver=$INPUT_PKGVER/g" PKGBUILD
sed -i "s/^pkgrel=.*$/pkgrel=$INPUT_PGKREL/g" PKGBUILD
git --no-pager diff PKGBUILD

if [ "$INPUT_UPDPKGSUMS" = 'true' ] ; then
	echo "Updating checksums on PKGBUILD"
	updpkgsums
	git --no-pager diff PKGBUILD
fi

if [ "$INPUT_SRCINFO" = 'true' -o [ "$INPUT_SRCINFO" = 'auto' -a -e .SRCINFO ] ] ; then
	echo "Generating new .SRCINFO based on PKGBUILD"
	makepkg --printsrcinfo > .SRCINFO
	git --no-pager diff .SRCINFO
fi

if [ "$INPUT_NAMCAP" = 'true' ] ; then
	glgrp "Validating PKGBUILD with namcap"
	namcap $INPUT_NAMCAP_OPTS PKGBUILD
fi

source PKGBUILD
printf "pkgname=$pkgname\n" >> $GITHUB_OUTPUT
printf "pkgbase=$pkgbase\n" >> $GITHUB_OUTPUT
printf "pkgver=$pkgver\n" >> $GITHUB_OUTPUT
printf "pkgrel=$pkgrel\n" >> $GITHUB_OUTPUT

WORKPATH="$GITHUB_WORKSPACE/$INPUT_PATH"
WORKPATH="${WORKPATH%/}"
echo "Copying files from $BUILDDIR to $WORKPATH"
sudo cp -fv PKGBUILD "$WORKPATH"/PKGBUILD
test -e .SRCINFO && sudo cp -fv .SRCINFO "$WORKPATH"/.SRCINFO
