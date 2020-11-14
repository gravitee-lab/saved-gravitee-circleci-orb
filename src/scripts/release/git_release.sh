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
  echo "    The [$0] script runs the git release of a maven project which was "
  echo "    successfully maven relased to the maven repositories "
  echo "      => It creates the git maintenance branch for the next release, if it          "
  echo "         does not already exists"
  echo "      => It \"prepares\" the [pom.xml] for the next maven release: "
  echo "         ++ if this is a minor release, it increments the minor version on "
  echo "            master branch, and patch version on the maintenance branch "
  echo "         ++ if this is a patch (maintenance) release, it increments the patch       "
  echo "            version on the maintenance branch"
  echo "         ++ It adds (back) the '-SNAPSHOT' suffix on the maintenance "
  echo "            branch for any release "
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
  echo "  MVN_PRJ_VERSION (Required) The version of the maven project,according [pom.xml].It should not contains the '-SNAPSHOT' suffix, because the mavenproject is supposedly just released"
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
# This script performs the git release of a maven project which has already successfully been maven released
# To do that, we need the version of the maven project.
if [ -f ./.circleci/mvn.project.version.sh ]; then
  rm ./.circleci/mvn.project.version.sh
fi;
# --- model is [mvn_release_trim_snapshot.sh]
cat <<EOF>>./.circleci/mvn.project.version.sh
#!/bin/bash
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
# So we can retrieve the project version out of container
echo "\${MVN_PRJ_VERSION}" > ./.circleci/gio.maven.project.version
EOF
# finally let's make it executable, before passing it to the [runMavenShellScript] function
chmod +x ./.circleci/mvn.project.version.sh
runMavenShellScript ./.circleci/mvn.project.version.sh


export MVN_PRJ_VERSION=$(cat ./.circleci/gio.maven.project.version)
export MVN_PRJ_VERSION_MAJOR=$(echo "${MVN_PRJ_VERSION}" | awk -F '.' '{print $1}')
export MVN_PRJ_VERSION_MINOR=$(echo "${MVN_PRJ_VERSION}" | awk -F '.' '{print $2}')
export MVN_PRJ_VERSION_PATCH=$(echo "${MVN_PRJ_VERSION}" | awk -F '.' '{print $3}')

echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo "                            FOR THE GIT RELEASE  "
echo "                              THE [pom.xml] IS :  "
echo " [--------------------------------------------------------------------------------] "
cat ./pom.xml
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo "      MVN_PRJ_VERSION=[${MVN_PRJ_VERSION}]"
echo "      MVN_PRJ_VERSION_MAJOR=[${MVN_PRJ_VERSION_MAJOR}]"
echo "      MVN_PRJ_VERSION_MINOR=[${MVN_PRJ_VERSION_MINOR}]"
echo "      MVN_PRJ_VERSION_PATCH=[${MVN_PRJ_VERSION_PATCH}]"
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "
echo " [--------------------------------------------------------------------------------] "




# the GIT_COMMIT env. var. will be picked up by maven
export GIT_COMMIT=$(git rev-parse HEAD)

# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #
# -                        GIT CONFIG FOR THE GRAVITEE BOT                       - #
# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #

if [ "x${SECRETHUB_ORG}" == "x" ]; then
  echo "[$0 - setupSSHGithubUser] You did not set the [SECRETHUB_ORG] env. var."
  Usage
  exit 1
fi;
if [ "x${SECRETHUB_REPO}" == "x" ]; then
  echo "[$0 - setupSSHGithubUser] You did not set the [SECRETHUB_REPO] env. var."
  Usage
  exit 1
fi;
echo "[$0 - setupSSHGithubUser] [SECRETHUB_ORG=[${SECRETHUB_ORG}]] "
echo "[$0 - setupSSHGithubUser] [SECRETHUB_REPO=[${SECRETHUB_REPO}]] "

export GIT_USER_NAME=$(secrethub read ${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/git/user/name)
export GIT_USER_EMAIL=$(secrethub read ${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/git/user/email)
export LOCAL_SSH_PUBKEY="${HOME}/.ssh.gravitee.io/id_rsa.pub"
export LOCAL_SSH_PRVIKEY="${HOME}/.ssh.gravitee.io/id_rsa"
export GIT_SSH_COMMAND='ssh -i ~/.ssh.gravitee.io/id_rsa'
mkdir -p "${HOME}/.ssh.gravitee.io/"
secrethub read --out-file ${LOCAL_SSH_PUBKEY} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/git/ssh/public_key"
secrethub read --out-file ${LOCAL_SSH_PRVIKEY} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/git/ssh/private_key"
chmod 700 "${HOME}/.ssh.gravitee.io/"
chmod 644 "${LOCAL_SSH_PUBKEY}"
chmod 600 "${LOCAL_SSH_PRVIKEY}"

echo "[$0 - setupSSHGithubUser] [GIT_USER_NAME=[${GIT_USER_NAME}]] "
echo "[$0 - setupSSHGithubUser] [GIT_USER_EMAIL=[${GIT_USER_EMAIL}]] "
echo "[$0 - setupSSHGithubUser] [GIT_SSH_COMMAND=[${GIT_SSH_COMMAND}]] "

# export GIT_USER_NAME=${GIT_USER_NAME:-'Jean-Baptiste-Lasselle'}
if [ "x${GIT_USER_NAME}" == "x" ]; then
  echo "[$0 - setupSSHGithubUser] You did not set the [GIT_USER_NAME] env. var."
  Usage
  exit 1
fi;
# export GIT_USER_EMAIL=${GIT_USER_EMAIL:-'jean.baptiste.lasselle.pegasus@gmail.com'}
if [ "x${GIT_USER_EMAIL}" == "x" ]; then
  echo "[$0 - setupSSHGithubUser] The [GIT_USER_EMAIL] env. var. was not properly set from secret manager"
  Usage
  exit 1
fi;
if [ "x${GIT_USER_SIGNING_KEY}" == "x" ]; then
  echo "[$0 - setupSSHGithubUser] the [GIT_USER_SIGNING_KEY] env. var. was not set, So [${GIT_USER_NAME}]] won't be signed"
  git config --global commit.gpgsign false
else
  echo "[$0 - setupSSHGithubUser] [${GIT_USER_NAME}] commits will be signed with signature [${GIT_USER_SIGNING_KEY}]"
  git config --global commit.gpgsign true
  git config --global user.signingkey ${GIT_USER_SIGNING_KEY}
fi;

echo "[$0 - setupSSHGithubUser] skipped almost everything else, and stripped out function "
# export SSH_PRIVATE_KEY=$(echo "$GIT_SSH_COMMAND" | awk '{print $3}' | sed "s#~#${HOME}#g")
git config --global user.name "${GIT_USER_NAME}"
git config --global user.email "${GIT_USER_EMAIL}"
# git config --global --list
echo "[$0 - setupSSHGithubUser] completed "

# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #
# -                       LAST GIT AND MAVEN COMMANDS :                          - #
# -                       GIT TAG RELEASE                                        - #
# -                       GIT AND MAVEN PREPARE NEXT VERSION                     - #
# -------------------------------------------------------------------------------- #
# -------------------------------------------------------------------------------- #


export CURRENT_GIT_BRANCH=$(git status | grep 'On branch' | awk '{print $3}')
echo "# -------------------------------------------------------------------------------- #"
echo "# ---- GIT TAG RELEASE  "
echo "# ---- CURRENT_GIT_BRANCH=[${CURRENT_GIT_BRANCH}]  "
echo "# ---- TAG WILL BE (Resolved from pom.xml) = [${MVN_PRJ_VERSION}]  "
echo "# -------------------------------------------------------------------------------- #"
# // commit, tag the release
# https://github.com/gravitee-io/jenkins-scripts/blob/master/src/main/groovy/releasemaven.groovy#L64
git add --update
git commit -m "${MVN_PRJ_VERSION}"
git tag ${MVN_PRJ_VERSION}
# //create the maintenance branch if needed
# I'll create the maintenance git branch iff it does not already exist
# export MVN_PRJ_VERSION_MAJOR=$(cat ./.circleci/gio.maven.project.version | awk -F '.' '{print $1}')
# export MVN_PRJ_VERSION_MINOR=$(cat ./.circleci/gio.maven.project.version | awk -F '.' '{print $2}')
# export MVN_PRJ_VERSION_PATCH=$(cat ./.circleci/gio.maven.project.version | awk -F '.' '{print $3}')

# export MVN_PRJ_VERSION_MAJOR="1"
# export MVN_PRJ_VERSION_MINOR="6"
# export MVN_PRJ_VERSION_PATCH="5"

# same as ${c.version.getNextBranchName()}
export MAINTENANCE_GIT_BRANCH="${MVN_PRJ_VERSION_MAJOR}.${MVN_PRJ_VERSION_MINOR}.x"
# same as c.version.nextFixSnapshotVersion()
export NEXT_PATCH_VERSION=$((${MVN_PRJ_VERSION_PATCH}+1))
export NEXT_PATCH_SNAPSHOT_VERSION="${MVN_PRJ_VERSION_MAJOR}.${MVN_PRJ_VERSION_MINOR}.${NEXT_PATCH_VERSION}-SNAPSHOT"

export GIT_BRANCH_FILTER=$(git branch -a | grep "${MAINTENANCE_GIT_BRANCH}")

echo "# -------------------------------------------------------------------------------- #"
echo "# ---- CREATE MAINTENANCE GIT BRANCH IF IT DOES NOT EXISTS  "
echo "# ----   "
echo "# ---- (On MAINTENANCE GIT BRANCH we prepare next patch version, regardless of      "
echo "# ---- whether the release is a maintenance release, or a   "
echo "# ---- minor release, with new features )  "
echo "# -------------------------------------------------------------------------------- #"
if [ "x${GIT_BRANCH_FILTER}" == "x" ]; then
  echo "# ---- git Maintenance branch [${MAINTENANCE_GIT_BRANCH}] does not exist, creating it"
  git checkout -b ${MAINTENANCE_GIT_BRANCH}
  echo "# -------------------------------------------------------------------------------- #"
  echo "# ---- PREPARE NEXT VERSION ON [MAINTENANCE_GIT_BRANCH]  "
  echo "# ---- resetting version in [pom.xml] to [${NEXT_PATCH_SNAPSHOT_VERSION}]"

# ---
# the maven command to prepare next version
cat <<EOF>>./.circleci/mvn.script5.sh
mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=${NEXT_PATCH_SNAPSHOT_VERSION} -DgenerateBackupPoms=false
export MVN_EXIT_CODE=\$?
echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=${NEXT_PATCH_SNAPSHOT_VERSION} -DgenerateBackupPoms=false] maven command is [\${MVN_EXIT_CODE}] "
exit \${MVN_EXIT_CODE}
EOF

  chmod +x ./.circleci/mvn.script5.sh
  runMavenShellScript ./.circleci/mvn.script5.sh


  git add --update
  git commit -m 'chore(): Prepare next version'
  echo "# ---- NOW WE HAVE A NEW VERSION IN [POM.XML], on MAINTENANCE_GIT_BRANCH=[${MAINTENANCE_GIT_BRANCH}]"
  echo "# ---- "
  echo "# ---- here is the full content of the [pom.xml] on MAINTENANCE_GIT_BRANCH=[${MAINTENANCE_GIT_BRANCH}] : "
  echo "# -------------------------------------------------------------------------------- #"
  cat ./pom.xml
  echo "# -------------------------------------------------------------------------------- #"

  if [ "${DRY_RUN}" == "0" ]; then
    # --->>> NO IT IS NOT A DRY RUN
    git push --tags origin ${MAINTENANCE_GIT_BRANCH}
  fi;
  git checkout ${CURRENT_GIT_BRANCH}
else
  echo "git Maintenance branch [${MAINTENANCE_GIT_BRANCH}] does exist, no need to create it, also CURRENT_GIT_BRANCH=[${CURRENT_GIT_BRANCH}] and MAINTENANCE_GIT_BRANCH=[${MAINTENANCE_GIT_BRANCH}] are supposed to be equal."
fi;

echo "# -------------------------------------------------------------------------------- #"
echo "# ---- PREPARE NEXT VERSION ON MASTER or MAINTENANCE BRANCH  "
echo "# ---- "
echo "# ---- CURRENT_GIT_BRANCH=[${CURRENT_GIT_BRANCH}]  "
echo "# ---- MAINTENANCE_GIT_BRANCH=[${MAINTENANCE_GIT_BRANCH}]"
echo "# ---- If this is a maintainance release, CURRENT_GIT_BRANCH and MAINTENANCE_GIT_BRANCH are supposed to be equal)."
echo "# ---- If this is a minor release, CURRENT_GIT_BRANCH and MAINTENANCE_GIT_BRANCH are supposed to be different)."
echo "# -------------------------------------------------------------------------------- #"

export NEXT_MINOR_VERSION=$((${MVN_PRJ_VERSION_MINOR}+1))
export NEXT_SNAPSHOT_VERSION="${MVN_PRJ_VERSION_MAJOR}.${NEXT_MINOR_VERSION}.${MVN_PRJ_VERSION_PATCH}-SNAPSHOT"

if [ "${MVN_PRJ_VERSION_PATCH}" == "0" ]; then
  echo "# ---- [${MVN_PRJ_VERSION}] is not a maintenance release, so we increment MINOR VERSION from [${MVN_PRJ_VERSION_MINOR}] to [${NEXT_MINOR_VERSION}], and prepared next version will be [${NEXT_SNAPSHOT_VERSION}] "

# ---
cat <<EOF>>./.circleci/mvn.script6.sh
mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=${NEXT_SNAPSHOT_VERSION} -DgenerateBackupPoms=false
export MVN_EXIT_CODE=\$?
echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=${NEXT_SNAPSHOT_VERSION} -DgenerateBackupPoms=false] maven command is [\${MVN_EXIT_CODE}] "
exit \${MVN_EXIT_CODE}
EOF

  chmod +x ./.circleci/mvn.script6.sh
  runMavenShellScript ./.circleci/mvn.script6.sh


else
  echo "# ---- [${MVN_PRJ_VERSION}] is a maintenance release, so we increment PATCH VERSION from [${MVN_PRJ_VERSION_PATCH}] to [${NEXT_PATCH_VERSION}], and prepared next version will be [${NEXT_PATCH_SNAPSHOT_VERSION}] "
  echo "resetting version in [pom.xml] to [${NEXT_PATCH_SNAPSHOT_VERSION}]"

# ---
cat <<EOF>>./.circleci/mvn.script7.sh
mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=${NEXT_PATCH_SNAPSHOT_VERSION} -DgenerateBackupPoms=false
export MVN_EXIT_CODE=\$?
echo "[\$0] The exit code of the [mvn -Duser.home=/home/${NON_ROOT_USER_NAME_LABEL}/ -s ./settings.xml -B versions:set -DnewVersion=${NEXT_PATCH_SNAPSHOT_VERSION} -DgenerateBackupPoms=false] maven command is [\${MVN_EXIT_CODE}] "
exit \${MVN_EXIT_CODE}
EOF

  chmod +x ./.circleci/mvn.script7.sh
  runMavenShellScript ./.circleci/mvn.script7.sh


fi;

echo "# -------------------------------------------------------------------------------- #"
echo "# ---- NOW WE HAVE A NEW VERSION IN [POM.XML], on CURRENT_GIT_BRANCH=[${CURRENT_GIT_BRANCH}]"
echo "# ---- "
echo "# ---- here is the full content of the [pom.xml] on CURRENT_GIT_BRANCH=[${CURRENT_GIT_BRANCH}] : "
echo "# -------------------------------------------------------------------------------- #"
cat ./pom.xml
echo "# -------------------------------------------------------------------------------- #"


echo "# -------------------------------------------------------------------------------- #"
echo "# ---- NOW WE COMMIT THE PREPARED NEXT VERSION, on CURRENT_GIT_BRANCH=[${CURRENT_GIT_BRANCH}]"
echo "# ---- "
echo "# ---- CURRENT_GIT_BRANCH=[${CURRENT_GIT_BRANCH}]  "
echo "# ---- MAINTENANCE_GIT_BRANCH=[${MAINTENANCE_GIT_BRANCH}]"
echo "# ---- If this is a maintainance release, [CURRENT_GIT_BRANCH] and [MAINTENANCE_GIT_BRANCH] are supposed to be equal."
echo "# ---- If this is a minor release, [CURRENT_GIT_BRANCH] and [MAINTENANCE_GIT_BRANCH] are supposed to be different."
echo "# -------------------------------------------------------------------------------- #"

git add --update
git commit -m 'chore(): Prepare next version'

echo "# -------------------------------------------------------------------------------- #"
echo "# ---- FINALLY WE GIT PUSH PREPARED NEXT VERSION "
echo "# ---- IF AND ONLY IF THIS IS NOT A DRY RUN : "
echo "# -------------------------------------------------------------------------------- #"

if [ "${DRY_RUN}" == "0" ]; then
  # --->>> NO IT IS NOT A DRY RUN
  echo "# --->>> NO IT IS NOT A DRY RUN"
  echo " note that CURRENT_GIT_BRANCH=[${CURRENT_GIT_BRANCH}]"
  echo " note that CURRENT_GIT_BRANCH=[${MAINTENANCE_GIT_BRANCH}]"
  echo " so that CURRENT_GIT_BRANCH=MAINTENANCE_GIT_BRANCH"
  git push --tags origin ${CURRENT_GIT_BRANCH}
else
  echo "# --->>> THIS IS A DRY RUN"
fi;
echo "# -------------------------------------------------------------------------------- #"
