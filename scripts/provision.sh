#!/usr/bin/env bash
source /vagrant/.env


if [[ ! -f ${CUSTOM_PROFILE_FILENAME} ]]; then
    echo ">>> Adding the aliases to /etc/profile, making it persistent"
    echo "set -a" > /etc/profile.d/${CUSTOM_PROFILE_FILENAME}
    echo "source /vagrant/scripts/.bashrc" >> /etc/profile.d/${CUSTOM_PROFILE_FILENAME}
fi


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
  yum install -y   yum-utils   device-mapper-persistent-data   lvm2
  yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
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


if [[ ! -f ${DOCKER_COMPOSE_LOCATION} ]]; then
    echo ">>> Downloading docker-compose and making it executable"
    sudo curl -L "$DOCKER_COMPOSE_BASE_URL/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
              -o "$DOCKER_COMPOSE_LOCATION"
    sudo chmod +x "$DOCKER_COMPOSE_LOCATION"
fi


if [[ -z `docker ps -q --no-trunc | grep $(${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml ps -q mms)` ]]; then
  echo ">>> Starting containerized services"
  ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml up -d
fi
