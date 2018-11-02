# xplanet

Simple script using xplanet to generate a nice wallpaper.

## Installation

First, clone the repository.

```sh
$ git clone https://github.com/brtrndb/xplanet.git
```

## Requirements

Then install xplanet.

```sh
$ sudo apt-get install xplanet
```

## Usage

```sh
$ ./xplanet.sh -h
Usage: ./xplanet.sh [OPTION]
-f, --file:        Use an xplanet configuration file. Default name: ./xplanet.config.
-t, --target:      Set the directory for generated images. Default: ./img.
-p, --planet:      Choose a specific planet to render. Default: earth.
-c, --cron:        Add a crontab entry every hour.
-dl, --download:   Download the clouds map. Works only for Earth.
-bg, --background: Set the rendered image as background.
-rm, --remove:     Delete previous images.
-h, --help:        Display usage.
```

## Links

- Xplanet ressources: http://xplanet.sourceforge.net
- Xplanet clouds: http://xplanetclouds.com/

## Note

Tested on Ubuntu 18.04.

## License

See [LICENSE.md](./LICENSE.md).
