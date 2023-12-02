#!/bin/sh
# Bertrand B.

NULL="/dev/null";
SCRIPT_PATH="$(cd -- "$(dirname "$0")" > $NULL 2>&1 ; pwd -P)";
TEXTURES_FOLDER="$SCRIPT_PATH/img";

# Script parameters.
CONFIG_FILE="$SCRIPT_PATH/xplanet.config";
PLANET=earth;
SETUP_CRON=false;
SETUP_BACKGROUND=false;
DELETE_PREVIOUS=false;
INCLUDE_LABEL=false;
NOTIFY=true

EARTH_CLOUDS_MAP_URL="https://matteason.github.io/daily-cloud-maps/8192x4096-clouds.jpg";
PING_URL="www.google.com";

NOTIFY_CMD="/usr/bin/notify-send";
IMG_NOTIFY_ICON="$TEXTURES_FOLDER/notify.jpg";

# Xplanet options.
LONGITUDE=0;
LATITUDE=0;
LABEL_COLOR=blue;
LABEL_POS=+0+0;
GEOMETRY=4096x2048;
BACKGROUND_STARS="$TEXTURES_FOLDER/stars.png";

# Used for setting background.
PID=$(pgrep gnome-session -n);
export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/"$PID"/environ | cut -d= -f2-);

usage() {
  echo "Usage: ./$(basename "$0") [OPTION]";
  echo "-f, --file:        Use an xplanet configuration file. Default name: $CONFIG_FILE.";
  echo "-p, --planet:      Choose a specific planet to render. Default: $PLANET.";
  echo "-c, --cron:        Add a crontab entry every hour.";
  echo "-bg, --background: Set the rendered image as background.";
  echo "-d, --delete:      Delete previous images.";
  echo "-nn, --no-notify:  Disable notification once render is terminated.";
  echo "-h, --help:        Display usage.";
}

run() {
  configure $*;

  if [ "$SETUP_CRON" = "true" ]; then
    run_cron_setup;
  else
    run_xplanet;
  fi
}

configure() {
  while [ "$#" -gt "0" ]; do
    case "$1" in
      -f | --file)
        CONFIG_FILE="$2";
        shift 2;
        ;;
      -p | --planet)
        PLANET="$2";
        shift 2;
        ;;
      -c | --cron)
        SETUP_CRON=true;
        shift 1;
        ;;
      -bg | --background)
        SETUP_BACKGROUND=true;
        shift 1;
        ;;
      -d | --delete)
        DELETE_PREVIOUS=true;
        shift 1;
        ;;
      -nn | --no-notify)
        NOTIFY=false;
        shift 1;
        ;;
      -h | --help)
        usage;
        exit 0;
        ;;
      --* | -*)
        echo "Unknown parameter '$1'.";
        usage;
        exit 0;
        ;;
    esac
  done
}

run_cron_setup() {
  CRONTAB=$(crontab -u $USER -l 2> $NULL | grep -v $(basename "$0"));
  CONF="0 * * * * $(readlink -f "$0") -f $(readlink -f "$CONFIG_FILE") -bg -d -nn";

  if [ -z "$CRONTAB" ]; then
    echo -e "$CONF" | crontab -u "$USER" -;
  else
    echo -e "$CRONTAB\n$CONF" | crontab -u "$USER" -;
  fi
  if [ "$?" = "0" ]; then
    echo "Cron created: $CONF.";
  else
    echo "Cron failed.";
  fi
}

run_xplanet() {
  RENDERED="$TEXTURES_FOLDER/bg-$PLANET-$(date +%s)-$GEOMETRY.png";

  render "$RENDERED";
  delete_previous_render;
  set_background "$RENDERED";
  notify;
}

render() {
  echo "Rendering planet $PLANET. This may take a while...";

  if [ "$PLANET" = "earth" ]; then
    get_earth_clouds_map;
  fi

  if [ "$INCLUDE_LABEL" = "true" ]; then
    OPT_LABEL="-label -color $LABEL_COLOR -labelpos $LABEL_POS -fontsize 25";
  fi

  xplanet -num_times 1 \
    -config "$CONFIG_FILE" \
    -searchdir "$TEXTURES_FOLDER" \
    -body "$PLANET" \
    -longitude $LONGITUDE \
    -latitude $LATITUDE \
    -background "$BACKGROUND_STARS" \
    $OPT_LABEL \
    -geometry $GEOMETRY \
    -quality 100 \
    -output "$1" > $NULL 2>&1;
  echo "Done !";
}

get_earth_clouds_map() {
  IS_CONNECTED=$(ping -c 1 $PING_URL > $NULL 2>&1 && echo $?);
  if [ ! "0" -eq "$IS_CONNECTED" ] ; then
    echo "No internet. Previous clouds map will be used if any.";
    return;
  fi

  EARTH_CLOUDS_MAP="$TEXTURES_FOLDER/earth-clouds-$(date +%s).jpg";

  echo "Downloading earth clouds map.";
  wget $EARTH_CLOUDS_MAP_URL -O "$EARTH_CLOUDS_MAP" --no-cache -q -T 5;

  LATEST_EARTH_CLOUDS_MAP=$(find "$TEXTURES_FOLDER" -type f -name earth-clouds-*.jpg | sort | tac | tail -n +2)
  rm -f $LATEST_EARTH_CLOUDS_MAP;
}

delete_previous_render() {
  if [ "$DELETE_PREVIOUS" = "true" ]; then
    LATEST_BACKGROUND=$(find "$TEXTURES_FOLDER" -type f -name bg-"$PLANET"-*.png | sort | tac | tail -n +2)
    rm -f $LATEST_BACKGROUND;
  fi
}

set_background() {
  if [ "$SETUP_BACKGROUND" = "true" ]; then
    echo "Updating background.";

    COLOR_SCHEME=$(gsettings get org.gnome.desktop.interface color-scheme);
    if [ "$COLOR_SCHEME" = "'prefer-dark'" ]; then
      gsettings set org.gnome.desktop.background picture-uri-dark "file://$(readlink -f "$1")";
    else
      gsettings set org.gnome.desktop.background picture-uri "file://$(readlink -f "$1")";
    fi
  fi
}

notify() {
  if [ "$NOTIFY" = "true" ]; then
    $NOTIFY_CMD --icon="$IMG_NOTIFY_ICON" --app-name="$0" "Xplanet: Explore the stars !";
  fi
}

run $*;
