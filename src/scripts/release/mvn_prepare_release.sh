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
secrethub read --out-file ./settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.xml"


Usage() {
  echo " [--------------------------------------------------------------------------------] "
  echo "    The [$0] script prepares the maven release: "
  echo "      => It resets the maven project's version in the [pom.xml], trimming "
  echo "         the '-SNAPSHOT' suffix "
  echo "      => It updates the the maven project's dependencies in the [pom.xml],          "
  echo "         to their latest versions in the reference maven repositories               "
  echo " [--------------------------------------------------------------------------------] "
  echo "    Usage :  "
  echo " [--------------------------------------------------------------------------------] "
  echo "        $0 "
  echo " [--------------------------------------------------------------------------------] "
  echo "    Environment Variables : "
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
  echo "   Running [$0] with Dry Run maven profile of ID [${MAVEN_PROFILE_ID}] "
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
  docker run -it --rm -v "$PWD":/usr/src/giomaven_project -v "$HOME/.m2":/root/.m2 -w /usr/src/giomaven_project ${MVN_DOCKER} ${MAVEN_COMMAND}
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




# ---
# The maven version plugin will edit the [pom.xml] to reset the maven project version.
# The purpose here, is to "get rid of the [-SNAPSHOT] suffix comming
# from the release.json"
# ---
# Example :
# --> the [pom.xml] has version [1.3.1-SNAPSHOT], so we run :
# mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -B versions:set -DnewVersion=1.3.1 -DgenerateBackupPoms=false
# ---
# To dothat, We need the version of the maven project. That's a few commands to run. So we need to run that as a script.
# --> So we create a shell script with the required commands, and then run the script with the [runMavenShellScript] function
# --> Note that Circle CI Orbs file inclusion works with only Onefile, that's why we HAVE to generate it "on the fly"
if [ -f ./.circleci/mvn.script.sh ]; then
  rm ./.circleci/mvn.script.sh
fi;

echo " [--------------------------------------------------------------------------------] "
echo "   CHECKING LINUX USER OUTSIDE MAVEN CONTAINER : whoami=[$(whoami)] id=[$(id)]"
echo " [--------------------------------------------------------------------------------] "

# ---
# PATCH 1.0.3 => Update dependencies BEFORE ANY OTHER MAVEN COMMAND, SO THAT
# THE OTHER MAVEN COMMAND WON'T FAIL BECAUSE OF A MISSING -SNAPSHOT DEPENENCY
# NOT PRESENT IN PRIVATE ARTIFACTORY
# ---
echo "# ---"
echo "# PATCH 1.0.3 => Update dependencies BEFORE ANY OTHER MAVEN COMMAND, SO THAT"
echo "# THE OTHER MAVEN COMMAND WON'T FAIL BECAUSE OF A MISSING -SNAPSHOT DEPENDENCY"
echo "# NOT PRESENT IN PRIVATE ARTIFACTORY"
echo "# ---"
echo "# ---"
echo "# NOW  CALCULATE THE MAVEN PROJECT VERISON WITH THE MAVEN EXEC PLUGIN WON'T FAIL BECAUSE OF A "
echo "# MISSING -SNAPSHOT DEPENDENCY IN ARTIFACTORY REFERENTIAL "
echo "# ---"
# the command to update dependencies
cat <<EOF>>./.circleci/mvn.script2.sh
mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B -U versions:update-properties -Dincludes=io.gravitee.*:* -DallowMajorUpdates=false -DallowMinorUpdates=false -DallowIncrementalUpdates=true -DgenerateBackupPoms=false
export MVN_EXIT_CODE=\$?
echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B -U versions:update-properties -Dincludes=io.gravitee.*:* -DallowMajorUpdates=false -DallowMinorUpdates=false -DallowIncrementalUpdates=true -DgenerateBackupPoms=false] maven command is [\${MVN_EXIT_CODE}] "
exit \${MVN_EXIT_CODE}
EOF

chmod +x ./.circleci/mvn.script2.sh

runMavenShellScript ./.circleci/mvn.script2.sh
# --- Can't calculate the maven project version before updating dependencies => patch 1.0.3
# If The maven project version, ends with '.0', then
# this is a maintainance release
# if [ "${MVN_PRJ_VERSION_PATCH}" == "0" ]; then
  # yes it is a maintainance version
  # runMavenShellScript ./.circleci/mvn.script2.sh
# else
  # no it is not a maintainance version
  # runMavenShellScript ./.circleci/mvn.script2.sh
# fi;



# ---
# NOW  CALCULATE THE MAVEN PROJECT VERISON WITH THE MAVEN EXEC PLUGIN WON'T FAIL BECAUSE OF A
# MISSING -SNAPSHOT DEPENDENCY IN ARTIFACTORY REFERENTIAL
# ---
echo "# ---"
echo "# NOW  CALCULATE THE MAVEN PROJECT VERISON WITH THE MAVEN EXEC PLUGIN WON'T FAIL BECAUSE OF A "
echo "# MISSING -SNAPSHOT DEPENDENCY IN ARTIFACTORY REFERENTIAL "
echo "# ---"
# --- model is [mvn_release_trim_snapshot.sh]
cat <<EOF>>./.circleci/mvn.script.sh
#!/bin/bash
# O./
echo " [--------------------------------------------------------------------------------] "
echo "   CHECKING LINUX USER IN MAVEN CONTAINER : whoami=[$(whoami)] id=[$(id)]"
echo " [--------------------------------------------------------------------------------] "
# 1./ Ok,so first, need to pick up the maven project version from [pom.xml], using the maven exec plugin
export MVN_PRJ_VERSION=\$(mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -Dexec.executable='echo' -Dexec.args='\${project.version}' --non-recursive exec:exec -q | tee -a ./maven.logs; echo "\$?" > maven.exit.code)
cat ./maven.logs
export MVN_EXIT_CODE=\$(cat maven.exit.code)
echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -Dexec.executable='echo' -Dexec.args='\\\${project.version}' --non-recursive exec:exec -q] maven command is [\${MVN_EXIT_CODE}] "
if ! [ "\${MVN_EXIT_CODE}" == "0" ]; then
  echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -Dexec.executable='echo' -Dexec.args='\\\${project.version}' --non-recursive exec:exec -q] maven command is [\${MVN_EXIT_CODE}], so not zero "
  rm maven.exit.code
  exit \${MVN_EXIT_CODE}
fi;
rm maven.exit.code
echo "Resolved Maven Project version : [\${MVN_PRJ_VERSION}]"
# But MVN_PRJ_VERSION has the '-SNAPSHOT' suffix, we need to strip it off, to pass that exact verion to maven version plugin
export MVN_PRJ_VERSION=\$(echo "\${MVN_PRJ_VERSION}" | awk -F '-SNAPSHOT' '{print \$1}')
echo "trimmed [-SNAPSHOT] suffix from Maven Project version : [\${MVN_PRJ_VERSION}]"
# So we can retrieve the project version out of container
echo "\${MVN_PRJ_VERSION}" > ./.circleci/gio.maven.project.release.version
# 2./ and then we can run the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=1.3.1 -DgenerateBackupPoms=false]
mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=\${MVN_PRJ_VERSION} -DgenerateBackupPoms=false
# 3./ Exit code
export MVN_EXIT_CODE=\$?
echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=\${MVN_PRJ_VERSION} -DgenerateBackupPoms=false] maven command is [\${MVN_EXIT_CODE}] "
exit \${MVN_EXIT_CODE}
EOF
# finally let's make it executable, before passing it to the [runMavenShellScript] function
chmod +x ./.circleci/mvn.script.sh
runMavenShellScript ./.circleci/mvn.script.sh



export MVN_PRJ_VERSION=$(cat ./.circleci/gio.maven.project.release.version)
export MVN_PRJ_VERSION_MAJOR=$(cat ./.circleci/gio.maven.project.release.version | awk -F '.' '{print $1}')
export MVN_PRJ_VERSION_MINOR=$(cat ./.circleci/gio.maven.project.release.version | awk -F '.' '{print $2}')
export MVN_PRJ_VERSION_PATCH=$(cat ./.circleci/gio.maven.project.release.version | awk -F '.' '{print $3}')

echo "MVN_PRJ_VERSION=[${MVN_PRJ_VERSION}]"
echo "MVN_PRJ_VERSION_PATCH=[${MVN_PRJ_VERSION_PATCH}]"




echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo "                         END OF MAVEN PREPARE RELEASE Usage :  "
echo "                              THE [pom.xml] IS NOW :  "
echo " [--------------------------------------------------------------------------------] "
cat ./pom.xml
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
