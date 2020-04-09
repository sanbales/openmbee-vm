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
    ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec "${1}" env TERM=xterm /bin/sh
}

setup() {
    latest_mms_version=$(curl -s https://registry.hub.docker.com/v2/repositories/openmbee/mms/tags | python -c "import sys,json; print(json.load(sys.stdin)['results'][1]['name'])")
    echo ">>> Starting containerized services.  Installing latest MMS version: ${latest_mms_version}"
    ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant up -d

    echo ">>> Initializing the database service (PostgreSQL)"
    initialize_db

    echo ">>> Initializing the search service (Elasticsearch)"
    initialize_search
    echo ""

    #transfer the corrected files to the docker tomcat directories:
    #the .properties files change Alfresco to use the HTTP protocol instead of the HTTPS (the default); the tomcat-users files creates necessary admin user
    #after files are written, restart openmbee-mms container for changes to take effect
    echo ">>> copying correct MMS and Tomcat config files to vagrant vm..."
    docker cp /vagrant/alfresco-global.properties openmbee-mms:/usr/local/tomcat/shared/classes/alfresco-global.properties
    docker cp /vagrant/mms.properties openmbee-mms:/usr/local/tomcat/shared/classes/mms.properties
    docker cp /vagrant/tomcat-users.xml openmbee-mms:/usr/local/tomcat/conf/tomcat-users.xml
    docker restart openmbee-mms

    #coerce (again) Postgres to create the required `alfresco` and `mms` databases
    echo ">>> ensuring the necessary databases were created"
    initialize_db

    echo ">>> Installing View Editor files"
    echo "  > Getting latest View Editor files..."
    latest_ve_version=$(curl -s https://github.com/Open-MBEE/ve/releases/latest | grep -oP "tag/([0-9\.])+" | cut -d "/" -f 2)
    wget -q https://github.com/Open-MBEE/ve/releases/download/${latest_ve_version}/ve-${latest_ve_version}.zip
    yum -q -y install unzip
    unzip -qq ve-${latest_ve_version}.zip 
    mv dist ve\#\#${latest_ve_version}

    echo "  > Extracting and copying View Editor files over..."
    docker cp ve\#\#${latest_ve_version} openmbee-mms:/usr/local/tomcat/webapps/
    docker exec -i openmbee-mms sh -c "mkdir /usr/local/tomcat/webapps/ve##${latest_ve_version}/WEB-INF" 
    docker cp /vagrant/web.xml openmbee-mms:/usr/local/tomcat/webapps/ve\#\#${latest_ve_version}/WEB-INF/web.xml
    echo "  > View Editor installed."

    echo ">>> You can now use 'dc logs' to inspect the services"
}

teardown() {
    ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant stop
    ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant kill
    ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant rm -f -v
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
    if ! [[ `${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant ps -q ${PG_SERVICE_NAME}` ]]; then
        echo "  > Waiting ${PG_WAIT} seconds for PostgreSQL service to start"
        sleep ${PG_WAIT}
    fi

    # Check to see PostgreSQL service is running by requesting list of available databases
    if ! `${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} psql -lq -U ${PG_USERNAME} | grep -q "List of databases"`; then
        echo "  > Waiting ${PG_WAIT} seconds for PostgreSQL to begin accepting connections"
        sleep ${PG_WAIT}
    fi

    # Check to see if new user has ability to create databases
    if `${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} psql -U ${PG_USERNAME} -c "${PG_TEST_CREATEDB_ROLE_COMMAND}" | grep -q "(0 row)"`; then
        echo "  > Giving '${PG_USERNAME}' permission to create databases"
        ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} psql -U ${PG_USERNAME} -c "ALTER ROLE ${PG_USERNAME} CREATEDB"
    fi

    if ! `${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} psql -lqt -U ${PG_USERNAME} | cut -d \| -f 1 | grep -qw alfresco`; then
        echo "  > Creating the Alfresco database ('alfresco')"
        ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} createdb -U ${PG_USERNAME} alfresco
    fi

    if ! `${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} psql -lqt -U ${PG_USERNAME} | cut -d \| -f 1 | grep -qw ${PG_DB_NAME}`; then
        echo "  > Creating the MMS database ('${PG_DB_NAME}')"
        ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} createdb -U ${PG_USERNAME} ${PG_DB_NAME}
    fi

    if ! `${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} psql -U ${PG_USERNAME} -d ${PG_DB_NAME} -c "\dt" | grep -qw organizations`; then
        ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant exec -T ${PG_SERVICE_NAME} psql -U ${PG_USERNAME} -d ${PG_DB_NAME} -c "${PG_DB_CREATION_COMMAND}"
    fi
}

initialize_search() {
    if [[ ! `${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml --project-directory /vagrant ps -q ${ES_SERVICE_NAME}` ]]; then
        echo "  > Waiting ${ES_WAIT} seconds for Elasticsearch service to start"
        sleep ${ES_WAIT}
    fi

    if [[ ! -f ${ES_MAPPING_TEMPLATE_FILE} ]]; then
        echo "  > Could not find '${ES_MAPPING_TEMPLATE_FILE}'!"
        # echo "  > Attempting to download the Elasticsearch Mapping File from the OpenMBEE MMS GitHub Repo"
        # wget -O ${ES_MAPPING_TEMPLATE_FILE} ${ES_MAPPING_TEMPLATE_URL}
    fi

    # ES_RESPONSE=`curl -s -XGET http://127.0.0.1:${ES_PORT}/_template/template`
    # if [[ "${ES_RESPONSE:0:1}" != "{" ]]; then
    #     echo "  > Sleeping to make sure Elasticsearch is running"
    #     sleep ${ES_WAIT}

    #     echo "  > Re-requesting template from Elasticsearch"
    #     ES_RESPONSE=`curl -s -XGET http://127.0.0.1:${ES_PORT}/_template/template`
    # fi

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
