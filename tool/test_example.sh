#!/bin/bash

set -e

cd example/project
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart run build_runner test
dart test_html_builder:browser_aggregate_tests

# These commands target a scenario where there is no build cache and someone
# uses build filters to run a subset of tests.
dart run build_runner clean
dart run build_runner test --delete-conflicting-outputs --build-filter="test/unit/css_test.**" -- test/unit/css_test.dart
