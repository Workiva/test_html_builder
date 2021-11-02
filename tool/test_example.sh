#!/bin/bash

set -e

cd example/project
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart run build_runner test
dart run test_html_builder:browser_aggregate_tests
