#!/bin/bash

set -eu

# Constants
HOME=/home/builder
BUILDDIR="$HOME"/work

# Preconditions
if [ -z "$INPUT_PKGVER" -a -z "$INPUT_PKGREL" ] ; then
	echo "At least a pkgver or a pkgrel must be given."
	exit 1
fi

# Setup
mkdir -p "$BUILDDIR"
cd "$BUILDDIR"

cp -rTfv "$GITHUB_WORKSPACE"/ ./
test "x$INPUT_PATH" != 'x' && cd "$INPUT_PATH"

# Main
if [ "x$INPUT_PKGVER" != 'x' ] ; then
	echo "Updating pkgver of PKGBUILD"
	sed -i "s/^pkgver=.*$/pkgver=$INPUT_PKGVER/g" PKGBUILD
	git --no-pager diff PKGBUILD
fi

if [ "x$INPUT_PKGREL" != 'x' ] ; then
	echo "Updating pkgrel of PKGBUILD"
	sed -i "s/^pkgrel=.*$/pkgrel=$INPUT_PKGREL/g" PKGBUILD
	git --no-pager diff PKGBUILD
fi

if [ "$INPUT_UPDPKGSUMS" = 'true' ] ; then
	echo "Updating checksums of PKGBUILD"
	updpkgsums
	git --no-pager diff PKGBUILD
fi

if [ "$INPUT_SRCINFO" = 'true' -o [ "$INPUT_SRCINFO" = 'auto' -a -e .SRCINFO ] ] ; then
	echo "Generating new .SRCINFO based on PKGBUILD"
	makepkg --printsrcinfo > .SRCINFO
	git --no-pager diff .SRCINFO
fi

if [ "$INPUT_NAMCAP" = 'true' ] ; then
	echo "Validating PKGBUILD with namcap"
	namcap $INPUT_NAMCAP_OPTS PKGBUILD
fi

# Outputs
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
