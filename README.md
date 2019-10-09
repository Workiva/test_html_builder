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

Create as many HTML test templates in the `test/` directory as needed, e.g.:

```html
<!-- test/example_template.html -->
<html>
    <head>
        <!-- Load custom assets needed by the test. -->
        <script src="custom.js"></script>

        <!-- Every template must include this token. -->
        {test}
        <!-- It will be replaced by the builder with the required tags:
        <link rel="x-dart-test" href="...">
        <script src="packages/test/dart.js"></script>
        -->
    </head>
</html>
```

Tell the builder which templates should be applied to which files, e.g.:

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

## Contributing

See the [Contributing Guidelines][contributing].

[contributing]: /CONTRIBUTING.md
