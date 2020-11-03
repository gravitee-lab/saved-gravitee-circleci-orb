# There is no default value applied here : the
# default value should be defined by the Circle CI Orb Logic ONLY.
export DRY_RUN=${DRY_RUN}
export DESIRED_MAVEN_VERSION=${DESIRED_MAVEN_VERSION:-'3.6.3'}
export MVN_DOCKER="maven:${DESIRED_MAVEN_VERSION}-openjdk-11 "

Usage() {
  echo " Usage :  "
  echo " [--------------------------------------------------------------------------------] "
  echo " [$0] "
  echo " [--------------------------------------------------------------------------------] "
  echo " Environment Variables : "
  echo " [--------------------------------------------------------------------------------] "
  echo "  SECRETHUB_ORG (Required) The name of the Secrethub Org from which Secrets have to be fetched"
  echo "  SECRETHUB_REPO (Required) The name of the Secrethub Repo from which Secrets have to be fetched"
  echo " [--------------------------------------------------------------------------------] "
}

Info() {
  echo " [--------------------------------------------------------------------------------] "
  echo "   Running [$0] with maven version [${DESIRED_MAVEN_VERSION}] "
  echo "   Running [$0] in dry run Mode ? [${DRY_RUN}] "
  echo "   Running [$0] with Secret Hub Org name [${SECRETHUB_ORG}] "
  echo "   Running [$0] with Secret Hub Repo name [${SECRETHUB_REPO}] "
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
  # the ${MAVEN_SHELL_SCRIPT} shell script IS in the docker container, because of the docker volume to $PWD
  docker run -it --rm -v "$PWD":/usr/src/giomaven_project -v "$HOME/.m2":/root/.m2 -w /usr/src/giomaven_project ${MVN_DOCKER} ${MAVEN_SHELL_SCRIPT}
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

Info

# ---
# This plugin will edit the [pom.xml] to resetthe maven project version.
# The purpose here, is to "get rid of the [-SNAPSHOT] suffix comming
# from the release.json"
# ---
# Example :
# --> the [pom.xml] has version [1.3.1-SNAPSHOT], so we run :
# mvn -B versions:set -DnewVersion=1.3.1 -DgenerateBackupPoms=false
# ---
# To do that, we need the version of the maven project. That's a few commands to run. SO we need to run that as a script.
# --> So we create a shell script with the required commands, and then run the script with the [runMavenShellScript] function
# --> Note that Circle CI Orbs file inclusion works with only Onefile, that's why we HAVE to generate it "on the fly"
if [ -f ./.circleci/mvn.script.sh ]; then
  rm ./.circleci/mvn.script.sh
fi;
# --- model is [mvn_release_trim_snapshot.sh]
# 1./ Ok,so first, need to pick up the maven project version from [pom.xml], using the maven exec plugin
echo "export MVN_PRJ_VERSION=\$(mvn -Dexec.executable='echo' -Dexec.args='\${project.version}' --non-recursive exec:exec -q; echo \"\$?\" > maven.exit.code)" | tee -a ./.circleci/mvn.script.sh
export MVN_COMMAND="mvn -Dexec.executable='echo' -Dexec.args='\\\${project.version}' --non-recursive exec:exec -q"
echo "export MVN_EXIT_CODE=\$(cat maven.exit.code)" | tee -a ./.circleci/mvn.script.sh
echo "echo \"[\$0] The exit code of the [${MVN_COMMAND}] maven command is [\${MVN_EXIT_CODE}] \"" | tee -a ./.circleci/mvn.script.sh
echo "if ! [ \"\${MVN_EXIT_CODE}\" == \"0\" ]; then" | tee -a ./.circleci/mvn.script.sh
echo "  echo \"[\$0] The exit code of the [${MVN_COMMAND}] maven command is [\${MVN_EXIT_CODE}], so not zero \"" | tee -a ./.circleci/mvn.script.sh
echo "  rm maven.exit.code" | tee -a ./.circleci/mvn.script.sh
echo "  exit \${MVN_EXIT_CODE}" | tee -a ./.circleci/mvn.script.sh
echo "fi;" | tee -a ./.circleci/mvn.script.sh
echo "rm maven.exit.code" | tee -a ./.circleci/mvn.script.sh

echo "echo \"Resolved Maven Project version : [\${MVN_PRJ_VERSION}]\"" | tee -a ./.circleci/mvn.script.sh
# But MVN_PRJ_VERSION has the '-SNAPSHOT' suffix, we need to strip it off, to pass that exact verion to maven version plugin
echo "export MVN_PRJ_VERSION=\$(echo \"\${MVN_PRJ_VERSION}\" | awk -F '-SNAPSHOT' '{print \$1}')" | tee -a ./.circleci/mvn.script.sh
echo "echo \"trimmed [-SNAPSHOT] suffix from Maven Project version : [\${MVN_PRJ_VERSION}]\"" | tee -a ./.circleci/mvn.script.sh
# So we can retrieve the project version out of container
echo "echo \"\${MVN_PRJ_VERSION}\" > ./.circleci/gio.maven.project.version" | tee -a ./.circleci/mvn.script.sh
# 2./ and then we can run the [mvn -B versions:set -DnewVersion=1.3.1 -DgenerateBackupPoms=false]
export MVN_COMMAND="mvn -B versions:set -DnewVersion=\\\${MVN_PRJ_VERSION} -DgenerateBackupPoms=false"
echo "mvn -B versions:set -DnewVersion=\${MVN_PRJ_VERSION} -DgenerateBackupPoms=false" | tee -a ./.circleci/mvn.script.sh
# 3./ Exit code
echo "export MVN_EXIT_CODE=\$?" | tee -a ./.circleci/mvn.script.sh
echo "echo \"[\$0] The exit code of the [${MVN_COMMAND}] maven command is [\${MVN_EXIT_CODE}] \"" | tee -a ./.circleci/mvn.script.sh
echo "exit \${MVN_EXIT_CODE}" | tee -a ./.circleci/mvn.script.sh
# finally let's make it executable, before passing it to the [runMavenShellScript] function
chmod +x ./.circleci/mvn.script.sh
runMavenShellScript ./.circleci/mvn.script.sh



export MVN_PRJ_VERSION=$(cat ./.circleci/gio.maven.project.version)
export MVN_PRJ_VERSION_MAJOR=$(cat ./.circleci/gio.maven.project.version | awk -F '.' '{print $1}')
export MVN_PRJ_VERSION_MINOR=$(cat ./.circleci/gio.maven.project.version | awk -F '.' '{print $2}')
export MVN_PRJ_VERSION_PATCH=$(cat ./.circleci/gio.maven.project.version | awk -F '.' '{print $3}')

echo "MVN_PRJ_VERSION=[${MVN_PRJ_VERSION}]"
echo "MVN_PRJ_VERSION_PATCH=[${MVN_PRJ_VERSION_PATCH}]"

# ---
# the command to update dependencies
export MVN_UPDATER_CMD="mvn -B -U versions:update-properties -Dincludes=io.gravitee.*:* -DallowMajorUpdates=false -DallowMinorUpdates=false -DallowIncrementalUpdates=true -DgenerateBackupPoms=false"
echo "${MVN_UPDATER_CMD}" > ./.circleci/mvn.script2.sh
echo "export MVN_EXIT_CODE=\$?" | tee -a ./.circleci/mvn.script2.sh
echo "echo \"[\$0] The exit code of the [${MVN_UPDATER_CMD}] maven command is [\${MVN_EXIT_CODE}] \"" | tee -a ./.circleci/mvn.script2.sh
echo "exit \${MVN_EXIT_CODE}" | tee -a ./.circleci/mvn.script2.sh
chmod +x ./.circleci/mvn.script2.sh

# ---
# If The maven project version, ends with '.0', then
# this is a maintainance release
if [ "${MVN_PRJ_VERSION_PATCH}" == "0" ]; then
  # yes it is a maintainance version
  runMavenShellScript ./.circleci/mvn.script2.sh
else
  # no it is not a maintainance version
  runMavenShellScript ./.circleci/mvn.script2.sh
fi;


# --- --- --- --- --- --- --- #
# ---  FINAL MVN DEPLOY   --- #
# --- --- --- --- --- --- --- #

export MVN_COMMAND="mvn clean"

# ---------------------------------------
# is it a dry run
# ---------------------------------------
echo "# ---------------------------------------"
echo " IS IT A DRY RUN ? [DRY_RUN=[${DRY_RUN}]] "
echo "# ---------------------------------------"
# the GIT_COMMIT env. var. will be picked up by maven
export GIT_COMMIT=$(git rev-parse HEAD)
# Ok, that's just the way it is is Circle CI types (inverted from C LANGUAGE AND ALL UNIX CONVENTIONS : ZERO IS FALSE, ONE IS TRUE....)
if [ "${DRY_RUN}" == "1" ]; then
  # --->>> YES IT IS A DRY RUN
  echo "# --->>> YES IT IS A DRY RUN"
  echo "Release Dry Mode is ON"
  export MVN_COMMAND="mvn -B -U clean install"
  echo "${MVN_COMMAND}" | tee ./.circleci/mvn.script3.sh

  echo "export MVN_EXIT_CODE=\$?" | tee -a ./.circleci/mvn.script3.sh
  echo "echo \"[\$0] The exit code of the previous maven command is [\${MVN_EXIT_CODE}] \"" | tee -a ./.circleci/mvn.script3.sh
  echo "if ! [ \"\${MVN_EXIT_CODE}\" == \"0\" ]; then" | tee -a ./.circleci/mvn.script3.sh
  echo "  echo \"[\$0] The exit code of the [${MVN_COMMAND}] maven command is [\${MVN_EXIT_CODE}], so not zero \"" | tee -a ./.circleci/mvn.script3.sh
  echo "  exit \${MVN_EXIT_CODE}" | tee -a ./.circleci/mvn.script3.sh
  echo "fi;" | tee -a ./.circleci/mvn.script3.sh

  export MVN_COMMAND="mvn enforcer:enforce"
  echo "${MVN_COMMAND}" | tee -a ./.circleci/mvn.script3.sh
  echo "export MVN_EXIT_CODE=\$?" | tee -a ./.circleci/mvn.script3.sh
  echo "echo \"[\$0] The exit code of the [${MVN_COMMAND}] maven command is [\${MVN_EXIT_CODE}] \"" | tee -a ./.circleci/mvn.script3.sh
  echo "exit \${MVN_EXIT_CODE}" | tee -a ./.circleci/mvn.script3.sh
  chmod +x ./.circleci/mvn.script3.sh
  runMavenShellScript ./.circleci/mvn.script3.sh

else
  if [ "${DRY_RUN}" == "0" ]; then
    # --->>> NO IT IS NOT A DRY RUN
    echo "# --->>> NO IT IS NOT A DRY RUN"
    export MVN_COMMAND="mvn -B -U -P gravitee-release clean deploy"
    echo "${MVN_COMMAND}" > ./.circleci/mvn.script4.sh
    echo "export MVN_EXIT_CODE=\$?" | tee -a ./.circleci/mvn.script4.sh
    echo "echo \"The exit code of the [${MVN_COMMAND}] maven command is [\${MVN_EXIT_CODE}] \"" | tee -a ./.circleci/mvn.script4.sh
    echo "exit \${MVN_EXIT_CODE}" | tee -a ./.circleci/mvn.script4.sh
    chmod +x ./.circleci/mvn.script4.sh
    runMavenShellScript ./.circleci/mvn.script4.sh

  else
    echo "Error : received [DRY_RUN=[${DRY_RUN}]] value, while Circle CI should have transmitted either ZERO for false, or ONE, for false"
    exit 3
  fi;
fi;

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
  mvn -B versions:set -DnewVersion=${NEXT_PATCH_SNAPSHOT_VERSION} -DgenerateBackupPoms=false
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
  mvn -B versions:set -DnewVersion=${NEXT_SNAPSHOT_VERSION} -DgenerateBackupPoms=false
else
  echo "# ---- [${MVN_PRJ_VERSION}] is a maintenance release, so we increment PATCH VERSION from [${MVN_PRJ_VERSION_PATCH}] to [${NEXT_PATCH_VERSION}], and prepared next version will be [${NEXT_PATCH_SNAPSHOT_VERSION}] "
  echo "resetting version in [pom.xml] to [${NEXT_PATCH_SNAPSHOT_VERSION}]"
  mvn -B versions:set -DnewVersion=${NEXT_PATCH_SNAPSHOT_VERSION} -DgenerateBackupPoms=false
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
