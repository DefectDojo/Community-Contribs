#!/bin/bash --login
usage() {
  echo -e "USAGE: ${0} <\n\tlist_containers || \n\tstart postgres-redis*|postgres-rabbitmq|mysql-redis|mysql-rabbitmq || \n\tstop || \n\trestart postgres-redis*|postgres-rabbitmq|mysql-redis|mysql-rabbitmq || \n\tdeploy <docker hub username> || \n\tcontainer_logs celerybeat|celeryworker|nginx|uwsgi|mysql|rabbitmq|mailhog || \n\tbackup_db || \n\tupgrade || \n\tdestroy || \n\treset_password USERNAME || \n\tshell celerybeat|celeryworker|nginx|uwsgi|mysql|rabbitmq|mailhog\n>"
  exit 1
}

start() {
  dd_root="${1}"
  profile="${2}"
  if [[ $profile == '' ]]; then
    profile='mysql-rabbitmq'
  fi
  cd $dd_root && ./dc-up-d.sh $profile
}

stop() {
  dd_root="${1}"
  cd $dd_root && ./dc-stop.sh
}

restart() {
  dd_root="${1}"
  profile="${2}"
  stop $dd_root && start $dd_root $profile
}

backup_db() {
  mysql_container="${1}"
  backup_archive='/opt/defect_dojo_mysql_backups'
  backup_file="${backup_archive}/defectdojo_dump-$(date +%Y-%m-%d_%H-%M-%S).sql"
  if [[ ! -d $backup_archive ]]; then
    sudo mkdir $backup_archive
    sudo chown $USER:$USER $backup_archive
  fi
  echo 'Backing Up Database...'
  printf 'Enter password:'
  docker exec \
    -it $mysql_container \
    /bin/bash \
    -c 'mysqldump -u defectdojo -p defectdojo' > $backup_file
  echo -e "\nBackup written to ${backup_file}"
}

down_all_dd_containers_n_nuke_volumes() {
  dd_root="${1}"
  cd $dd_root && ./dc-down.sh --volumes
}

restore_db() {
  dd_root="${1}"
  down_all_dd_containers_n_nuke_volumes $dd_root
}

reset_password() {
  uwsgi_container="${1}"
  username="${2}"
  if [[ $username != '' ]]; then
    docker exec -it $uwsgi_container ./manage.py changepassword $username
  else
    usage
  fi
}

shell() {
  container="${1}"
  docker exec -u 0 -it $container /bin/sh
}

if (( $# >= 1 )); then
  action="${1}"
  dd_root='/opt/django-DefectDojo'

  celerybeat_container=$(docker ps | grep django | grep celerybeat | awk '{ print $(NF)}')
  celeryworker_container=$(docker ps | grep django | grep celeryworker | awk '{ print $(NF)}')
  nginx_container=$(docker ps | grep django | grep nginx | awk '{ print $(NF)}')
  uwsgi_container=$(docker ps | grep django | grep uwsgi | awk '{ print $(NF)}')
  mysql_container=$(docker ps | grep django | grep mysql | awk '{ print $(NF)}')
  rabbitmq_container=$(docker ps | grep django | grep rabbitmq | awk '{ print $(NF)}')
  mailhog_container=$(docker ps | grep django | grep mailhog | awk '{ print $(NF)}')
    
  case $action in
    'list_containers')
      docker ps -a | grep django-defectdojo | awk '{print $NF}';;
      
    'start')
      profile="${2}"
      start $dd_root $profile;;
    
    'stop') stop $dd_root;;
    
    'restart')
      profile="${2}"
      restart $dd_root $profile;;

    'reset_password')    
      username="${2}"
      reset_password $uwsgi_container $username;;

    'shell')
      choice="${2}"
      case $choice in
        'celerybeat'|'celeryworker'|'nginx'|'uwsgi'|'mysql'|'rabbitmq'|'mailhog')
          container=$(docker ps | grep django | grep ${choice} | awk '{ print $(NF)}')
          shell $container;;
        *) usage;;
      esac;;

    'deploy')    
      if (( $# == 2 )); then
        docker_hub_username="${2}"
        docker login --username $docker_hub_username

        if [[ ! -d $dd_root ]]; then
          cd /opt && sudo git clone https://github.com/DefectDojo/django-DefectDojo
          # Do this to avoid future git pull issues w/ $dd_root/Dockerfile.*
          cd $dd_root
          git checkout -b local_deployment
          sudo chown -R $USER:$USER $dd_root
        fi
        cd $dd_root
        git checkout dev && git pull
        cp dojo/settings/settings.py docker/extra_settings
        cp dojo/settings/settings.dist.py docker/extra_settings
        ./docker/setEnv.sh debug;
        ./dc-build.sh
        ./dc-up-d.sh
        uwsgi_container=$(docker ps | grep django | grep uwsgi | awk '{ print $(NF)}')
        docker exec -it $uwsgi_container ./manage.py changepassword admin
      else
        usage
      fi;;
    
    'container_logs')
      if (( $# == 2 )); then
        container_str="${2}"
        container_name=$(docker ps -a | grep django-defectdojo | grep ${container_str} | awk '{ print $(NF) }')
        echo "DOCKER CONTAINER => ${container_name} LOGS:"
        docker logs --tail 30 --follow $container_name
      else
        usage
      fi;;
      
    'backup_db') backup_db $mysql_container;;
      
    'upgrade')
      backup_db $mysql_container
      dockerfile='Dockerfile.django'
      local_dockerfile='Dockerfile.django.LOCAL'
      orig_dockerfile='Dockerfile.django.ORIG'
      cd $dd_root
      if [[ -f $dockerfile ]]; then
        mv $dockerfile $local_dockerfile
      fi
      git checkout dev && git reset --hard origin/dev && git pull
      git checkout local_deployment && git merge dev
      cp $dockerfile $orig_dockerfile
      cp $local_dockerfile $dockerfile
      # docker pull defectdojo/defectdojo-django:latest;
      # docker pull defectdojo/defectdojo-nginx:latest;
      ./dc-build.sh
      restart $dd_root
      docker exec -it $uwsgi_container /bin/bash -c 'python manage.py migrate';;
      
    'destroy')
      printf 'This will destroy all containers and _DATA VOLUMES_ for Defect Dojo...proceed? Y|N: '; read answer
      down_all_dd_containers_n_nuke_volumes $dd_root
      case $answer in
        'Y' | 'y')
          cd $dd_root && ./dc-down.sh --volumes
          if [[ -d $dd_root ]]; then
            cd /opt && rm -rf $dd_root
          fi;;
        *) echo "${0} destroy ABORTED.";;
      esac;;
    *) usage;;
  esac
else
  usage
fi
