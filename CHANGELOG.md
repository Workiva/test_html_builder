## 3.1.0

- The `test/dart_test.browser_aggregate.yaml` file was previously always
generated for backwards-compatibility. With this release, it is only generated
if a reference to it is found in `dart_test.yaml`.

## 3.0.3

- Compatible with Dart 3.
- For consumers using the browser aggregation feature, update the builder to
also output the `dart_test.browser_aggregate.yaml` config file to the same
location used in v2: the `test/` directory. This makes it easier for consumers
to upgrade from v2 to v3.

## 3.0.1

- Sort the imports and test invocations when generating aggregate tests. This
ensures consistent builder outputs across different operating systems.

## 3.0.0

- Migrate to null safety.
- **Breaking change:** the browser aggregation feature now outputs the
`dart_test.browser_aggregate.yaml` config file to the root of your package
instead of the `test/` directory.

## 2.2.2

- When browser aggregation is enabled in `build.yaml`, ensure that the
`test/dart_test.browser_aggregate.yaml` asset is always generated even when
`--build-filter` options are used. This is a workaround only necessary with
older versions of the `build` dependencies and is fixed in the latest.

## 2.2.1

- When running tests, print the `randomize_ordering_seed` that was used to build
each browser aggregate test file. This should make it easier to debug test
failures that occur due to the randomized ordering.

## 2.2.0

- Add ability to 'randomize' tests within the aggregated test file with the
`randomize_ordering_seed` option.

## 2.1.3

- **Bug fix:** using the browser aggregation feature now works with build
filters. Previously this would fail because the
`dart_test.browser_aggregate.yaml` output would be filtered out.

## 2.1.2

- Treat Dart 2.13.4 as the primary SDK target for CI.

## 2.1.1

- Widen dependency ranges blocking Dart 2.13.

## 2.1.0

- Add support for `--build-args` to the browser aggregation feature.
- Hardcode `--delete-conflicting-outputs` in the first `build_runner` command
that is executed by the browser aggregation feature.
- Update the "args" mode of the browser aggregation feature so it doesn't
parrot back the build arguments it uses when running the build_runner.

## 2.0.0

[browser-aggregation]: /README.md#aggregating-browser-tests
[test-package-custom-html]: https://github.com/dart-lang/test/tree/master/pkgs/test#running-tests-with-custom-html

- Add a [browser aggregation feature][browser-aggregation] that automates the
generation and running of aggregate tests for browser tests. In large projects
with a lot of browser tests, this approach significantly speeds up the building
of these tests with dart2js, and it may also speed up the execution time with
DDC. See the readme for more info.

- **Breaking:** Update HTML template expectations to match [those from the `test` package][test-package-custom-html].
Templates must now have a `{{testScript}}` placeholder instead of `{test}` and
they must also include `<script src="packages/test/dart.js"></script>`.

    This allows projects that may have already been using custom HTML for tests
    to more easily adopt this package. It also makes it possible in the future
    for this package to support projects that use a single HTML template via the
    test package's `custom_html_template_path` option.

- Switch from Travis CI to a GitHub Workflow.

## 1.0.2

- Fix #8.
- Address pub health/maintenance recommendations (add an example, add missing
  doc comments).

## 1.0.1

- Update package metadata in `pubspec.yaml`.

## 1.0.0

- Initial version.
