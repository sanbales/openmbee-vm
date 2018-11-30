#!/usr/bin/env bash
DOCKER_COMPOSE_BASE_URL="https://github.com/docker/compose/releases/download"
DOCKER_COMPOSE_LOCATION=/usr/local/bin/docker-compose
DOCKER_COMPOSE_VERSION="1.23.2"

if ! (command -v docker); then
    echo ">>> Installing Docker"
    yum -y install docker
fi

if ! (grep -q -E "^docker:" /etc/group); then
    echo ">>> Creating a docker user group and adding vagrant user to it"
    groupadd docker
    usermod -aG docker vagrant
fi

if ! ( systemctl is-active --quiet docker ); then
  echo ">>> Starting docker daemon"
  sudo systemctl start docker
fi

if ! ( systemctl list-unit-files --state=enabled | grep -q -E "^docker.service" ); then
  echo ">>> Making sure docker daemon starts automatically"
  sudo systemctl enable docker
fi

if [[ ! -f ${DOCKER_COMPOSE_LOCATION} ]]; then
    echo ">>> Downloading docker-compose and making it executable"
    sudo curl -L "$DOCKER_COMPOSE_BASE_URL/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" \
              -o "$DOCKER_COMPOSE_LOCATION"
    sudo chmod +x "$DOCKER_COMPOSE_LOCATION"
fi

if [[ -z `docker ps -q --no-trunc | grep $(${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml ps -q alfresco)` ]]; then
  echo ">>> Starting containerized services"
  ${DOCKER_COMPOSE_LOCATION} -f /vagrant/docker-compose.yml up -d
fi
