#!/bin/bash

set -e

cd example/project
dart pub upgrade
dart run build_runner build --delete-conflicting-outputs
dart run build_runner test -- --concurrency=1 # concurrency=1 is a workaround for this issue: https://github.com/dart-lang/test/issues/2294
dart run test_html_builder:browser_aggregate_tests --test-args="--concurrency=1" # concurrency=1 is a workaround for this issue: https://github.com/dart-lang/test/issues/2294

# These commands target a scenario where there is no build cache and someone
# uses build filters to run a subset of tests.
dart run build_runner clean
dart run build_runner test --delete-conflicting-outputs --build-filter="test/unit/css_test.**" -- --concurrency=1 test/unit/css_test.dart # concurrency=1 is a workaround for this issue: https://github.com/dart-lang/test/issues/2294
