docker system prune -f
docker stop mms-docker pgsql-docker es-docker
docker rm mms-docker pgsql-docker es-docker
docker volume prune -f
rm mapping_templat*.json
