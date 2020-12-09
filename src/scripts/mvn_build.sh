# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# CI CD System OCI Container Library
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
export OCI_REPOSITORY_ORG=${OCI_REPOSITORY_ORG:-"quay.io/gravitee-lab"}
export OCI_REPOSITORY_NAME=${OCI_REPOSITORY_NAME:-"cicd-maven"}
export MAVEN_CONTAINER_IMAGE_TAG=${MAVEN_CONTAINER_IMAGE_TAG:-"stable-latest"}
export MVN_DOCKER="${OCI_REPOSITORY_ORG}/${OCI_REPOSITORY_NAME}:${MAVEN_CONTAINER_IMAGE_TAG}"

docker pull "${MVN_DOCKER}"

export IMAGE_TAG_LABEL=$(docker inspect --format '{{ index .Config.Labels "oci.image.tag"}}' "${MVN_DOCKER}")
export GH_ORG_LABEL=$(docker inspect --format '{{ index .Config.Labels "cicd.github.org"}}' "${MVN_DOCKER}")
export NON_ROOT_USER_NAME_LABEL=$(docker inspect --format '{{ index .Config.Labels "oci.image.nonroot.user.name"}}' "${MVN_DOCKER}")
export NON_ROOT_USER_GRP_LABEL=$(docker inspect --format '{{ index .Config.Labels "oci.image.nonroot.user.group"}}' "${MVN_DOCKER}")
export NON_ROOT_USER_UID_LABEL=$(docker inspect --format '{{ index .Config.Labels "oci.image.nonroot.user.uid"}}' "${MVN_DOCKER}")
export NON_ROOT_USER_GID_LABEL=$(docker inspect --format '{{ index .Config.Labels "oci.image.nonroot.user.gid"}}' "${MVN_DOCKER}")
export CCI_USER_UID=$(id -u)
export CCI_USER_GID=$(id -g)

echo " IMAGE_TAG_LABEL=[${IMAGE_TAG_LABEL}]"
echo " GH_ORG_LABEL=[${GH_ORG_LABEL}]"
echo " NON_ROOT_USER_NAME_LABEL=[${NON_ROOT_USER_NAME_LABEL}]"
echo " NON_ROOT_USER_GRP_LABEL=[${NON_ROOT_USER_GRP_LABEL}]"
echo " NON_ROOT_USER_UID_LABEL=[${NON_ROOT_USER_UID_LABEL}]"
echo " NON_ROOT_USER_GID_LABEL=[${NON_ROOT_USER_GID_LABEL}]"



export MAVEN_COMMAND="mvn clean package"


Info() {
  echo " [--------------------------------------------------------------------------------] "
  echo "   Running [$0] in dry run Mode ? [${DRY_RUN}] "
  echo "   Running [$0] with Secret Hub Org name [${SECRETHUB_ORG}] "
  echo "   Running [$0] with Secret Hub Repo name [${SECRETHUB_REPO}] "
  echo "   Running [$0] with maven profile of ID [${MAVEN_PROFILE_ID}] "
  echo "   Running [$0] with OCI IMAGE TAG [${IMAGE_TAG_LABEL}]"
  echo "   Running [$0] with OCI IMAGE GH_ORG =[${GH_ORG_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_NAME =[${NON_ROOT_USER_NAME_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_GRP =[${NON_ROOT_USER_GRP_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_NAME =[${NON_ROOT_USER_NAME_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_GRP =[${NON_ROOT_USER_GRP_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_UID =[${NON_ROOT_USER_UID_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_GID =[${NON_ROOT_USER_GID_LABEL}]"
  echo "   Running [$0] with Pipeline user name=[$(whoami)]"
  echo "   Running [$0] with Pipeline user uid CCI_USER_UID=[${CCI_USER_UID}]"
  echo "   Running [$0] with Pipeline user gid CCI_USER_GID=[${CCI_USER_GID}]"
  echo "   Running [$0] with Will Run Maven Command MAVEN_COMMAND=[${MAVEN_COMMAND}]"
  echo " [--------------------------------------------------------------------------------] "
}

Info

# docker run -it --rm -v "$PWD":/usr/src/mymaven -v "$HOME/.m2":/root/.m2 -w /usr/src/mymaven ${MVN_DOCKER} ${MAVEN_COMMAND}

if ! [ -d "$HOME/.m2" ]; then
  mkdir -p "$HOME/.m2"
  # https://github.com/moby/moby/issues/2259#issuecomment-26564115
  # From Jérôme Petazonni himself
  # chmod a+rw "$HOME/.m2"
  chown ${CCI_USER_UID}:${CCI_USER_GID} "$HOME/.m2"
fi;

echo "docker-compose installed version? "
docker-compose version
# https://circleci.com/developer/orbs/orb/circleci/docker#commands-install-docker-compose
docker run -it --rm --user ${CCI_USER_UID}:${CCI_USER_GID} -v "$PWD":/usr/src/giomaven_project -v "$HOME/.m2":/home/${NON_ROOT_USER_NAME_LABEL}/.m2 -e MAVEN_CONFIG=/home/${NON_ROOT_USER_NAME_LABEL}/.m2 -w /usr/src/giomaven_project "${MVN_DOCKER}"  ${MAVEN_COMMAND}

export DOCKER_EXIT_CODE="$?"
echo "[$0] the exit code of the [${MAVEN_COMMAND}] maven command is [${DOCKER_EXIT_CODE}] "
if ! [ "${DOCKER_EXIT_CODE}" == "0" ]; then
  echo "[$0] the exit code of the [${MAVEN_COMMAND}] maven command is [${DOCKER_EXIT_CODE}], so not zero "
  exit ${DOCKER_EXIT_CODE}
fi;
