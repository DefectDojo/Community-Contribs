# DefectDojo HowTo: Run the django-DefectDojo in a Single Docker Container

## Why do you need to run this stuff
Run the django-DefectDojo in a single Docker container may be useful if you have not so big environment or if you want to train with the product but persist your data.
In my case it was be needed to create one image for our image registry during running django-DefectDojo in MVP mode.

## Initial steps

As bug [#1753](https://github.com/DefectDojo/django-DefectDojo/issues/1753) is not fixed yet I will use my repo from PR [1889](https://github.com/DefectDojo/django-DefectDojo/pull/1880).

Start new Docker container:

```
$ sudo docker run -it -v $PWD/defectdojodata:/var/lib/mysql -p 8000:8000 ubuntu:18.04 bash
```

Run commands inside the running container:

```
# apt-get update

# apt-get install python3-pip git

# pip3 install virtualenv

# cd /opt

# virtualenv dojo

# cd dojo/

# git clone https://github.com/AlexanderTyutin/django-DefectDojo.git

# useradd -m dojo
# cd /opt
# chown -R dojo /opt/dojo
# cd /opt/dojo
# source ./bin/activate

# cd django-DefectDojo/setup
# ./setup.bash -n

# DD_DEBUG=true
# DD_ALLOWED_HOSTS=*

# service mysql start

# cd /opt/dojo
# source ./bin/activate
# cd django-DefectDojo

# python3 manage.py runserver 0.0.0.0:8000
```

After performing these steps you will have running django-DefectDojo instance and initial database for django-DefectDojo.

Stop the container by Ctrl-C and go further.

## Remove the conatiner

As we no longer need the stopped container let's remove it by command:
```
sudo docker container rm ID_OF_YOUR_CONTAINER
```
Also you may remove the image for this container by typing:
```
sudo docker image rm ID_OF_YOUR_IMAGE
```

## Create the image
```
sudo docker build -t defectdojo -f Dockerfile.update .
```
