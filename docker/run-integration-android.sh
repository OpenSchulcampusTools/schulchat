#!/bin/bash

export PATH="${PATH}:/tmp/flutter/.pub-cache/bin:${HOME}/.pub-cache/bin"

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
if [ -z "$TEST_DEVICE" ]; then
  echo "TEST_DEVICE not set"
  exit 1
fi

echo "Getting .well-known from docker entrypoint"
curl -XGET "http://synapse/.well-known/matrix/client"

adb start-server
emulator -avd $TEST_DEVICE -wipe-data -no-audio -no-boot-anim -no-window -accel on -gpu swiftshader_indirect -memory 2048 -writable-system & # run in background

adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'

#TODO find a way to accept permissions from the tests
#adb shell pm grant de.rlp.schulchat android.permission.POST_NOTIFICATIONS
#adb shell pm grant de.rlp.schulchat android.permission.ACCESS_NOTIFICATION_POLICY
#TODO these are too many permissions, identify the relevant ones
adb shell pm grant de.rlp.schulchat android.permission.ACCESS_COARSE_LOCATION
adb shell pm grant de.rlp.schulchat android.permission.ACCESS_FINE_LOCATION
adb shell pm grant de.rlp.schulchat android.permission.BIND_TELECOM_CONNECTION_SERVICE
adb shell pm grant de.rlp.schulchat android.permission.BLUETOOTH
adb shell pm grant de.rlp.schulchat android.permission.CALL_PHONE
adb shell pm grant de.rlp.schulchat android.permission.CAMERA
adb shell pm grant de.rlp.schulchat android.permission.FOREGROUND_SERVICE
adb shell pm grant de.rlp.schulchat android.permission.INTERNET
adb shell pm grant de.rlp.schulchat android.permission.MODIFY_AUDIO_SETTINGS
adb shell pm grant de.rlp.schulchat android.permission.READ_EXTERNAL_STORAGE
adb shell pm grant de.rlp.schulchat android.permission.READ_PHONE_STATE
adb shell pm grant de.rlp.schulchat android.permission.RECORD_AUDIO
adb shell pm grant de.rlp.schulchat android.permission.SYSTEM_ALERT_WINDOW
adb shell pm grant de.rlp.schulchat android.permission.USE_FULL_SCREEN_INTENT
adb shell pm grant de.rlp.schulchat android.permission.VIBRATE
adb shell pm grant de.rlp.schulchat android.permission.WAKE_LOCK
adb shell pm grant de.rlp.schulchat android.permission.WRITE_EXTERNAL_STORAGE

#push /etc/hosts file from docker container so we can reach synapse
adb root
adb shell avbctl disable-verification
sleep 10
adb reboot
sleep 20
adb wait-for-device shell 'while [[ -z $(getprop sys.boot_completed) ]]; do sleep 1; done;'
adb root
adb remount
adb push /etc/hosts /system/etc

flutter devices
scrcpy --no-display --record video.mkv &

# import all files so coverage report is accurate, as
# it will report only on the touched files
IMPORTS=$(find lib -name '*.dart'|sed -e "s#^lib#import 'package:fluffychat#g" -e "s#\$#';#g")
echo -e "${IMPORTS}\n$(cat integration_test/app_test.dart)" >integration_test/app_test.dart

flutter test -d emulator-5554 integration_test --coverage --dart-define=INTEGRATION_USER1=$INTEGRATION_USER1 --dart-define=INTEGRATION_PASSWORD1=$INTEGRATION_PASSWORD1 --dart-define=INTEGRATION_USER2=$INTEGRATION_USER2 --dart-define=INTEGRATION_PASSWORD2=$INTEGRATION_PASSWORD2 --reporter json | tee TEST-results.json
exit_code=${PIPESTATUS[0]}
echo "Done running tests. Exit code was $exit_code"
flutter pub global activate junitreport
echo "Done activating junitreport."
grep '^{' TEST-results.json > TEST-report.json # workaround for https://github.com/flutter/flutter/issues/97799
flutter pub global run junitreport:tojunit --input TEST-report.json --output TEST-report.xml
echo "Done converting test report."
#sed 's/&#x1B;//g' -i TEST-report.xml
genhtml -o coverage coverage/lcov.info || true
echo "Done genhtml."
curl https://raw.githubusercontent.com/eriwen/lcov-to-cobertura-xml/master/lcov_cobertura/lcov_cobertura.py > lcov_cobertura.py #TODO how to install package without migrating to docker images?
chmod +x lcov_cobertura.py
./lcov_cobertura.py coverage/lcov.info || true
ls -la
echo "Done cobertura."
echo $exit_code >exit_code
