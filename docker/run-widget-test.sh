#!/bin/bash

export PATH="$PATH:/tmp/flutter/.pub-cache/bin:$HOME/.pub-cache/bin"

# import all files so coverage report is accurate, as
# it will report only on the touched files
IMPORTS=$(find lib -name '*.dart'|sed -e "s#^lib#import 'package:fluffychat#g" -e "s#\$#';#g")
echo -e "${IMPORTS}\n$(cat test/widget_test.dart)" >test/widget_test.dart

flutter test --coverage --machine --reporter json --coverage-path coverage_widget/lcov.info | tee TEST-results.json
exit_code=${PIPESTATUS[0]}
echo "Done running tests. Exit code was $exit_code"
flutter pub global activate junitreport
echo "Done activating junitreport."
grep '^{' TEST-results.json > TEST-report.json # workaround for https://github.com/flutter/flutter/issues/97799
flutter pub global run junitreport:tojunit --input TEST-report.json --output TEST-report.xml
echo "Done converting test report."
#sed 's/&#x1B;//g' -i TEST-report.xml
genhtml -o coverage_widget coverage_widget/lcov.info || true
echo "Done genhtml."
curl https://raw.githubusercontent.com/eriwen/lcov-to-cobertura-xml/master/lcov_cobertura/lcov_cobertura.py > lcov_cobertura.py #TODO how to install package without migrating to docker images?
python3 ./lcov_cobertura.py coverage_widget/lcov.info || true
mv coverage.xml coverage_widget.xml
echo "Done cobertura."
echo $exit_code >exit_code
