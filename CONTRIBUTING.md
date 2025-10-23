# Contributing

## Prerequisites

- [git]
- [just]
- [nushell]
- [nix]
- [docker-compose]

Please review [the development shell](./src/dev.nix) for the complete list of
tools.

## Development

Source code is located in the [src](./src) directory.

Please review the [justfile](./justfile) for the complete list of commands,
existing source code and documentation on how to work with the project.

## Pull requests

Please make sure do the following when making pull requests:

- modify `CHANGELOG.md` by adding changes in the `Unreleased` heading

## Release

For release pull requests please make sure to:

- modify `CHANGELOG.md` by moving `Unreleased` changes into a new release
  heading
- add an appropriate GitHub tag

[git]: https://git-scm.com/
[just]: https://github.com/casey/just
[nushell]: https://www.nushell.sh/
[nix]: https://nixos.org/
[docker-compose]: https://docs.docker.com/compose/
