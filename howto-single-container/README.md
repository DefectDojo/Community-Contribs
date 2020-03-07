# DefectDojo HowTo: Run the django-DefectDojo in a Single Docker Container

## Why do you need to run this stuff
Run the django-DefectDojo in a single Docker container may be useful if you have not so big environment or if you want to train with the product but persist your data.
In my case it was be needed to create one image for our image registry during running django-DefectDojo in MVP mode.

As bug [#1753](https://github.com/DefectDojo/django-DefectDojo/issues/1753) is not fixed yet I will use my repo from PR [1889](https://github.com/DefectDojo/django-DefectDojo/pull/1880).

## Create directories for application and database and run defectdojo_init.sh script

```
mkdir ddjdb
mkdir ddjapp
sudo ./defectdojo_init.sh -appdir=${PWD}/ddjapp -dbdir=${PWD}/ddjdb
```

## Create your working image and make test run

```
sudo ./defectdojo_install.sh -appdir=${PWD}/ddjapp -dbdir=${PWD}/ddjdb
```

## Run you application in working mode

```
sudo ./defectdojo_start.sh -appdir=${PWD}/ddjapp -dbdir=${PWD}/ddjdb
```

## Reset admin password for web interface.

This item created with great appreciate to @Sudneo comment in https://github.com/DefectDojo/django-DefectDojo/issues/642

Enter into the container shell

```
sudo docker exec -it defectdojoapp bash
```

Run mysql client for local server

```
mysql
```

Execute commands in the mysql shell

```
use dojodb;
UPDATE auth_user SET password='pbkdf2_sha256$36000$sT96yObJtsFk$F9YAJimsQqBXnff/QGLNTv100qhCNl/23hoBuNtSNZU=' WHERE username='admin';
quit;
```

## Log in to your django-DefectDojo instance

Navigate to http://127.0.0.1:8000/ in your browser and login with admin:admin pair.

## Future errors possible

### Can't connect to defectDojo web server, errors in MySql logs
```
django.db.utils.OperationalError: (2002, "Can't connect to local MySQL server through socket '/var/run/mysqld/mysqld.sock' (2)")
```

Check for mysql errors from the inside of the container:

```
$ sudo docker exec -it defectdojoapp bash
# cat /var/log/mysql/error.log
```

If you will see such string:

```
...
2020-02-21T12:45:50.627311Z 11 [Note] Access denied for user 'debian-sys-maint'@'localhost' (using password: YES)
...
```

then [this thread from StackOverflow](https://stackoverflow.com/questions/11644300/access-denied-for-user-debian-sys-maint) will be helpful.
