#!/usr/bin/env bash
set -a
. /vagrant/.env
set +a

alias dc='${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant'

commands() {
  cat << EOF

MMS VM Custom Commands Help:

    clean_restart      - remove all containers and volumes and restart containers
    dc                 - function alias for docker-compose (alias for 'docker-compose -f /vagrant/docker-compose.yml')
    enter <container>  - shell into a running container (e.g., 'enter db' to enter the PostgreSQL container)
    initialize_db      - populate the PostgreSQL service with the necessary permissions and databases
    initialize_search  - populate the Elasticsearch service by uploading the MMS Mapping Template
    setup              - start stopped services and (if necessary) initialize their data
    teardown           - remove all containers and volumes

EOF
}

enter() {
    dc exec "${1}" env TERM=xterm /bin/sh
}

setup() {
    echo ">>> Starting containerized services"
    dc up -d

    echo ">>> Initializing the database service (PostgreSQL)"
    initialize_db

    echo ">>> Initializing the search service (Elasticsearch)"
    initialize_search
    echo ""

    #transfer .alfresco-global.properties and mms.properies files to the docker tomcat directory:
    #these files change Alfresco to use the HTTP protocol instead of the HTTPS (the default)
    echo ">>> copy correct config files to vagrant vm..."
    docker exec -i openmbee-mms sh -c "cat > /usr/local/tomcat/shared/classes/alfresco-global.properties" < /vagrant/alfresco-global.properties
    docker exec -i openmbee-mms sh -c "cat > /usr/local/tomcat/shared/classes/mms.properties" < /vagrant/mms.properties
    docker exec -i openmbee-mms sh -c "cat > /usr/local/tomcat/conf/tomcat-users.xml" < /vagrant/tomcat-users.xml

    #coerce (again) Postgres to create the required `alfresco` and `mms` databases
    echo ">>> ensuring the necessary databases were created"
    initialize_db

    echo ">>> You can now use 'dc logs' to inspect the services"
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

clean_restart() {
    teardown
    setup
}

initialize_db() {
    if ! [[ `dc ps -q ${PG_SERVICE_NAME}` ]]; then
        echo "  > Waiting ${PG_WAIT} seconds for PostgreSQL service to start"
        sleep ${PG_WAIT}
    fi

    # Check to see PostgreSQL service is running by requesting list of available databases
    if ! `dc exec ${PG_SERVICE_NAME} psql -lq -U ${PG_USERNAME} | grep -q "List of databases"`; then
        echo "  > Waiting ${PG_WAIT} seconds for PostgreSQL to begin accepting connections"
        sleep ${PG_WAIT}
    fi

    # Check to see if new user has ability to create databases
    if `dc exec ${PG_SERVICE_NAME} psql -U ${PG_USERNAME} -c "${PG_TEST_CREATEDB_ROLE_COMMAND}" | grep -q "(0 row)"`; then
        echo "  > Giving '${PG_USERNAME}' permission to create databases"
        dc exec ${PG_SERVICE_NAME} psql -U ${PG_USERNAME} -c "ALTER ROLE ${PG_USERNAME} CREATEDB"
    fi

    if ! `dc exec ${PG_SERVICE_NAME} psql -lqt -U ${PG_USERNAME} | cut -d \| -f 1 | grep -qw alfresco`; then
        echo "  > Creating the Alfresco database ('alfresco')"
        dc exec ${PG_SERVICE_NAME} createdb -U ${PG_USERNAME} alfresco
    fi

    if ! `dc exec ${PG_SERVICE_NAME} psql -lqt -U ${PG_USERNAME} | cut -d \| -f 1 | grep -qw ${PG_DB_NAME}`; then
        echo "  > Creating the MMS database ('${PG_DB_NAME}')"
        dc exec ${PG_SERVICE_NAME} createdb -U ${PG_USERNAME} ${PG_DB_NAME}
    fi

    if ! `dc exec ${PG_SERVICE_NAME} psql -U ${PG_USERNAME} -d ${PG_DB_NAME} -c "\dt" | grep -qw organizations`; then
        dc exec ${PG_SERVICE_NAME} psql -U ${PG_USERNAME} -d ${PG_DB_NAME} -c "${PG_DB_CREATION_COMMAND}"
    fi
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

    ES_RESPONSE=`curl -s -XGET http://127.0.0.1:${ES_PORT}/_template/template`
    if [[ "${ES_RESPONSE:0:1}" != "{" ]]; then
        echo "  > Sleeping to make sure Elasticsearch is running"
        sleep ${ES_WAIT}

        echo "  > Re-requesting template from Elasticsearch"
        ES_RESPONSE=`curl -s -XGET http://127.0.0.1:${ES_PORT}/_template/template`
    fi

    if [[ "${ES_RESPONSE}" == "{}" ]]; then
        echo " >> Uploading MMS Mapping Template File to Elasticsearch"
        curl -XPUT http://127.0.0.1:${ES_PORT}/_template/template -d @${ES_MAPPING_TEMPLATE_FILE}

        ES_RESPONSE=`curl -s -XGET http://127.0.0.1:${ES_PORT}/_template/template`
        if [[ "${ES_RESPONSE}" == "{}" ]]; then
            echo ""
            echo ">>> Failed to upload the MMS Template to Elasticsearch"
        fi
    fi
}
