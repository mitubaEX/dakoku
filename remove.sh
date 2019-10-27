docker ps -a | grep dakoku | awk '{print $1}' | xargs docker rm -f
docker images | grep dakoku | awk '{print $1}' | xargs docker rmi -f
