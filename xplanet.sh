#!/bin/sh
# Bertrand B.

# xplanet options.
PLANET=earth			# Default planet.
COORD_LONG=0			# Default longitude.
COORD_LAT=0			# Default latitude.
LABEL=false			# Label on image.
LABEL_COLOR=blue		# Deafult label text color.
LABEL_POS=+0+0			# Default label position.
GEOMETRY=4096x2048		# Default image size.
CONFIG_FILE=./xplanet.config	# Default config file.
DL_CLOUDS=false			# Download clouds map.

# Images.
DIR_IMG=./img
PLANET_IMG=$DIR_IMG/bg-$PLANET-`date +%s`.png;
CLOUDS_IMG=$DIR_IMG/earth-clouds.jpg
STARS_IMG=$DIR_IMG/stars.png
NOTIFY_IMG=$DIR_IMG/notify.jpg

# Download clouds map urls.
URL_CLOUDS="http://xplanetclouds.com/free/local/clouds_2048.jpg"
URL_PING="www.google.com"

NOTIFY_CMD=/usr/bin/notify-send
NULL=/dev/null

usage()
{
    echo "Usage: ./$(basename "$0") [OPTION]";
    echo "-c, --config: Use an xplanet configuration file. Default name: $CONFIG_FILE.";
    echo "-p, --planet: Choose a specific planet to render. Default: $PLANET.";
    echo "-dl:          Download the clouds map. Works only for Earth. Note: 2 downloads per day per IP address.";
    echo "-bg:          Set the rendered image as background.";
    echo "-h, --help:   Display usage.";
}

configure(){
    while [ "$#" -gt "0" ]; do
	case "$1" in
	    -c | --config)	# Choose a configuration file.
		CONFIG_FILE="$2";
		shift 2;
		;;
	    -p | --planet)	# Planet.
		PLANET="$2";
		PLANET_IMG=$DIR_IMG/bg-$PLANET-`date +%s`.png;
		shift 2;
		;;
	    -dl)		# Download earth clouds map.
		DL_CLOUDS=true;
		shift 1;
		;;
	    -bg | --background)	# Set the image as background.
		SET_BACKGROUND=true;
		shift 1;
		;;
	    -h | --help)	# Display usage.
		usage;
		exit 0;
		;;
	    -* | --*)		# Unknown option found
		echo "Unknown parameter $1. Ignored.";
		shift 1;
		;;
	esac
    done
}

dl_clouds(){
    echo "Planet Earth requires clouds map.";
    echo -n "Checking internet connexion...";
    CONNECTED=`ping -c 1 $URL_PING > $NULL 2>&1 && echo $?`;
    if [ ! "0" -eq "$CONNECTED" ] ; then
	echo " There is no internet connection.";
	echo "Old clouds map will be used.";
	return;
    fi

    echo " Success.";
    mv $CLOUDS_IMG $CLOUDS_IMG.old;
    echo "Downloading clouds map.";
    wget $URL_CLOUDS -O $CLOUDS_IMG -q --show-progress --progress=bar:scroll ;

    if [ "`file -b $CLOUDS_IMG`" = "ASCII text" ] ; then
      cat $CLOUDS_IMG;
      rm -f $CLOUDS_IMG;
      mv $CLOUDS_IMG.old $CLOUDS_IMG;
      echo "Using old clouds map.";
    else
      echo -n "Deleting old clouds map.";
      rm -f $CLOUDS_IMG.old;
      echo " Done.";
    fi
}

rm_previous_render(){
    echo -n "Deleting old backround images.";
    rm -f $DIR_IMG/bg-*.png;
    echo " Done.";
}

render(){
    echo -n "Generating image. This may take a while...";
    if [ "$LABEL" = "true" ]; then
	OPT_LABEL=-label -color $LABEL_COLOR -labelpos $LABEL_POS -fontsize 25
    fi
    xplanet -num_times 1 -config $CONFIG_FILE -body $PLANET -longitude $COORD_LONG -latitude $COORD_LAT -background $STARS_IMG -geometry $GEOMETRY -quality 100 $OPT_LABEL -output $PLANET_IMG > $NULL 2>&1;
    echo " Done !";
}

set_background(){
    if [ "$SET_BACKGROUND" = "true" ]; then
	echo -n "Setting up background...";
	gsettings set org.gnome.desktop.background picture-uri file://"$(readlink -f $PLANET_IMG)";
	echo " Done !";
    fi
}

notify(){
    $NOTIFY_CMD --icon=$NOTIFY_IMG --app-name=$0 "Xplanet: Explore the stars !";
}

run(){
    configure $*;
    echo "Planet selected: $PLANET." ;
    if [ "$PLANET" = "earth" ] && [ "$DL_CLOUDS" = "true" ] ; then
	dl_clouds;
    fi
    rm_previous_render;
    render;
    set_background;
    notify;
}

run $*;
