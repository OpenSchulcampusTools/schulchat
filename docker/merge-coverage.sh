#!/bin/bash

python2 scripts/merge-coverage.py -o coverage-merged.xml coverage.xml coverage_widget.xml
lcov -a coverage_widget/lcov.info -a coverage/lcov.info -o lcov_merged.info
genhtml -o coverage_merged lcov_merged.info || true
