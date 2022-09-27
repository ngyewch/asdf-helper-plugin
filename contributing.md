# Contributing

Testing Locally:

```shell
asdf plugin test <plugin-name> <plugin-url> [--asdf-tool-version <version>] [--asdf-plugin-gitref <git-ref>] [test-command*]

#
asdf plugin test asdf-helper https://github.com/ngyewch/asdf-asdf-helper.git "asdf-helper version"
```

Tests are automatically run in GitHub Actions on push and PR.
