#!/bin/bash

set -e

if [ -z "$INTEGRATION_USER1" ]; then
  echo "INTEGRATION_USER1 not set"
  exit 1
fi
if [ -z "$INTEGRATION_PASSWORD1" ]; then
  echo "INTEGRATION_PASSWORD1 not set"
  exit 1
fi
if [ -z "$INTEGRATION_USER2" ]; then
  echo "INTEGRATION_USER2 not set"
  exit 1
fi
if [ -z "$INTEGRATION_PASSWORD2" ]; then
  echo "INTEGRATION_PASSWORD2 not set"
  exit 1
fi

./chromedriver --port=4444&

echo "waiting 5s so that chromedriver can finish startup"
sleep 5

# On local system it might be helpful to add --keep-app-running so you can inspect the console log until we know how to get it here
flutter drive -d chrome --dart-define=Dart2jsOptimization=O1 --dart-define=INTEGRATION_USER1=$INTEGRATION_USER1 --dart-define=INTEGRATION_PASSWORD1=$INTEGRATION_PASSWORD1 --dart-define=INTEGRATION_USER2=$INTEGRATION_USER2 --dart-define=INTEGRATION_PASSWORD2=$INTEGRATION_PASSWORD2 --release --driver=test_driver/integration_test.dart integration_test/alltests.dart --web-run-headless
