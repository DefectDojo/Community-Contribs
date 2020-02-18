#!/bin/bash

# The script for creating image with Dockerfile.update
# Author: Alexander Tyutin <alexander@tyutin.net> https://github.com/AlexanderTyutin

apt-get update
apt-get install -y python3-pip git

pip3 install virtualenv

cd /opt

virtualenv dojo

cd dojo/

git clone https://github.com/AlexanderTyutin/django-DefectDojo.git

useradd -m dojo
cd /opt
chown -R dojo /opt/dojo
cd dojo
source ./bin/activate
cd django-DefectDojo/setup

./setup.bash -n
