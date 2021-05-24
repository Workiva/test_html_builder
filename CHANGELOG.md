## 2.0.1

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
