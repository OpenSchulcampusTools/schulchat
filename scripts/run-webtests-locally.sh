#!/usr/bin/env bash

#TODO note cleanup synapse container before!

export FLUTTER_TOOLS=$*

export HOMESERVER=synapse
export INTEGRATION_USER1=integration1
export INTEGRATION_USER2=integration2
export INTEGRATION_PASSWORD1=$(openssl rand -base64 30)
export INTEGRATION_PASSWORD2=$(openssl rand -base64 30)

echo "passwords: integration1: ${INTEGRATION_PASSWORD1} and integration2: ${INTEGRATION_PASSWORD2}"

echo "stopping and removing any old synapse container"
sudo docker stop synapse
sudo docker container rm synapse

echo "cleaning up old database"
rm -f integration_test/synapse/data/homeserver.db*

echo "running synapse"
sudo docker run -d --name synapse -h $HOMESERVER -v $(pwd)/integration_test/synapse/data:/data matrixdotorg/synapse:latest
export SYNAPSE_IP=$(sudo docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' synapse)
echo "synapse server ip: ${SYNAPSE_IP}"

./scripts/integration-prepare-homeserver.sh

sed -i "s#test.schulchat.rlp.de#synapse#g" config.sample.json lib/config/app_config.dart
sed -i 's#homeserver = Uri.https#homeserver = Uri.http#g' lib/pages/homeserver_picker/homeserver_picker.dart
sed -i 's#var newDomain = Uri.https#var newDomain = Uri.http#g' lib/pages/login/login.dart
sed -i 's#disableAuthWithUsernameAndPassword = true#disableAuthWithUsernameAndPassword = false#g' lib/config/edu_settings.dart

# encryption
mkdir -p assets/js/package
./scripts/prepare-web.sh

flutter config --enable-web

if [ -f "$FLUTTER_TOOLS" ]; then
  echo "using dart drive"
  # headless
  dart --disable-dart-dev $FLUTTER_TOOLS drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d chrome --web-run-headless --headless --dart-define=Dart2jsOptimization=O0 --dart-define=INTEGRATION_USER1=$INTEGRATION_USER1 --dart-define=INTEGRATION_USER2=$INTEGRATION_USER2 --dart-define=INTEGRATION_PASSWORD1=$INTEGRATION_PASSWORD1 --dart-define=INTEGRATION_PASSWORD2=$INTEGRATION_PASSWORD2 --debug
else
  echo "using flutter drive"
  # not headless, needs chromedriver, e.g. `./chromedriver --port=4444 --enable-chrome-logs --verbose --log-path=/tmp/chromedriver.log`
  flutter drive -d chrome --dart-define=Dart2jsOptimization=O0 --dart-define=INTEGRATION_USER1=$INTEGRATION_USER1 --dart-define=INTEGRATION_USER2=$INTEGRATION_USER2 --dart-define=INTEGRATION_PASSWORD1=$INTEGRATION_PASSWORD1 --dart-define=INTEGRATION_PASSWORD2=$INTEGRATION_PASSWORD2 --debug --driver=test_driver/integration_test.dart integration_test/app_test.dart
fi
