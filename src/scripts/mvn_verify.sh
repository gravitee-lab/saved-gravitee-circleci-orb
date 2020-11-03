
export DESIRED_MAVEN_VERSION=${DESIRED_MAVEN_VERSION:-'3.6.3'}
export MVN_DOCKER="maven:${DESIRED_MAVEN_VERSION}-openjdk-11 "
export MAVEN_COMMAND="mvn clean verify"


Info() {
  echo "Running [$0] with maven version [${DESIRED_MAVEN_VERSION}] "
  echo "Will Run Maven Command MAVEN_COMMAND=[${MAVEN_COMMAND}]"
}

Info
docker run -it --rm -v "$PWD":/usr/src/mymaven -v "$HOME/.m2":/root/.m2 -w /usr/src/mymaven ${MVN_DOCKER} ${MAVEN_COMMAND}
