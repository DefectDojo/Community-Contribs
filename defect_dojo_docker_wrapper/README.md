# DefectDojo Docker Wrapper
This contains a wrapper shell script to easily execute various common tasks when interacting w/ the DefectDojo docker environment.

## Install
`sudo cp ./defect_dojo_docker_wrapper.sh /usr/local/bin`

## Usage
```
$ defect_dojo_docker_wrapper.sh 
USAGE: /usr/local/bin/defect_dojo_docker_wrapper.sh <
        list_containers || 
        start postgres-redis*|postgres-rabbitmq|mysql-redis|mysql-rabbitmq || 
        stop || 
        restart postgres-redis*|postgres-rabbitmq|mysql-redis|mysql-rabbitmq || 
        deploy <docker hub username> || 
        container_logs celerybeat|celeryworker|nginx|uwsgi|mysql|rabbitmq|mailhog || 
        backup_db || 
        upgrade || 
        destroy || 
        reset_password USERNAME || 
        shell celerybeat|celeryworker|nginx|uwsgi|mysql|rabbitmq|mailhog
```

## State
This should be considered somewaht alpha in terms of its capabilties.  In terms of using this to start / stop / restart containers, view / tail logs, drop into containers for shells, and upgrading it's pretty helpful.
