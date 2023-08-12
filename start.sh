#!/bin/bash
#=================================================================================================
#
# Load docker image with war file
#
#=================================================================================================
# exit script on any error
trap 'docker network disconnect supercharge-net supercharge-db;docker network rm supercharge-net;' ERR

IMAGE_VERSION="1.0"
IMAGE_NAME="supercharge-api"
IMAGE_TAG="${IMAGE_NAME}:${IMAGE_VERSION}"
CONTAINER_NAME="supercharge-api"

SCRIPT_DIR=`dirname $0`;
NET_NAME="supercharge-net"
DB_NAME="supercharge-db"
DB_HOST="$DB_NAME:5432"
CONN=false

#
# Network setup
#
RESP=`docker network ls`
if [[ $RESP != *$NET_NAME* ]]; then
    CONN=true
    docker network create $NET_NAME
fi

LIST=`docker ps`
if ! [[ $LIST =~ $DB_NAME($'\n'|$) ]]; then
    CONN=true
    echo "Starting $DB_NAME..."
    RESP=`docker start $DB_NAME`

    if [[ $RESP == *"No such container"* ]]; then
        echo $RESP
        echo "Please create container from database folder first"
        exit
    fi
fi

if [ "$CONN" = true ]; then
    docker network connect $NET_NAME $DB_NAME
fi


#
# Build image
#
docker build --tag $IMAGE_TAG "$SCRIPT_DIR/"

if [[ $LIST =~ $CONTAINER_NAME($'\n'|$) ]]; then
    docker network disconnect $NET_NAME $CONTAINER_NAME 2> /dev/null
    docker stop $CONTAINER_NAME
fi

#
# Create and start the container
#
docker run --name $CONTAINER_NAME \
           --detach \
           --env "JAVA_OPTS=-Ddb.url=jdbc:postgresql://$DB_HOST/postgres -Dspring.profiles.active=development" \
           --env "JPDA_ADDRESS=*:8000" \
           --rm \
           --network $NET_NAME \
           --publish 8080:8080 \
           --publish 127.0.0.1:8000:8000 \
           "$IMAGE_TAG"
