#!/bin/bash

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
if [ -z "$HOMESERVER" ]; then
  echo "Please ensure HOMESERVER environment variable is set to the IP or hostname of the homeserver."
  exit 1
fi
if [ -z "$SYNAPSE_IP" ]; then
  echo "Please ensure SYNAPSE_IP environment variable is set to the IP of the homeserver."
  exit 1
fi

#for android tests we put it outside the entrypoint and it works
#not sure why it cannot reach synapse
timeout 30s sh scripts/integration-prepare-homeserver.sh

./chromedriver --port=4444 --enable-chrome-logs --verbose --log-path=/tmp/chromedriver.log &

echo "waiting 5s so that chromedriver can finish startup"
sleep 5

# On local system it might be helpful to add --keep-app-running so you can inspect the console log until we know how to get it here
#flutter drive -d chrome --dart-define=Dart2jsOptimization=O1 --dart-define=INTEGRATION_USER1=$INTEGRATION_USER1 --dart-define=INTEGRATION_PASSWORD1=$INTEGRATION_PASSWORD1 --dart-define=INTEGRATION_USER2=$INTEGRATION_USER2 --dart-define=INTEGRATION_PASSWORD2=$INTEGRATION_PASSWORD2 --release --driver=test_driver/integration_test.dart integration_test/alltests.dart --web-run-headless
dart --disable-dart-dev /tmp/flutter/packages/flutter_tools/bin/flutter_tools.dart  drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome --web-run-headless --headless --dart-define=Dart2jsOptimization=O0 --dart-define=INTEGRATION_USER1=$INTEGRATION_USER1 --dart-define=INTEGRATION_USER2=$INTEGRATION_USER2 --dart-define=INTEGRATION_PASSWORD1=$INTEGRATION_PASSWORD1 --dart-define=INTEGRATION_PASSWORD2=$INTEGRATION_PASSWORD2 --release
exit_code=$?
echo "Widget test finished. Exit code was $exit_code"
echo $exit_code >/tmp/exit_code
