#!/bin/sh
# Update desktop wallpaper with xplanet.
# Ubuntu 15.10.

# xplanet options.
PLANET=earth
COORD_LONG=0
COORD_LAT=0
LABEL=false
LABEL_COLOR=blue
LABEL_POS=+0+0
GEOMETRY=4096x2048
CONFIG_FILE=./xplanet.config

# Images.
DIR_IMG=./img
PLANET_IMG=$DIR_IMG/bg-$PLANET-`date +%s`.png;
CLOUDS_IMG=$DIR_IMG/earth-clouds.jpg
STARS_IMG=$DIR_IMG/stars.png
NOTIFY_IMG=$DIR_IMG/notify.jpg

# Download clouds map urls.
URL_CLOUDS="http://home.megapass.co.kr/~gitto88/cloud_data/clouds_4096.jpg"
#URL_CLOUDS=http://xplanetclouds.com/free/local/clouds_2048.jpg
NULL=/dev/null

NOTIFY_CMD=/usr/bin/notify-send

DL_CLOUDS=false

echo "Xplanet wallpaper script. (`date "+%H:%M:%S"`).";

if [ "$PLANET" = "earth" ] && [ "$DL_CLOUDS" = "true" ];
then
    echo " > Planet Earth needs clouds map. ";
    echo -n " > Checking internet connexion.";
    if ping -c 3 google.com > $NULL 2>&1;
    then
	echo " Connected !";
	echo -n " > Deleting old clouds map.";
	rm -f $CLOUDS_IMG;
	echo " Done !";
	echo -n " > Downloading clouds map...";
	wget $URL_CLOUDS -O $CLOUDS_IMG > $NULL 2>&1
	echo " Done !";
    else
	echo " Connection failed.";
	echo -n " > Old clouds map used instead..";
    fi
else
    echo " > Planet selected: $PLANET." ;
fi

echo -n " > Deleting old backround images...";
rm -f $DIR_IMG/bg-*.png;
echo " Done !";

echo -n " > Generating new background image.";
if [ "$LABEL" = "true" ];
then
    OPT_LABEL=-label -color $LABEL_COLOR -labelpos $LABEL_POS -fontsize 25
fi
xplanet -num_times 1 -config $CONFIG_FILE -body $PLANET -longitude $COORD_LONG -latitude $COORD_LAT -background $STARS_IMG -geometry $GEOMETRY -quality 100 $OPT_LABEL -output $PLANET_IMG > $NULL 2>&1;
echo " Done !";

echo -n " > Setting up background.";
$NOTIFY_CMD --icon=$NOTIFY_IMG --app-name=$0 "Xplanet: Mise à jour terminée.";
echo " Done !";
return 0;
