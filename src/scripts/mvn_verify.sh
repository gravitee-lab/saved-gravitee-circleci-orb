
export DESIRED_MAVEN_VERSION=${DESIRED_MAVEN_VERSION:-'3.6.3'}
export MVN_DOCKER="maven:${DESIRED_MAVEN_VERSION}-openjdk-16 "
export MAVEN_COMMAND="mvn clean verify"


Info() {
  echo "Running [$0] with maven version [${DESIRED_MAVEN_VERSION}] "
  echo "Will Run Maven Command MAVEN_COMMAND=[${MAVEN_COMMAND}]"
}

Info
docker run -it --rm -v "$PWD":/usr/src/mymaven -v "$HOME/.m2":/root/.m2 -w /usr/src/mymaven ${MVN_DOCKER} ${MAVEN_COMMAND}


# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
    Greet
fi
