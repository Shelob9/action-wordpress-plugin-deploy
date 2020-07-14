#!/bin/bash

# Note that this does not use pipefail
# because if the grep later doesn't match any deleted files,
# which is likely the majority case,
# it does not exit with a 0, and I only care about the final exit.
set -eo

# Set variables
GENERATE_ZIP=true

# Set options based on user input
if [ -z "$1" ]; then
  GENERATE_ZIP=$1;
fi

# Allow some ENV variables to be customized
if [[ -z "$SLUG" ]]; then
	SLUG=${GITHUB_REPOSITORY#*/}
fi
echo "ℹ︎ SLUG is $SLUG"

# Does it even make sense for VERSION to be editable in a workflow definition?
if [[ -z "$VERSION" ]]; then
	VERSION="${GITHUB_REF#refs/tags/}"
	VERSION="${VERSION#v}"
fi 
echo "ℹ︎ VERSION is $VERSION"

if [[ -z "$ASSETS_DIR" ]]; then
	ASSETS_DIR=".wordpress-org"
fi
echo "ℹ︎ ASSETS_DIR is $ASSETS_DIR"

SVN_URL="https://plugins.svn.wordpress.org/${SLUG}/"
SVN_DIR="/github/svn-${SLUG}"

echo "➤ Copying files..."
if [[ -e "$GITHUB_WORKSPACE/.distignore" ]]; then
	echo "ℹ︎ Using .distignore"
	# Copy from current branch to /trunk, excluding dotorg assets
	# The --delete flag will delete anything in destination that no longer exists in source
	rsync -rc --exclude-from="$GITHUB_WORKSPACE/.distignore" "$GITHUB_WORKSPACE/" ninja-forms-mail-chimp --delete --delete-excluded
else
	echo "Must have a .distignore"
	exit 1
fi
echo "workspace ls"
ls $GITHUB_WORKSPACE
echo "workspace/ninja-forms-mailchimp ls"
ls $GITHUB_WORKSPACE/ninja-forms-mail-chimp

if ! $GENERATE_ZIP; then
  echo "Generating zip file..."
  cd "$GITHUB_WORKSPACE/ninja-forms-mail-chimp" || exit
  zip -r "${GITHUB_WORKSPACE}/${SLUG}.zip" .
  echo "✓ Zip file generated!"
fi

echo "✓ Plugin built!"
