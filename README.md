# Features

This project **Features** is a set of reusable 'features'. Quickly add a tool/cli to a development container.

*Features* are self-contained units of installation code and development container configuration. Features are designed to install atop a wide-range of base container images.

> This repo follows the [**proposed**  dev container feature distribution specification](https://containers.dev/implementors/features-distribution/).

**List of features:**

* [vimsrc](src/vimsrc/README.md): Vim, from source, choose functions like lua or python.
* [smlnj](src/smlnj/README.md): Standard-ML of New Jersey.
* [mingw](src/mingw/README.md): MinGW-w64.

## Usage

To reference a feature from this repository, add the desired features to a devcontainer.json. Each feature has a README.md that shows how to reference the feature and which options are available for that feature.

The example below installs the *vim* declared in the `./src` directory of this repository.

See the relevant feature's README for supported options.

```jsonc
{
    "image": "ubuntu",
    "features": {
        "ghcr.io/martinaskestadfeatures/vimsrc": {
            "enable_lua": true
        }
    }
}
```
