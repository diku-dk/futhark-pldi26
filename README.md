# Meta-Artifact for the paper *Verifying Array Properties in Pure Data-Parallel Programs*

This repository contains a Nix derivation for building the artifact (a
Docker image) for the paper. See [artifact/](artifact/) for the
actual benchmarking infrastructure, including dependencies, if you
want to run it outside docker.

## (Re-)creating the Docker image

### Requirements
- The [Nix](https://nixos.org/) package manager.

### Initial setup

You must initialize and update the submodules:

```
git submodule init
git submodule update
```

### Building the Docker image

Run

```
$ nix-build docker.nix -o propprop.tar.gz
```

This produces a file called `propprop.tar.gz` (a symlink to the actual
image, which is in the Nix store).

See [artifact/README.md](artifact/README.md) for further
instructions.
