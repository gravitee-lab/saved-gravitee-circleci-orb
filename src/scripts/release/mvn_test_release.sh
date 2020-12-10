# There is no default value applied here : the
# default value should be defined by the Circle CI Orb Logic ONLY.
export DRY_RUN=${DRY_RUN}
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

# ---
# --- IN CONTAINER SECRETS
# ---
# +++ ++++++++++++++++ +++ #
# +++ The GPG Identity +++ #
# +++ ++++++++++++++++ +++ #
export OUTSIDE_CONTAINER_SECRETS_VOLUME=$(pwd)/graviteebot/.secrets/
mkdir -p ${OUTSIDE_CONTAINER_SECRETS_VOLUME}/.gungpg

export RESTORED_GPG_PUB_KEY_FILE="${OUTSIDE_CONTAINER_SECRETS_VOLUME}/.gungpg/graviteebot.gpg.pub.key"
export RESTORED_GPG_PRIVATE_KEY_FILE="${OUTSIDE_CONTAINER_SECRETS_VOLUME}/.gungpg/graviteebot.gpg.priv.key"

secrethub read --out-file ${RESTORED_GPG_PUB_KEY_FILE} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/gpg/pub_key"
secrethub read --out-file ${RESTORED_GPG_PRIVATE_KEY_FILE} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/gpg/private_key"

# ---
# The Signing key ID
export GRAVITEEBOT_GPG_SIGNING_KEY_ID=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/gpg/key_id")

# ---
# The GnuPG SNIPPET
cat <<EOF>>./.circleci/gpg.script.snippet.sh
echo "# --------------------- #"
# The [/home/$NON_ROOT_USER_NAME/.secrets] is engraved into the container image
export SECRETS_HOME=/home/$NON_ROOT_USER_NAME/.secrets
export RESTORED_GPG_PUB_KEY_FILE="\${SECRETS_HOME}/.gungpg/graviteebot.gpg.pub.key"
export RESTORED_GPG_PRIVATE_KEY_FILE="\${SECRETS_HOME}/.gungpg/graviteebot.gpg.priv.key"
echo "# --------------------- #"
echo "Content of [\\\${SECRETS_HOME}/.gungpg]=[\${SECRETS_HOME}/.gungpg] (are the keys there in the container ?)" :
ls -allh \${SECRETS_HOME}/.gungpg
echo "# --------------------- #"

export EPHEMERAL_KEYRING_FOLDER_ZERO=\$(mktemp -d)
chmod 700 \${EPHEMERAL_KEYRING_FOLDER_ZERO}
export GNUPGHOME=\${EPHEMERAL_KEYRING_FOLDER_ZERO}
echo "GPG Keys before import : "
gpg --list-keys

# ---
# Importing GPG KeyPair
gpg --batch --import \${RESTORED_GPG_PRIVATE_KEY_FILE}
gpg --import \${RESTORED_GPG_PUB_KEY_FILE}
echo "# --------------------- #"
echo "GPG Keys after import : "
gpg --list-keys
echo "# --------------------- #"
echo "  GPG version is :"
echo "# --------------------- #"
gpg --version
echo "# --------------------- #"

# ---
# now we trust ultimately the Public Key in the Ephemeral Context,
export GRAVITEEBOT_GPG_SIGNING_KEY_ID=${GRAVITEEBOT_GPG_SIGNING_KEY_ID}
echo "GRAVITEEBOT_GPG_SIGNING_KEY_ID=[\${GRAVITEEBOT_GPG_SIGNING_KEY_ID}]"

echo -e "5\\ny\\n" |  gpg --command-fd 0 --expert --edit-key \${GRAVITEEBOT_GPG_SIGNING_KEY_ID} trust

echo "# --------------------- #"
echo "# --- OK READY TO SIGN"
echo "# --------------------- #"
EOF

export GPG_SCRIPT_SNIPPET=$(cat ./.circleci/gpg.script.snippet.sh)
rm ./.circleci/gpg.script.snippet.sh

# ---
# +++ ++++++++++++++++ +++ #
# +++ The settings.xml +++ #
# +++ ++++++++++++++++ +++ #
# First, we need the [settings.xml] file containing the maven profiles secrets
if [ "${DRY_RUN}" == "0" ]; then
  echo "# --->>> NO IT IS NOT A DRY RUN"
  secrethub read --out-file ./settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.non.dry.run.xml"
else
  echo "# --->>> THIS IS A DRY RUN"
  secrethub read --out-file ./settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.xml"
fi;

echo " [--------------------------------------------------------------------------------] "
echo " [------  NOW HERE IS THE SETTINGS.XML PULL FROM SECRETHUB : "
echo " [--------------------------------------------------------------------------------] "
cat ./settings.xml
echo " [--------------------------------------------------------------------------------] "

Usage() {
  echo " [--------------------------------------------------------------------------------] "
  echo "    The [$0] script run the tests of the maven project to release "
  echo " [--------------------------------------------------------------------------------] "
  echo "    Usage :  "
  echo " [--------------------------------------------------------------------------------] "
  echo "        $0 "
  echo " [--------------------------------------------------------------------------------] "
  echo " Environment Variables : "
  echo " [--------------------------------------------------------------------------------] "
  echo "  SECRETHUB_ORG (Required) The name of the Secrethub Org from which Secrets have to be fetched"
  echo "  SECRETHUB_REPO (Required) The name of the Secrethub Repo from which Secrets have to be fetched"
  echo "  MAVEN_PROFILE_ID (Required) The ID of the maven profile touse to perfomr the dry run"
  echo " [--------------------------------------------------------------------------------] "
}

Info() {
  echo " [--------------------------------------------------------------------------------] "
  echo "   Running [$0] in dry run Mode ? [${DRY_RUN}] "
  echo "   Running [$0] with Secret Hub Org name [${SECRETHUB_ORG}] "
  echo "   Running [$0] with Secret Hub Repo name [${SECRETHUB_REPO}] "
  echo "   Running [$0] with maven profile of ID [${MAVEN_PROFILE_ID}] "
  echo "   Running [$0] with OCI IMAGE IMAGE_TAG_LABEL=[${IMAGE_TAG_LABEL}]"
  echo "   Running [$0] with OCI IMAGE GH_ORG_LABEL=[${GH_ORG_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_NAME_LABEL=[${NON_ROOT_USER_NAME_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_GRP_LABEL=[${NON_ROOT_USER_GRP_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_NAME_LABEL=[${NON_ROOT_USER_NAME_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_GRP_LABEL=[${NON_ROOT_USER_GRP_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_UID_LABEL=[${NON_ROOT_USER_UID_LABEL}]"
  echo "   Running [$0] with OCI IMAGE NON_ROOT_USER_GID_LABEL=[${NON_ROOT_USER_GID_LABEL}]"
  echo "   Running [$0] with Pipeline user name=[$(whoami)]"
  echo "   Running [$0] with Pipeline user uid CCI_USER_UID=[${CCI_USER_UID}]"
  echo "   Running [$0] with Pipeline user gid CCI_USER_GID=[${CCI_USER_GID}]"
  echo " [--------------------------------------------------------------------------------] "
}


# --- --- --- --- --- --- --- #
# ---   operational       --- #
# ---   functions         --- #
# --- --- --- --- --- --- --- #
# ---
#

runMavenCommand () {
  export MAVEN_COMMAND=$1
  echo "[runMavenCommand] - Will Run Maven Command [${MAVEN_COMMAND}]"
  # docker run -it --rm -v "$PWD":/usr/src/giomaven_project -v "$HOME/.m2":/root/.m2 -w /usr/src/giomaven_project ${MVN_DOCKER} ${MAVEN_COMMAND}
  docker run -it --rm --user ${CCI_USER_UID}:${CCI_USER_GID} -v "$PWD":/usr/src/giomaven_project -v "$HOME/.m2":/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2 -w /usr/src/giomaven_project ${MVN_DOCKER} ${MAVEN_COMMAND}
  # example running as non-root :
  # docker run -v ~/.m2:/var/maven/.m2 -ti --rm -u 1000 -e MAVEN_CONFIG=/var/maven/.m2 maven mvn -Duser.home=/var/maven archetype:generate

}
# ---
# -  Runs a script inside the maven docker container
# ---
# this function takes one argument, the name of a file :
# => which is a shell script to execute in the docker container
# => which is expected to be located in [$PWD], to be picked up by the docker volume
runMavenShellScript () {

  export MAVEN_SHELL_SCRIPT=$1
  echo "[runMavenShellScript] - Will Run Maven Shell Script [${MAVEN_SHELL_SCRIPT}]"
  echo "[runMavenShellScript] - Will Run Maven Shell Script with CCI_USER_UID=[${CCI_USER_UID}]"
  echo "[runMavenShellScript] - Will Run Maven Shell Script with CCI_USER_GID=[${CCI_USER_GID}]"
  echo "[runMavenShellScript] - Will Run Maven Shell Script with CCI_USER (whoami)=[$(whoami)]"
  # --- #
  # the ${MAVEN_SHELL_SCRIPT} shell script IS in the docker container, because of the docker volume to $PWD
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
  docker run -it --rm --user ${CCI_USER_UID}:${CCI_USER_GID} -v ${OUTSIDE_CONTAINER_SECRETS_VOLUME}:/home/$NON_ROOT_USER_NAME/.secrets -v "$PWD":/usr/src/giomaven_project -v "$HOME/.m2":/home/${NON_ROOT_USER_NAME_LABEL}/.m2 -e MAVEN_CONFIG=/home/${NON_ROOT_USER_NAME_LABEL}/.m2 -w /usr/src/giomaven_project "${MVN_DOCKER}" ${MAVEN_SHELL_SCRIPT}

  export DOCKER_EXIT_CODE="$?"
  echo "[runMavenShellScript] the exit code of the [${MAVEN_SHELL_SCRIPT}] script is [${DOCKER_EXIT_CODE}] "
  if ! [ "${DOCKER_EXIT_CODE}" == "0" ]; then
    echo "[runMavenShellScript] the exit code of the [${MAVEN_SHELL_SCRIPT}] script is [${DOCKER_EXIT_CODE}], so not zero "
    exit ${DOCKER_EXIT_CODE}
  fi;
}



# --- --- --- --- --- --- --- #
# ---   operations start  --- #
# --- --- --- --- --- --- --- #
# From notes at https://github.com/gravitee-io/release/issues/128#issuecomment-700120543
# ---


# export GIT_USER_NAME=${GIT_USER_NAME:-'Jean-Baptiste-Lasselle'}
if [ "x${MAVEN_PROFILE_ID}" == "x" ]; then
  echo "[$0] You did not set the [MAVEN_PROFILE_ID] env. var."
  Usage
  exit 1
fi;

Info


echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo "                            FOR TESTING THE MAVEN RELEASE  "
echo "                              THE [pom.xml] IS :  "
echo " [--------------------------------------------------------------------------------] "
cat ./pom.xml
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "

# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #
# -                        RUN THE PROJECT 's TEST SUITES                        - #
# -                        (TRIMMING '-SNAPSHOT' SUFFIX)                         - #
# -------------------------------------------------------------------------------- #
# -      Note : We Run the Tests with the [pom.xml] exactly as it is before      - #
# -                             running the release                              - #
# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #

cat <<EOF>>./.circleci/mvn.run.tests.sh
#!/bin/bash
mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B -U -P ${MAVEN_PROFILE_ID} clean test
export MVN_EXIT_CODE=\$?
echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B -U -P ${MAVEN_PROFILE_ID} clean test] maven command is [\${MVN_EXIT_CODE}] "
if ! [ "\${MVN_EXIT_CODE}" == "0" ]; then
  echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B -U -P ${MAVEN_PROFILE_ID} clean test] maven command is [\${MVN_EXIT_CODE}], so not zero "
  exit \${MVN_EXIT_CODE}
fi;
EOF

echo "Now running tests"
chmod +x ./.circleci/mvn.run.tests.sh
runMavenShellScript ./.circleci/mvn.run.tests.sh

echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo "                            END OF MAVEN TEST RELEASE  "
echo "                              THE [pom.xml] IS NOW :  "
echo " [--------------------------------------------------------------------------------] "
cat ./pom.xml
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
