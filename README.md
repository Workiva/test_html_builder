# `test_html_builder`

A Dart builder that uses templates to generate HTML files for dart tests. Useful
for projects with many tests that require custom HTML. Instead of having to
replicate the custom HTML file for every test file that requires it, this
builder can apply a template to any number of test files.

## Usage

Add this package as a dev_dependency:

```yaml
dev_dependencies:
  test_html_builder: ^1.0.0
```

Create as many HTML test templates in a `test/templates/` directory as needed:

```html
<!-- test/templates/example_template.html -->
<html>
  <head>
    <!-- The "testName" placeholder will be replaced with a unique name for
    each test. -->
    <title>{{testName}} Test</title>

    <!-- Load custom assets needed by the test. -->
    <script src="custom.js"></script>

    <!-- Every template must include this placeholder. -->
    {{testScript}}
    <!-- It will be replaced by the builder with the required <link> tag:
    <link rel="x-dart-test" href="...">
    -->

    <!-- Every template must include the test runner script. -->
    <script src="packages/test/dart.js"></script>
  </head>
</html>
```

Tell the builder which templates should be applied to which files. For example:

```yaml
targets:
  $default:
    builders:
      test_html_builder:
        options:
          templates:
            "test/react_with_styles_template.html":
              - "test/components/styled/**_test.dart"
            "test/react_template.html":
              - "test/components/**_test.dart"
```

To illustrate how this works, consider an example test directory structure:

- `test/`
  - `foo_test.dart`
  - `react_template.html`
  - `react_with_styles_template.html`
  - `components/`
    - `bar_test.dart`
    - `styled/`
      - `baz_test.dart`

Running tests via `pub run build_runner test` with the above configuration will
result in the following (hidden) generated outputs:

- `test/components/bar_test.html` (from `react_template.html`)
- `test/components/styled/baz_test.html` (from `react_with_styles_template.html`)

### Notes

- If there is overlap between the globs defined for multiple templates, the
  builder will choose the first template that matches.

- If none of the templates match for a given test file, no html file will be
  generated.

- One-off custom html files for individual tests are still supported, but they
  must use the `.custom.html` extension:
  - `test/example_test.dart`
  - `test/example_test.custom.html`

## Aggregating Browser Tests

Some projects would like additional assurance in a more production-like
environment. This is typically done by running browser tests in release mode
(`-r|--release`), which compiles them with dart2js. However, in large projects
with a lot of browser tests, this can be prohibitively slow because dart2js is
not a modular compiler like the Dart Dev Compiler. This means that dart2js
treats each browser test as a full program that must be compiled together with
all of the files it imports transitively, which results in a lot of duplicate
work.

One option to workaround this slow process is to create an "aggregate" test that
imports all of your browser tests and runs them. With this in place, dart2js
only needs to compile one thing, but all of your browser tests still run. This
approach has some caveats:
- An aggregate test can only have one HTML file associated with it. If your
project uses multiple HTML templates, you'd need an aggregate test for each.
- You need to setup some config and customize the command used to run tests such
that only the aggregate tests are compiled and run; otherwise, you might still
be spending a bunch of time compiling all of the individual tests unnecessarily.

The builder provided by this package can automate all of this! First, enable
this functionality by setting `browser_aggregation: true`:

```yaml
targets:
  $default:
    builders:
      test_html_builder:
        options:
          templates:
            "test/react_with_styles_template.html":
              - "test/components/styled/**_test.dart"
            "test/react_template.html":
              - "test/components/**_test.dart"
          browser_aggregation: true
```

Once enabled, the builder will generate an aggregate test for each template that
imports and runs each test that uses the template. It will also generate a
default aggregate test for browser tests that don't match any of the templates.
Finally, it generates a `test/dart_test.browser_aggregate.yaml` file that can be
included in your project's `dart_test.yaml` so that the aggregate tests can be
easily selected with this test argument: `--preset=browser-aggregate`

To run these tests, you can use the executable provided by this package:

```
pub run test_html_builder:browser_aggregate_tests [--release]
```

Or, if you have your own test runner that you'd like to integrate this
functionality into, you can run:

```
pub run test_html_builder:browser_aggregate_tests --mode=args [--release]
```

which will print the necessary build_runner and test args in this format:

```
<build args> -- <test args>

# For example:
--release --build-filter=test/templates/react_template.browser_aggregate_test.** -- --preset=browser-aggregate
```

You can parse these or pass them directly into a command to run tests, like so:

```bash
pub run build_runner test $(pub run test_html_builder:browser_aggregate_tests --mode=args [--release])
```

### Randomizing the browser aggregation file
With `dart test`, you can randomize the order in which test files are run by using the `--test-randomize-ordering-seed` flag. However, when using the this package's browser aggregation feature, this method of test order randomization doesn't work because there will be only be one test file for each template. In other words, most of the tests will continue to be run in the same order.

For that reason, test_html_builder also supports a `randomize_ordering_seed` option that can be set in your `build.yaml`. It behaves essentially the same as the `--test-randomize-ordering-seed` flag, meaning that you can set the value to a specific seed or `"random"` if you'd like the seed to be picked at random for you.

Here's an example:

```yaml
targets:
  $default:
    builders:
      test_html_builder:
        options:
          ...
          browser_aggregation: true
          randomize_ordering_seed: random
```

If you notice a test failure due to the specific shuffling that occurred during that test
run, update the `randomize_ordering_seed` option to be whatever was output in the test runners log.

### Note

When randomizing the test order it is recommended to ignore the aggregated test files from version
control to avoid constant updates.

## Contributing

See the [Contributing Guidelines][contributing].

[contributing]: /CONTRIBUTING.md
