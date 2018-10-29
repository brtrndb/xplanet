# xplanet

Simple script using xplanet to generate a nice wallpaper.

### Requirements

First install xplanet.

```sh
$ sudo apt-get install xplanet
```

### Usage

```sh
$ ./xplanet.sh -h
Usage: ./xplanet [OPTIONS]
-c, --config: Use an xplanet configuration file. Default name: ./xplanet.config.
-p, --planet: Choose a specific planet to render. Default: earth.
-dl:          Download the clouds map. Works only for Earth. Note: 2 downloads per day per IP address.
-bg:          Set the rendered image as background.
-h, --help:   Display usage.
```

### Links

- Xplanet ressources: http://xplanet.sourceforge.net
- Xplanet clouds: http://xplanetclouds.com/

### Note

Tested on Ubuntu 18.04.

## License

See [LICENSE.md](./LICENSE.md).
