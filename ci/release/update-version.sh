#!/bin/bash
#############################
# cuxfilter Version Updater #
#############################

## Usage
# bash update-version.sh <type>
#     where <type> is either `major`, `minor`, `patch`

set -e

# Grab argument for release type
RELEASE_TYPE=$1

# Get current version and calculate next versions
CURRENT_TAG=`git tag | grep -xE 'v[0-9\.]+' | sort --version-sort | tail -n 1 | tr -d 'v'`
CURRENT_MAJOR=`echo $CURRENT_TAG | awk '{split($0, a, "."); print a[1]}'`
CURRENT_MINOR=`echo $CURRENT_TAG | awk '{split($0, a, "."); print a[2]}'`
CURRENT_PATCH=`echo $CURRENT_TAG | awk '{split($0, a, "."); print a[3]}'`
NEXT_MAJOR=$((CURRENT_MAJOR + 1))
NEXT_MINOR=$((CURRENT_MINOR + 1))
NEXT_PATCH=$((CURRENT_PATCH + 1))
CURRENT_SHORT_TAG=${CURRENT_MAJOR}.${CURRENT_MINOR}
NEXT_FULL_TAG=""
NEXT_SHORT_TAG=""

# Determine release type
if [ "$RELEASE_TYPE" == "major" ]; then
  NEXT_FULL_TAG="${NEXT_MAJOR}.0.0"
  NEXT_SHORT_TAG="${NEXT_MAJOR}.0"
elif [ "$RELEASE_TYPE" == "minor" ]; then
  NEXT_FULL_TAG="${CURRENT_MAJOR}.${NEXT_MINOR}.0"
  NEXT_SHORT_TAG="${CURRENT_MAJOR}.${NEXT_MINOR}"
elif [ "$RELEASE_TYPE" == "patch" ]; then
  NEXT_FULL_TAG="${CURRENT_MAJOR}.${CURRENT_MINOR}.${NEXT_PATCH}"
  NEXT_SHORT_TAG="${CURRENT_MAJOR}.${CURRENT_MINOR}"
else
  echo "Incorrect release type; use 'major', 'minor', or 'patch' as an argument"
  exit 1
fi

echo "Preparing '$RELEASE_TYPE' release [$CURRENT_TAG -> $NEXT_FULL_TAG]"

# Inplace sed replace; workaround for Linux and Mac
function sed_runner() {
    sed -i.bak ''"$1"'' $2 && rm -f ${2}.bak
}

# RTD update
sed_runner 's/version = .*/version = '"'${NEXT_SHORT_TAG}'"'/g' docs/source/conf.py
sed_runner 's/release = .*/release = '"'${NEXT_FULL_TAG}'"'/g' docs/source/conf.py

# bump cudf
for FILE in conda/environments/*.yml; do
  sed_runner "s/cudf=.*/cudf=${NEXT_SHORT_TAG}/g" ${FILE};
  sed_runner "s/cuspatial=.*/cuspatial=${NEXT_SHORT_TAG}/g" ${FILE};
  sed_runner "s/dask-cuda=.*/dask-cuda=${NEXT_SHORT_TAG}/g" ${FILE};
  sed_runner "s/dask-cudf=.*/dask-cudf=${NEXT_SHORT_TAG}/g" ${FILE};
done

# README.md update
sed_runner "s/version == ${CURRENT_SHORT_TAG}/version == ${NEXT_SHORT_TAG}/g" README.md
sed_runner "s/cuxfilter=${CURRENT_SHORT_TAG}/cuxfilter=${NEXT_SHORT_TAG}/g" README.md
