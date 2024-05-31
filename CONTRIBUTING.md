# Contributing

Contributions are welcome. What is expected from contributors is outlined below. If at any stage you require help, please just ask!

## Issues first

If there is something specific you want to work on, then please open an issue/discussion first to avoid duplication of efforts. Then:

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Make your changes
4. Review the steps below before committing your changes
5. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
6. Push to the Branch (`git push origin feature/AmazingFeature`)
7. Open a Pull Request

## Before committing changes

### Update documentation

Ensure that the `README.md` is updated where changed due to the new feature.

### Lua annotations

Any new or changed functions and module level locals should be annotated with Lua specs. These not only provide documentation but also assist the Language Server with completion and signature information. You can learn more about Lua annotations [here](https://luals.github.io/wiki/annotations/).

### Add tests

Tests should be added to cover any changes or new features. These can be found in the `spec` folder. To run the tests, [Make](https://www.gnu.org/software/make/) is required. Run `make test` from the repository root.

### Format code

This project uses [StyLua](https://github.com/JohnnyMorganz/StyLua) to ensure consistent code formatting.

The StyLua documentation details a number of ways this tool can be installed, including an executable you can just download. Then from the root of this repository run `stylua -g **/*.lua` (or `stylua -g **\*.lua` if on Windows).

Please run StyLua before committing your code. Do not commit the StyLua executable to this repository.

### Lint code

This project uses [Luacheck](https://github.com/mpeterv/luacheck) for static analysis and linting of the code.

### Continuous integration
The CI system used by this repository will run the tests, check the code formatting with Stylua, and lint the code with Luacheck. These checks must pass before a pull request can be merged, so performing these tasks locally first before committing will avoid having to push fix up commits.

### Conventional commits for Commits and PR

Please use the [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/) when writing your commit messages.
