#!/usr/bin/env bash
set -a
. /vagrant/.env
set +a

alias dc='docker-compose -f /vagrant/docker-compose.yml --project-directory /vagrant'

commands() {
  cat << EOF

OpenMBEE VM Custom Commands Help:

    clean_restart      - remove all containers and volumes and restart containers
    dc                 - function alias for docker-compose (alias for 'docker-compose -f /vagrant/docker-compose.yml')
    enter <container>  - shell into a running container (e.g., 'enter db' to enter the PostgreSQL container)
    initialize_db      - populate the PostgreSQL service with the necessary permissions and databases
    initialize_search  - populate the Elasticsearch service by uploading the MMS Mapping Template
    teardown           - remove all containers and volumes

EOF
}

enter() {
    dc exec "${1}" env TERM=xterm /bin/sh
}

clean_restart() {
    teardown
    dc up -d
    initialize_db
    initialize_search
    echo ">>> Use 'dc logs' to see the container output"
}

teardown() {
    dc stop
    dc kill
    dc rm -f -v
    docker system prune -f
    docker volume prune -f
    if [[ -f ${ES_MAPPING_TEMPLATE_FILE} ]]; then
        rm ${ES_MAPPING_TEMPLATE_FILE}
    fi
}

initialize_db() {
    if [[ ! `dc ps -q ${PG_SERVICE_NAME}` ]]; then
        echo "  > Waiting ${PG_WAIT} seconds for PostgreSQL service to start"
        sleep ${PG_WAIT}
    fi

    if [[ ! `dc exec ${PG_SERVICE_NAME} env PGPASSWORD=${PG_PASSWORD} psql -lq -U ${PG_USERNAME} | grep -q "List of databases"` ]]; then
        echo "  > Waiting ${PG_WAIT} seconds for PostgreSQL to begin accepting connections"
        sleep ${PG_WAIT}
    fi

    if [[ ! `dc exec db psql -U ${PG_USERNAME} -c ${PG_TEST_CREATEDB_ROLE_COMMAND} | grep -q "(1 row)"` ]]; then
        echo "  > Giving '${PG_USERNAME}' permission to create databases"
        dc exec ${PG_SERVICE_NAME} env PGPASSWORD=${PG_PASSWORD} psql -h ${PG_SERVICE_NAME} -p ${PG_PORT} -U ${PG_USERNAME} -c "ALTER ROLE ${PG_USERNAME} CREATEDB"
    fi

    if [[ ! `dc exec ${PG_SERVICE_NAME} psql -lqt -U ${PG_USERNAME} | cut -d \| -f 1 | grep -qw alfresco` ]]; then
        echo "  > Creating the Alfresco database ('alfresco')"
        dc exec ${PG_SERVICE_NAME} env PGPASSWORD=${PG_PASSWORD} createdb -h ${PG_SERVICE_NAME} -p ${PG_PORT} -U ${PG_USERNAME} alfresco
    fi

    if [[ ! `dc exec ${PG_SERVICE_NAME} psql -lqt -U ${PG_USERNAME} | cut -d \| -f 1 | grep -qw ${PG_DB_NAME}` ]]; then
        echo "  > Creating the MMS database ('${PG_DB_NAME}')"
        dc exec ${PG_SERVICE_NAME} env PGPASSWORD=${PG_PASSWORD} createdb -h ${PG_SERVICE_NAME} -p ${PG_PORT} -U ${PG_USERNAME} ${PG_DB_NAME}
    fi

    # Don't need to check because the command checks to see if the 'organizations' table exists before creating new ones
    dc exec ${PG_SERVICE_NAME} env PGPASSWORD=${PG_PASSWORD} psql -h ${PG_SERVICE_NAME} -p ${PG_PORT} -U ${PG_USERNAME} -d ${PG_DB_NAME} -c "${PG_DB_CREATION_COMMAND}"
}

initialize_search() {
    if [[ ! `dc ps -q ${ES_SERVICE_NAME}` ]]; then
        echo "  > Waiting ${ES_WAIT} seconds for Elasticsearch service to start"
        sleep ${ES_WAIT}
    fi

    if [[ ! -f ${ES_MAPPING_TEMPLATE_FILE} ]]; then
      echo "  > Could not find '${ES_MAPPING_TEMPLATE_FILE}'!"
      echo "  > Attempting to download the Elasticsearch Mapping File from the OpenMBEE MMS GitHub Repo"
      wget -O ${ES_MAPPING_TEMPLATE_FILE} ${ES_MAPPING_TEMPLATE_URL}
    fi

    ES_RESPONSE=`curl -XGET http://127.0.0.1:${ES_PORT}/_template/template`
    if [[ "${ES_RESPONSE:0:1}" != "{" ]]; then
        echo "  > Sleeping to make sure Elasticsearch is running"
        sleep ${ES_WAIT}
        ES_RESPONSE=`curl -XGET http://127.0.0.1:${ES_PORT}/_template/template`
    fi

    if [[ "${ES_RESPONSE}" == "{}" ]]; then
        echo " >> Uploading MMS Mapping Template File to Elasticsearch"
        curl -XPUT http://127.0.0.1:${ES_PORT}/_template/template -d @${ES_MAPPING_TEMPLATE_FILE}
        ES_RESPONSE=`curl -XGET http://127.0.0.1:${ES_PORT}/_template/template`
        if [[ "${ES_RESPONSE}" == "{}" ]]; then
            echo ""
            echo ">>> Failed to upload the MMS Template to Elasticsearch"
        fi
    fi
}
