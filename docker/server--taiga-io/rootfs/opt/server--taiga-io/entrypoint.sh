#!/bin/bash

set -euo pipefail

VAR_PID_RABBIT="0"
VAR_PID_SLEEP="0"

function adjust_log_directory_ownership() {
  echo " * Adjusting ownership for logs directory ..."
  sudo chown -R taiga:taiga "${DIRECTORY_LOGS}"
  echo " * Adjusting ownership for logs directory ... done"
}

function adjust_taiga_media_directory_ownership() {
  echo " * Adjusting ownership for taiga media directory ..."
  sudo chown -R taiga:taiga ${DIRECTORY_TAIGA_MEDIA}
  echo " * Adjusting ownership for taiga media directory ... done"
}

function import_default_taiga_database_directory() {
  echo " * Importing postgresql default configuration ..."
  sudo /bin/bash /opt/server--taiga-io/expose.sh "import" "${DIRECTORY_POSTGRESQL_DATA}"
  echo " * Importing postgresql default configuration ... done"
}

function import_taiga_media_directory() {
  echo " * Importing taiga media ..."
  sudo /bin/bash /opt/server--taiga-io/expose.sh "import" "${DIRECTORY_TAIGA_MEDIA}"
  echo " * Importing taiga media ... done"
}

function restart_postgresql_database() {
  echo " * Restarting postgresql database ..."
  sudo service postgresql restart > /dev/null
  /bin/bash /opt/server--taiga-io/wait-for-port.sh 5432
  echo " * Restarting postgresql database ... done"
}

function start_postgresql_database() {
  echo " * Starting postgresql database ..."
  sudo service postgresql start > /dev/null
  /bin/bash /opt/server--taiga-io/wait-for-port.sh 5432
  echo " * Starting postgresql database ... done"
}

function stop_postgresql_database() {
  echo " * Stopping postgresql database ..."
  sudo service postgresql stop > /dev/null
  echo " * Stopping postgresql database ... done"
}

function start_rabbitmq() {
  echo " * Starting rabbitmq ..."
  sudo rabbitmq-server                   \
        > ${HOME}/logs/rabbit.stdout.log \
       2> ${HOME}/logs/rabbit.stderr.log \
        & VAR_PID_RABBIT=${!}
  echo "  * Created process id ${VAR_PID_RABBIT}"
  /bin/bash /opt/server--taiga-io/wait-for-port.sh 5672
  echo " * Starting rabbitmq ... done"
}

function stop_rabbitmq() {
  echo " * Stopping rabbitmq ..."
  sudo kill -TERM ${VAR_PID_RABBIT}
  echo " * Stopping rabbitmq ... done"
}

function start_redis() {
  echo " * Starting redis ..."
  sudo service redis-server start > /dev/null
  echo " * Starting redis ... done"
}

function stop_redis() {
  echo " * Stopping redis ..."
  sudo service redis-server stop > /dev/null
  echo " * Stopping redis ... done"
}

function start_circusd() {
  echo " * Starting circusd ..."
  sudo service circusd start > /dev/null
  echo " * Starting circusd ... done"
}

function stop_circusd() {
  echo " * Stopping circusd ..."
  sudo service circusd stop > /dev/null
  echo " * Stopping circusd ... done"
}

function start_nginx() {
  echo " * Starting nginx ..."
  sudo service nginx start > /dev/null
  echo " * Starting nginx ... done"
}

function stop_nginx() {
  echo " * Stopping nginx ..."
  sudo service nginx stop > /dev/null
  echo " * Stopping nginx ... done"
}

function start_sleep_forever() {
  sleep infinity & \
  VAR_PID_SLEEP=${!}
}

function stop_sleep_forever() {
  sudo kill -TERM ${VAR_PID_SLEEP}
}

function create_taiga_database() {
  echo " * Creating taiga database ..."
  sudo --user postgres --login psql --command "CREATE USER taiga WITH SUPERUSER PASSWORD '${ENV_TAIGA_IO_SECRET_KEY_PSQL}';"
  sudo --user postgres --login createdb taiga -O taiga --encoding='utf-8' --locale=en_US.utf8 --template=template0
  echo " * Creating taiga database ... done"
}

function prepare_rabbitmq() {
  echo " * Preparing rabbitmq ..."
  if [ "$(sudo rabbitmqctl list_users | grep '^taiga\s')" = "" ]; then
    sudo rabbitmqctl add_user taiga ${ENV_TAIGA_IO_SECRET_KEY_EVENTS}
    sudo rabbitmqctl add_vhost taiga
    sudo rabbitmqctl set_permissions -p taiga taiga ".*" ".*" ".*"
    echo " * Preparing rabbitmq ... done"
  else
    echo " * Preparing rabbitmq ... skipped"
  fi
}

function wait_for_taiga_database() {
  echo " * Waiting for taiga database ..."
  /bin/bash /opt/server--taiga-io/wait-for-db.sh
  echo " * Waiting for taiga database ... done"
}

function initialize_taiga() {
  echo " * Initializing taiga ..."
  cd ${HOME}/taiga-back                                                     \
  && /bin/bash -c 'source /usr/share/virtualenvwrapper/virtualenvwrapper.sh \
  && workon taiga                                                           \
  && python manage.py migrate --noinput                                     \
  && python manage.py loaddata initial_user                                 \
  && python manage.py loaddata initial_project_templates                    \
  && python manage.py compilemessages                                       \
  && python manage.py collectstatic --noinput'
  echo " * Initializing taiga ... done"
}

function upgrade_taiga() {
  echo " * Upgrading taiga ..."
  cd ${HOME}/taiga-back                                                     \
  && /bin/bash -c 'source /usr/share/virtualenvwrapper/virtualenvwrapper.sh \
  && workon taiga                                                           \
  && python manage.py migrate --noinput                                     \
  && python manage.py compilemessages                                       \
  && python manage.py collectstatic --noinput                               \
  && python manage.py loaddata initial_project_templates'
  echo " * Upgrading taiga ... done"
}

function render_taiga_backend_configuration() {
  echo " * Rendering taiga backend configuration ..."
  sudo chown -R taiga:taiga ${DIRECTORY_TAIGA_BACK_CONF}
  if [ ! -f "${DIRECTORY_TAIGA_BACK_CONF}/local.py" ]; then
    sed -e "s/\${TAIGA_IO_URL}/${ENV_TAIGA_IO_URL}/g"                                \
        -e "s/\${TAIGA_IO_SCHEME}/${ENV_TAIGA_IO_SCHEME}/"                           \
        -e "s/\${TAIGA_IO_EMAIL}/${ENV_TAIGA_IO_EMAIL}/"                             \
        -e "s/\${TAIGA_IO_SECRET_KEY_API}/${ENV_TAIGA_IO_SECRET_KEY_API}/"           \
        -e "s/\${TAIGA_IO_SECRET_KEY_EVENTS}/${ENV_TAIGA_IO_SECRET_KEY_EVENTS}/"     \
        -e "s/\${TAIGA_IO_EMAIL_USE_TLS}/${ENV_TAIGA_IO_EMAIL_USE_TLS}/"             \
        -e "s/\${TAIGA_IO_EMAIL_HOST}/${ENV_TAIGA_IO_EMAIL_HOST}/"                   \
        -e "s/\${TAIGA_IO_EMAIL_HOST_USER}/${ENV_TAIGA_IO_EMAIL_HOST_USER}/"         \
        -e "s/\${TAIGA_IO_EMAIL_HOST_PASSWORD}/${ENV_TAIGA_IO_EMAIL_HOST_PASSWORD}/" \
        -e "s/\${TAIGA_IO_EMAIL_PORT}/${ENV_TAIGA_IO_EMAIL_PORT}/"                   \
        /templates/local.py > ${DIRECTORY_TAIGA_BACK_CONF}/local.py
    echo " * Rendering taiga backend configuration ... done"
  else
    echo " * Rendering taiga backend configuration ... skipped"
  fi
}

function render_taiga_events_configuration() {
  echo " * Rendering taiga events configuration ..."
  sudo chown -R taiga:taiga ${DIRECTORY_TAIGA_EVENTS_CONF}
  if [ ! -f "${DIRECTORY_TAIGA_EVENTS_CONF}/config.json" ]; then
    sed -e "s/\${TAIGA_IO_URL}/${ENV_TAIGA_IO_URL}/g"                                \
        -e "s/\${TAIGA_IO_SCHEME}/${ENV_TAIGA_IO_SCHEME}/"                           \
        -e "s/\${TAIGA_IO_EMAIL}/${ENV_TAIGA_IO_EMAIL}/"                             \
        -e "s/\${TAIGA_IO_SECRET_KEY_API}/${ENV_TAIGA_IO_SECRET_KEY_API}/"           \
        -e "s/\${TAIGA_IO_SECRET_KEY_EVENTS}/${ENV_TAIGA_IO_SECRET_KEY_EVENTS}/"     \
        -e "s/\${TAIGA_IO_EMAIL_USE_TLS}/${ENV_TAIGA_IO_EMAIL_USE_TLS}/"             \
        -e "s/\${TAIGA_IO_EMAIL_HOST}/${ENV_TAIGA_IO_EMAIL_HOST}/"                   \
        -e "s/\${TAIGA_IO_EMAIL_HOST_USER}/${ENV_TAIGA_IO_EMAIL_HOST_USER}/"         \
        -e "s/\${TAIGA_IO_EMAIL_HOST_PASSWORD}/${ENV_TAIGA_IO_EMAIL_HOST_PASSWORD}/" \
        -e "s/\${TAIGA_IO_EMAIL_PORT}/${ENV_TAIGA_IO_EMAIL_PORT}/"                   \
        /templates/events-conf.json > ${DIRECTORY_TAIGA_EVENTS_CONF}/config.json
    echo " * Rendering taiga events configuration ... done"
  else
    echo " * Rendering taiga events configuration ... skipped"
  fi
}

function render_taiga_frontend_configuration() {
  echo " * Rendering taiga frontend configuration ..."
  sudo chown -R taiga:taiga ${DIRECTORY_TAIGA_FRONT_CONF}
  if [ ! -f "${DIRECTORY_TAIGA_FRONT_CONF}/conf.json" ]; then
    sed -e "s/\${TAIGA_IO_URL}/${ENV_TAIGA_IO_URL}/g"                                \
        -e "s/\${TAIGA_IO_SCHEME}/${ENV_TAIGA_IO_SCHEME}/"                           \
        -e "s/\${TAIGA_IO_EMAIL}/${ENV_TAIGA_IO_EMAIL}/"                             \
        -e "s/\${TAIGA_IO_SECRET_KEY_API}/${ENV_TAIGA_IO_SECRET_KEY_API}/"           \
        -e "s/\${TAIGA_IO_SECRET_KEY_EVENTS}/${ENV_TAIGA_IO_SECRET_KEY_EVENTS}/"     \
        -e "s/\${TAIGA_IO_EMAIL_USE_TLS}/${ENV_TAIGA_IO_EMAIL_USE_TLS}/"             \
        -e "s/\${TAIGA_IO_EMAIL_HOST}/${ENV_TAIGA_IO_EMAIL_HOST}/"                   \
        -e "s/\${TAIGA_IO_EMAIL_HOST_USER}/${ENV_TAIGA_IO_EMAIL_HOST_USER}/"         \
        -e "s/\${TAIGA_IO_EMAIL_HOST_PASSWORD}/${ENV_TAIGA_IO_EMAIL_HOST_PASSWORD}/" \
        -e "s/\${TAIGA_IO_EMAIL_PORT}/${ENV_TAIGA_IO_EMAIL_PORT}/"                   \
        /templates/frontend-conf.json > ${DIRECTORY_TAIGA_FRONT_CONF}/conf.json
    echo " * Rendering taiga frontend configuration ... done"
  else
    echo " * Rendering taiga frontend configuration ... skipped"
  fi
}

function render_nginx_configuration() {
  echo " * Rendering nginx configuration ..."
  sudo chown -R taiga:taiga ${DIRECTORY_NGINX_CONF}
  if [ ! -f "${DIRECTORY_NGINX_CONF}/taiga.conf" ]; then
    sed -e "s/\${TAIGA_IO_URL}/${ENV_TAIGA_IO_URL}/g"                                \
        -e "s/\${TAIGA_IO_SCHEME}/${ENV_TAIGA_IO_SCHEME}/"                           \
        -e "s/\${TAIGA_IO_EMAIL}/${ENV_TAIGA_IO_EMAIL}/"                             \
        -e "s/\${TAIGA_IO_SECRET_KEY_API}/${ENV_TAIGA_IO_SECRET_KEY_API}/"           \
        -e "s/\${TAIGA_IO_SECRET_KEY_EVENTS}/${ENV_TAIGA_IO_SECRET_KEY_EVENTS}/"     \
        -e "s/\${TAIGA_IO_EMAIL_USE_TLS}/${ENV_TAIGA_IO_EMAIL_USE_TLS}/"             \
        -e "s/\${TAIGA_IO_EMAIL_HOST}/${ENV_TAIGA_IO_EMAIL_HOST}/"                   \
        -e "s/\${TAIGA_IO_EMAIL_HOST_USER}/${ENV_TAIGA_IO_EMAIL_HOST_USER}/"         \
        -e "s/\${TAIGA_IO_EMAIL_HOST_PASSWORD}/${ENV_TAIGA_IO_EMAIL_HOST_PASSWORD}/" \
        -e "s/\${TAIGA_IO_EMAIL_PORT}/${ENV_TAIGA_IO_EMAIL_PORT}/"                   \
        "/templates/nginx.conf" > "${DIRECTORY_NGINX_CONF}/taiga.conf"
    echo " * Rendering nginx configuration ... done"
  else
    echo " * Rendering nginx configuration ... skipped"
  fi
}

function apply_taiga_backend_configuration() {
  echo " * Applying taiga backend configuration ..."
  ln -fs ${DIRECTORY_TAIGA_BACK_CONF}/local.py ${HOME}/taiga-back/settings/local.py
  echo " * Applying taiga backend configuration ... done"
}

function apply_taiga_events_configuration() {
  echo " * Applying taiga events configuration ..."
  ln -fs ${DIRECTORY_TAIGA_EVENTS_CONF}/config.json ${HOME}/taiga-events/config.json
  echo " * Applying taiga events configuration ... done"
}

function apply_taiga_frontend_configuration() {
  echo " * Applying taiga frontend configuration ..."
  ln -fs ${DIRECTORY_TAIGA_FRONT_CONF}/conf.json ${HOME}/taiga-front-dist/dist/conf.json
  echo " * Applying taiga frontend configuration ... done"
}

function apply_nginx_configuration() {
  echo " * Applying nginx configuration ..."
  sudo ln -fs "${DIRECTORY_NGINX_CONF}/taiga.conf" /etc/nginx/conf.d/taiga.conf
  echo " * Applying nginx configuration ... done"
}

function handle_termination_signal() {
  echo " * Caugth for termination signal ..."
  echo "Stopping application taiga-io ..."
  stop_nginx
  stop_circusd
  stop_redis
  stop_rabbitmq
  stop_postgresql_database
  stop_sleep_forever
  echo " * Gracefully shut down all processes ..."
  echo "Stopping application taiga-io ... done"
  sleep 2
  exit 0
}

function generate() {
  echo "Preparing application taiga-io ..."
  adjust_log_directory_ownership
  import_taiga_media_directory
  adjust_taiga_media_directory_ownership
  import_default_taiga_database_directory
  start_postgresql_database
  create_taiga_database
  restart_postgresql_database
  wait_for_taiga_database
  initialize_taiga
  stop_postgresql_database
  render_taiga_backend_configuration
  render_taiga_events_configuration
  render_taiga_frontend_configuration
  render_nginx_configuration
  apply_taiga_backend_configuration
  apply_taiga_events_configuration
  apply_taiga_frontend_configuration
  apply_nginx_configuration
  echo "Preparing application taiga-io ... done"
}

function upgrade() {
  echo "Upgrading application taiga-io ..."
  adjust_log_directory_ownership
  adjust_taiga_media_directory_ownership
  apply_taiga_backend_configuration
  apply_taiga_events_configuration
  apply_taiga_frontend_configuration
  apply_nginx_configuration
  start_postgresql_database
  wait_for_taiga_database
  start_rabbitmq
  start_redis
  start_circusd
  upgrade_taiga
  stop_circusd
  stop_redis
  stop_rabbitmq
  stop_postgresql_database
  echo "Upgrading application taiga-io ... done"
}

function start() {
  echo "Starting application taiga-io ..."
  adjust_log_directory_ownership
  adjust_taiga_media_directory_ownership
  apply_taiga_backend_configuration
  apply_taiga_events_configuration
  apply_taiga_frontend_configuration
  apply_nginx_configuration
  start_postgresql_database
  wait_for_taiga_database
  start_rabbitmq
  prepare_rabbitmq
  start_redis
  start_circusd
  start_nginx
  start_sleep_forever
  echo "Starting application taiga-io ... done"

  echo " * Waiting for termination signal ..."
  trap handle_termination_signal SIGTERM

  wait ${VAR_PID_SLEEP}
}

VAR_OPTION="${1}"

case ${VAR_OPTION} in
  "version")
    echo "taiga-io version:"
    echo "  - taiga-back:       ${VERSION_TAIGA_BACK}"
    echo "  - taiga-front-dist: ${VERSION_TAIGA_FRONT}"
    ;;

  "generate")
    generate
    ;;

  "upgrade")
    upgrade
    ;;

  "start")
    start
    ;;
esac
