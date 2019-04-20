#!/bin/bash

set -euo pipefail

function generate() {
  echo " * Adjusting permissions for logs directory"
  sudo chown -R taiga:taiga "${DIRECTORY_LOGS}"
  echo "   ...done."
  echo " * Importing taiga media"
  sudo /bin/bash /opt/server--taiga-io/expose.sh "import" "${DIRECTORY_TAIGA_MEDIA}"
  sudo chown -R taiga:taiga ${DIRECTORY_TAIGA_MEDIA}
  echo " * Importing postgresql default configuration"
  sudo /bin/bash /opt/server--taiga-io/expose.sh "import" "${DIRECTORY_POSTGRESQL_DATA}"
  echo " * Starting postgresql"
  sudo service postgresql start > /dev/null
  echo "   ...done."
  /bin/bash /opt/server--taiga-io/wait-for-port.sh 5432
  sudo --user postgres --login psql --command "CREATE USER taiga WITH SUPERUSER PASSWORD '${ENV_TAIGA_IO_SECRET_KEY_PSQL}';"
  sudo --user postgres --login createdb taiga -O taiga --encoding='utf-8' --locale=en_US.utf8 --template=template0
  echo " * Starting postgresql"
  sudo service postgresql restart > /dev/null
  echo "   ...done."
  /bin/bash /opt/server--taiga-io/wait-for-port.sh 5432
  /bin/bash /opt/server--taiga-io/wait-for-db.sh
  cd ${HOME}/taiga-back                                                                                                  \
  && /bin/bash -c 'source /usr/share/virtualenvwrapper/virtualenvwrapper.sh                                              \
  && workon taiga                                                                                                        \
  && python manage.py migrate --noinput                                                                                  \
  && python manage.py loaddata initial_user                                                                              \
  && python manage.py loaddata initial_project_templates                                                                 \
  && python manage.py compilemessages                                                                                    \
  && python manage.py collectstatic --noinput'
  echo " * Stopping postgresql"
  sudo service postgresql stop > /dev/null
  echo "   ...done."
  echo " * Rendering taiga backend configuration"
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
    echo "   ...done."
  else
    echo "   ...skipped."
  fi
  ln -fs ${DIRECTORY_TAIGA_BACK_CONF}/local.py ${HOME}/taiga-back/settings/local.py
  echo " * Rendering taiga events configuration"
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
    echo "   ...done."
  else
    echo "   ...skipped."
  fi
  ln -fs ${DIRECTORY_TAIGA_EVENTS_CONF}/config.json ${HOME}/taiga-events/config.json
  echo " * Rendering taiga frontend configuration"
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
    echo "   ...done."
  else
    echo "   ...skipped."
  fi
  ln -fs ${DIRECTORY_TAIGA_FRONT_CONF}/conf.json ${HOME}/taiga-front-dist/dist/conf.json
  echo " * Rendering nginx configuration"
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
    echo "   ...done."
  else
    echo "   ...skipped."
  fi
  sudo ln -fs "${DIRECTORY_NGINX_CONF}/taiga.conf" /etc/nginx/conf.d/taiga.conf
}

function start() {
  echo " * Adjusting permissions for logs directory"
  sudo chown -R taiga:taiga "${DIRECTORY_LOGS}"
  echo "   ...done."
  sudo chown -R taiga:taiga ${DIRECTORY_TAIGA_MEDIA}
  ln -fs ${DIRECTORY_TAIGA_BACK_CONF}/local.py ${HOME}/taiga-back/settings/local.py
  ln -fs ${DIRECTORY_TAIGA_EVENTS_CONF}/config.json ${HOME}/taiga-events/config.json
  ln -fs ${DIRECTORY_TAIGA_FRONT_CONF}/conf.json ${HOME}/taiga-front-dist/dist/conf.json
  sudo ln -fs "${DIRECTORY_NGINX_CONF}/taiga.conf"    "/etc/nginx/conf.d/taiga.conf"
  echo " * Starting postgresql"
  sudo service postgresql start > /dev/null
  echo "   ...done."
  /bin/bash /opt/server--taiga-io/wait-for-port.sh 5432
  /bin/bash /opt/server--taiga-io/wait-for-db.sh
  echo " * Starting rabbitmq"
  sudo rabbitmq-server                   \
        > ${HOME}/logs/rabbit.stdout.log \
      2> ${HOME}/logs/rabbit.stderr.log \
        & VAR_PID_RABBIT=${!}
  echo "   ...done (${VAR_PID_RABBIT})."
  /bin/bash /opt/server--taiga-io/wait-for-port.sh 5672
  if [ "$(sudo rabbitmqctl list_users | grep '^taiga\s')" = "" ]; then
    sudo rabbitmqctl add_user taiga ${ENV_TAIGA_IO_SECRET_KEY_EVENTS}
    sudo rabbitmqctl add_vhost taiga
    sudo rabbitmqctl set_permissions -p taiga taiga ".*" ".*" ".*"
  else
    echo "Creating user \"taiga\" ..."
    echo "   ...skipped."
  fi
  echo " * Starting redis"
  sudo service redis-server start > /dev/null
  echo "   ...done."
  echo " * Starting circusd"
  sudo service circusd start > /dev/null
  echo "   ...done."
  echo " * Starting nginx"
  sudo service nginx start > /dev/null
  echo "   ...done."
  echo ""
  echo "Successfully started all processes."
  trap 'set -euo pipefail;                                                                   \
        /bin/bash /opt/server--taiga-io/re-echo.sh "";                                       \
        /bin/bash /opt/server--taiga-io/re-echo.sh " * Stopping nginx";                      \
        sudo service nginx stop > /dev/null;                                                 \
        /bin/bash /opt/server--taiga-io/re-echo.sh "   ...done.";                            \
        /bin/bash /opt/server--taiga-io/re-echo.sh " * Stopping circusd";                    \
        sudo service circusd stop > /dev/null;                                               \
        /bin/bash /opt/server--taiga-io/re-echo.sh "   ...done.";                            \
        /bin/bash /opt/server--taiga-io/re-echo.sh " * Stopping redis";                      \
        sudo service redis-server stop > /dev/null;                                          \
        /bin/bash /opt/server--taiga-io/re-echo.sh "   ...done.";                            \
        /bin/bash /opt/server--taiga-io/re-echo.sh " * Stopping rabbitmq";                   \
        sudo kill -TERM ${VAR_PID_RABBIT};                                                   \
        /bin/bash /opt/server--taiga-io/re-echo.sh "   ...done.";                            \
        /bin/bash /opt/server--taiga-io/re-echo.sh " * Stopping postgresql";                 \
        sudo service postgresql stop > /dev/null;                                            \
        /bin/bash /opt/server--taiga-io/re-echo.sh "   ...done.";                            \
        /bin/bash /opt/server--taiga-io/re-echo.sh "";                                       \
        /bin/bash /opt/server--taiga-io/re-echo.sh ">> Gracefully shut down all processes."; \
        sleep 2                                                                              \
        exit 0'                                                                              \
      SIGTERM

  wait ${VAR_PID_RABBIT}
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
  
  "start")
    start
    ;;
esac