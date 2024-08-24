#!/bin/sh -ve
rm -r assets/js/package
mkdir -p assets/js/package
touch assets/js/package/.gitkeep

OLM_VERSION=$(cat pubspec.yaml | yq -r .dependencies.flutter_olm)
DOWNLOAD_PATH="https://github.com/famedly/olm/releases/download/v$OLM_VERSION/olm.zip"

cd assets/js/ && curl -L $DOWNLOAD_PATH > olm.zip && cd ../../
cd assets/js/ && unzip olm.zip && cd ../../
cd assets/js/ && rm olm.zip && cd ../../
cd assets/js/ && mv javascript package && cd ../../
