#!/bin/sh
# Bertrand B.

# Script parameters.
PARAM_CONFIG_FILE="$(dirname "$0")/xplanet.config";
PARAM_TARGET_DIR="$(dirname "$0")/img";
PARAM_PLANET=earth;
PARAM_CRON=false;
PARAM_CLOUDS=false;
PARAM_BACKGROUND=false;
PARAM_REMOVE=false;
PARAM_LABEL=false;

# Xplanet options.
COORD_LONG=0;			# Default longitude.
COORD_LAT=0;			# Default latitude.
LABEL_COLOR=blue;		# Deafult label text color.
LABEL_POS=+0+0;			# Default label position.
GEOMETRY=4096x2048;		# Default image size.

# Images.
FOLDER_IMG="$(dirname "$0")/img";
IMG_PLANET="$PARAM_TARGET_DIR/bg-$PARAM_PLANET-$(date +%s).png";
IMG_CLOUDS="$FOLDER_IMG/earth-clouds.jpg";
IMG_STARS="$FOLDER_IMG/stars.png";
IMG_NOTIFY="$FOLDER_IMG/notify.jpg";

# Download clouds map urls.
URL_CLOUDS="https://raw.githubusercontent.com/apollo-ng/cloudmap/master/global.jpg";
URL_PING="www.google.com";

NOTIFY_CMD="/usr/bin/notify-send";
NULL="/dev/null";

# Used for setting background.
PID=$(pgrep gnome-session -n);
export DBUS_SESSION_BUS_ADDRESS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$PID/environ | cut -d= -f2-);

usage() {
  echo "Usage: ./$(basename "$0") [OPTION]";
  echo "-f, --file:        Use an xplanet configuration file. Default name: $PARAM_CONFIG_FILE.";
  echo "-t, --target:      Set the directory for generated images. Default: $PARAM_TARGET_DIR.";
  echo "-p, --planet:      Choose a specific planet to render. Default: $PARAM_PLANET.";
  echo "-c, --cron:        Add a crontab entry every hour.";
  echo "-dl, --download:   Download the clouds map. Works only for Earth.";
  echo "-bg, --background: Set the rendered image as background.";
  echo "-rm, --remove:     Delete previous images.";
  echo "-h, --help:        Display usage.";
}

configure() {
  while [ "$#" -gt "0" ]; do
    case "$1" in
      -f | --file)
        PARAM_CONFIG_FILE="$2";
        shift 2;
        ;;
      -t | --target)
        PARAM_TARGET_DIR="$2";
        IMG_PLANET="$PARAM_TARGET_DIR/bg-$PARAM_PLANET-$(date +%s).png";
        shift 2;
        ;;
      -p | --planet)
        PARAM_PLANET="$2";
        IMG_PLANET="$PARAM_TARGET_DIR/bg-$PARAM_PLANET-$(date +%s).png";
        shift 2;
        ;;
      -c | --cron)
        PARAM_CRON=true;
        shift 1;
        ;;
      -dl | --download)
        PARAM_CLOUDS=true;
        shift 1;
        ;;
      -bg | --background)
        PARAM_BACKGROUND=true;
        shift 1;
        ;;
      -rm | --remove)
        PARAM_REMOVE=true;
        shift 1;
        ;;
      -h | --help)
        usage;
        exit 0;
        ;;
      --* | -*)
        echo "Unknown parameter $1. Ignored.";
        shift 1;
        ;;
    esac
  done
}

mk_folder() {
  if [ "$PARAM_TARGET_DIR" = "." ]; then
    PARAM_TARGET_DIR=$(pwd);
  fi

  if [ ! -d "$PARAM_TARGET_DIR" ]; then
    mkdir -vp "$PARAM_TARGET_DIR";
  fi
}

dl_clouds() {
  if [ "$PARAM_PLANET" != "earth" ] || [ "$PARAM_CLOUDS" = "false" ] ; then
    return;
  fi

  echo -n "Clouds map required.";
  CONNECTED=$(ping -c 1 $URL_PING > $NULL 2>&1 && echo $?);
  if [ ! "0" -eq "$CONNECTED" ] ; then
    echo " No internet connection. Old clouds map will be used.";
    return;
  fi

  echo " Downloading clouds map.";
  wget $URL_CLOUDS -O $IMG_CLOUDS -q --show-progress --progress=bar:scroll;
}

rm_previous_render() {
  if [ "$PARAM_REMOVE" = "true" ]; then
    rm -vf $PARAM_TARGET_DIR/bg-$PARAM_PLANET*.png;
  fi
}

render() {
  if [ "$PARAM_LABEL" = "true" ]; then
    OPT_LABEL="-label -color $LABEL_COLOR -labelpos $LABEL_POS -fontsize 25";
  fi
  echo -n "Generating image. This may take a while...";
  xplanet -num_times 1 \
    -config $PARAM_CONFIG_FILE \
    -searchdir $FOLDER_IMG \
    -body $PARAM_PLANET \
    -longitude $COORD_LONG \
    -latitude $COORD_LAT \
    -background $IMG_STARS \
    $OPT_LABEL \
    -geometry $GEOMETRY \
    -quality 100 \
    -output $IMG_PLANET > $NULL 2>&1;
  echo " Done !";
}

set_background() {
  if [ "$PARAM_BACKGROUND" = "true" ]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$(readlink -f "$IMG_PLANET")";
  fi
}

notify() {
  $NOTIFY_CMD --icon=$IMG_NOTIFY --app-name=$0 "Xplanet: Explore the stars !";
}

setup_cron() {
  CRONTAB=$(crontab -u $USER -l 2> $NULL | grep -v $(basename "$0"));
  CONF="0 * * * * $(readlink -f "$0") -f $(readlink -f "$PARAM_CONFIG_FILE") -bg -dl -rm -t $PARAM_TARGET_DIR";

  if [ -z "$CRONTAB" ]; then
    echo -e "$CONF" | crontab -u $USER -;
  else
    echo -e "$CRONTAB\n$CONF" | crontab -u $USER -;
  fi
  if [ "$?" = "0" ]; then
    echo "Cron created: $CONF.";
  else
    echo "Cron failed.";
  fi
}

do_xplanet() {
  echo "Planet selected: $PARAM_PLANET." ;
  mk_folder;
  dl_clouds;
  rm_previous_render;
  render;
  set_background;
  notify;
}

run() {
  configure $*;
  if [ "$PARAM_CRON" = "true" ]; then
    setup_cron;
  else
    do_xplanet;
  fi
}

run $*;
