source ../.env

# This is required by Elastic Search, otherwise it will crash, as described here:
# https://www.elastic.co/guide/en/elasticsearch/reference/current/vm-max-map-count.html
if [[ "$(sysctl -n vm.max_map_count)" -ne "$ES_MAX_MAP_COUNT" ]]; then
  echo ">>> Setting the maximum number of memory map areas a process may have to $(ES_MAX_MAP_COUNT)"
  sudo sysctl -w vm.max_map_count=${ES_MAX_MAP_COUNT}

  # Make vm.max_map_count setting permanent
  if [[ ! -f ${ES_SYSCTL_CONF_FILE} ]]; then
    echo "  > Making the MAX_MAP_COUNT setting for Elastic Search persistent"
    echo "vm.max_map_count=$ES_MAX_MAP_COUNT" | sudo tee -a ${ES_SYSCTL_CONF_FILE}
  fi
fi

if ! ( command -v docker ); then
  echo ">>> Installing Docker"
  yum install -y yum-utils device-mapper-persistent-data lvm2
  yum-config-manager --add-repo ${DOCKER_CE_REPO_URL}
  yum install -y docker-ce docker-ce-cli containerd.io
fi

if ! ( grep -q -E "^docker:" /etc/group ); then
  echo ">>> Creating a docker user group and adding vagrant user to it"
  groupadd docker
  usermod -aG docker vagrant
fi

if ! ( systemctl list-unit-files --state=enabled | grep -q -E "^docker.service" ); then
  echo ">>> Setting up docker daemon to start automatically"
  sudo systemctl enable docker
fi

if ! ( systemctl is-active --quiet docker ); then
  echo ">>> Starting docker daemon"
  sudo systemctl start docker
fi

echo ">>> Starting the PostgreSQL Container"
docker run -d --name ${PG_CONTAINER_NAME} \
              --publish=${PG_PORT}:${PG_PORT} \
              -e POSTGRES_USER=${PG_USERNAME} -e POSTGRES_PASSWORD=${PG_PASSWORD} \
              ${PG_IMAGE}

echo "  > Sleeping to make sure PostgreSQL is running"
sleep 5

echo " >> Allowing user '${PG_USERNAME}' to create databases"
docker exec -it ${PG_CONTAINER_NAME} \
                psql -h ${HOST_ADDR} -U ${PG_USERNAME} -c "ALTER ROLE ${PG_USERNAME} CREATEDB"

echo " >> Creating the Alfresco database"
docker exec -it ${PG_CONTAINER_NAME} \
                createdb -h ${HOST_ADDR} -U ${PG_USERNAME} alfresco

echo " >> Creating the MMS database"
docker exec -it ${PG_CONTAINER_NAME} \
                createdb -h ${HOST_ADDR} -U ${PG_USERNAME} ${PG_DB_NAME}

echo "  > Configuring the MMS database"
docker exec -it ${PG_CONTAINER_NAME} \
                psql -h ${HOST_ADDR} -U ${PG_USERNAME} -d ${PG_DB_NAME} -c "${PG_DB_CREATION_COMMAND}"

echo ">>> Starting the Elasticsearch Container"
docker run -d --name ${ES_CONTAINER_NAME} --publish=9200:9200 ${ES_IMAGE}

echo " >> Setting up MMS Template in Elasticsearch"
if [[ ! -f ${ES_MAPPING_TEMPLATE_FILE} ]]; then
  echo "  > Could not find '${ES_MAPPING_TEMPLATE_FILE}'!"
  echo "  > Attempting to download the Elasticsearch Mapping File from the OpenMBEE MMS GitHub Repo"
  wget -O ${ES_MAPPING_TEMPLATE_FILE} ${ES_MAPPING_TEMPLATE_URL}
fi

echo "  > Sleeping to make sure Elasticsearch is running"
sleep 10

echo " >> Uploading MMS Mapping Template File to Elasticsearch"
curl -XPUT http://${HOST_ADDR}:9200/_template/template -d @${ES_MAPPING_TEMPLATE_FILE}
echo "  > If this command failed, run the line below manually to upload the MMS template to Elasticsearch"
echo "    curl -XPUT http://${HOST_ADDR}:9200/_template/template -d @${ES_MAPPING_TEMPLATE_FILE}"

echo ">>> Starting the MMS Container"
docker run -d --name ${MMS_CONTAINER_NAME} \
              --mount source=${MMS_VOLUME_NAME},target=/mnt/alf_data \
              --publish=8080:8080 \
              -e APP_USER=${MMS_USERNAME} -e APP_PASS=${MMS_PASSWORD} \
              -e PG_HOST=${HOST_ADDR} -e PG_PORT=${PG_PORT} \
              -e PG_DB_NAME=${PG_DB_NAME} -e PG_DB_USER=${PG_USERNAME} -e PG_DB_PASS=${PG_PASSWORD} \
              -e ES_HOST=${HOST_ADDR} -e ES_PORT=${ES_PORT} \
              ${MMS_IMAGE}
