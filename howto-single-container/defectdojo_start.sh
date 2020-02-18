#!/bin/bash

# The aim of this script is to run DefectDojo application regularly over existing artifacts:
# * database files
# * application files
# Author: Alexander Tyutin <alexander@tyutin.net> https://github.com/AlexanderTyutin

# Fill variables values from input parameters
for i in "$@"
do
        case $i in
                -appdir=*)
                APPDIR="${i#*=}"
                shift
                ;;
                -dbdir=*)
                DBDIR="${i#*=}"
                shift
                ;;
        esac
done
# -------------------------------------------

# Check variables values and corresponding directories
[ -z "$APPDIR" ] && echo "<appdir> parameter is not set. Exiting." && exit
if [ ! -d $APPDIR ]; then
	echo "Application directory <appdir> does not exist. Exiting."
	exit
fi

[ -z "$DBDIR" ] && echo "<dbdir> parameter is not set. Exiting." && exit
if [ ! -d $DBDIR ]; then
        echo "Database directory <dbdir> does not exist. Exiting." 
        exit
fi
# --------------------------------------------

# Run image building and application setup
# to get artifacts: application and ready database

docker run -it -v $DBDIR:/var/lib/mysql -v $APPDIR:/opt/dojo --name defectdojoapp -p 8000:8000 defectdojo
# ------------------------------------------------

