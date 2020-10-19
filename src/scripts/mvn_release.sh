# export DRY_RUN=${DRY_RUN:-"true"}
# so that there is no default value applied here : the
# default value should be defined by the Circle CI Orb Logic ONLY.
export DRY_RUN=${DRY_RUN}
export DESIRED_MAVEN_VERSION=${DESIRED_MAVEN_VERSION:-'3.6.3'}
export MVN_DOCKER="maven:${DESIRED_MAVEN_VERSION}-openjdk-16 "


Info() {
  echo "Running [$0] with maven version [${DESIRED_MAVEN_VERSION}] "
  echo "Running [$0] in dry run Mode ? ${DRY_RUN} "
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
}


# --- --- --- --- --- --- --- #
# ---   operations start  --- #
# --- --- --- --- --- --- --- #
# From notes at https://github.com/gravitee-io/release/issues/128#issuecomment-700120543
# ---


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
if [ -f ./mvn.script.sh ]; then
  rm ./mvn.script.sh
fi;
# --- model is [mvn_release_trim_snapshot.sh]
# 1./ Ok,so first, need to pick up the maven project version from [pom.xml], using the maven exec plugin
echo "export MVN_PRJ_VERSION=\$(mvn -Dexec.executable='echo' -Dexec.args='\${project.version}' --non-recursive exec:exec -q)" | tee -a ./mvn.script.sh
echo "echo \"Resolved Maven Project version : [\${MVN_PRJ_VERSION}]\"" | tee -a ./mvn.script.sh
# But MVN_PRJ_VERSION has the '-SNAPSHOT' suffix, we need to strip it off, to pass that exact verion to maven version plugin
echo "export MVN_PRJ_VERSION=\$(echo \"\${MVN_PRJ_VERSION}\" | awk -F '-SNAPSHOT' '{print \$1}')" | tee -a ./mvn.script.sh
echo "echo \"trimmed from-SNAPSHOT Maven Project version : [\${MVN_PRJ_VERSION}]\"" | tee -a ./mvn.script.sh
# So we can retrieve the project version out of container
echo "echo \"\${MVN_PRJ_VERSION}\" > ./gio.maven.project.version" | tee -a ./mvn.script.sh
# 2../ and then we can run the [mvn -B versions:set -DnewVersion=1.3.1 -DgenerateBackupPoms=false]
echo "mvn -B versions:set -DnewVersion=\${MVN_PRJ_VERSION} -DgenerateBackupPoms=false" | tee -a ./mvn.script.sh
# finally let's make it executable, before passing it to the [runMavenShellScript] function
chmod +x ./mvn.script.sh
runMavenShellScript ./mvn.script.sh

export MVN_PRJ_VERSION=$(cat ./gio.maven.project.version)
export MVN_PRJ_VERSION_PATCH=$(cat ./gio.maven.project.version | awk -F '.' '{print $3}')

echo "MVN_PRJ_VERSION=[${MVN_PRJ_VERSION}]"
echo "MVN_PRJ_VERSION_PATCH=[${MVN_PRJ_VERSION_PATCH}]"

# ---
# the command to update dependencies
export MVN_UPDATER_CMD="mvn -B -U versions:update-properties -Dincludes=io.gravitee.*:* -DallowMajorUpdates=false -DallowMinorUpdates=false -DallowIncrementalUpdates=true -DgenerateBackupPoms=false"
echo "${MVN_UPDATER_CMD}" > ./mvn.script2.sh
chmod +x ./mvn.script2.sh

# ---
# If The maven project version, ends with '.0', then
# this is a maintainance release
if [ "${MVN_PRJ_VERSION_PATCH}" == "0" ]; then
  # yes it is a maintainance version
  runMavenShellScript ./mvn.script2.sh
else
  # no it is not a maintainance version
  runMavenShellScript ./mvn.script2.sh
fi;


# --- --- --- --- --- --- --- #
# ---  FINAL MVN DEPLOY   --- #
# --- --- --- --- --- --- --- #
export MVN_UPDATER_CMD="mvn -B -U versions:update-properties -Dincludes=io.gravitee.*:* -DallowMajorUpdates=false -DallowMinorUpdates=false -DallowIncrementalUpdates=true -DgenerateBackupPoms=false"
echo "${MVN_UPDATER_CMD}" > ./mvn.script2.sh


export MVN_COMMAND="mvn clean"

# ---------------------------------------
# is it a dry run
# ---------------------------------------
echo "# ---------------------------------------"
echo " IS IT A DRY RUN ? [DRY_RUN=[${DRY_RUN}]] "
echo "# ---------------------------------------"
# Ok, that's just the way it is is Circle CI types (inverted from C LANGUAGE AND ALL UNIX CONVENTIONS : ZERO IS FALSE, ONE IS TRUE....)
if [ "${DRY_RUN}" == "1" ]; then
  # --->>> YES IT IS A DRY RUN
  echo "# --->>> YES IT IS A DRY RUN"
  echo "Release Dry Mode is ON"
  export MVN_COMMAND="mvn -B -U clean install"
  echo "${MVN_COMMAND}" > ./mvn.script3.sh
  export MVN_COMMAND="mvn enforcer:enforce"
  echo "${MVN_COMMAND}" >> ./mvn.script3.sh
  chmod +x ./mvn.script3.sh
  runMavenShellScript ./mvn.script3.sh
else
  if [ "${DRY_RUN}" == "0" ]; then
    # --->>> NO IT IS NOT A DRY RUN
    echo "# --->>> NO IT IS NOT A DRY RUN"
    export MVN_COMMAND="mvn -B -U -P gravitee-release clean deploy"
    echo "${MVN_COMMAND}" > ./mvn.script4.sh
    chmod +x ./mvn.script4.sh
    runMavenShellScript ./mvn.script4.sh
  else
    echo "Error : received [DRY_RUN=[${DRY_RUN}]] value, while Circle CI shoudl have transmitted either ZERO for false, or ONE, for false"
    exit 3
  fi;
fi;






Info

echo "[DEBUG] Implementation of the maven release process not finished."

exit 1




exit 0
# ---
# Below, notes I took while being explained what the former Jenkins Scripts did.
# ---
# 1.3.1-SNAPSHOT -> to 1.3.1
mvn -B versions:set -DnewVersion=1.3.1 -DgenerateBackupPoms=false

# detection si c'est une version de maintenance (un patch, ou une nouvelle feature/un breaking change) :
# les versions qui terminent par '.0' ne sont pas de maintenance sinon c'est une version de maintenance


# donc l'enjeu ci dessous est que si c'est une version de maintenance ou pas, on pourra
# vouloir une politique différente :
# soit on autorise l'upgrade automatique des versions majeures mineures
# soit on ne l'autorise pas : notre politique n'est pas complètement fixe de ce côté
# il y a des cas où l'on souhaite l'update automatique

                    if (c.version.isMaintenance()) { # keep detection of is maintainance or not : maybe we want different
                        mvn -B -U versions:update-properties -Dincludes=io.gravitee.*:* -DallowMajorUpdates=false -DallowMinorUpdates=false -DallowIncrementalUpdates=true -DgenerateBackupPoms=false
                    } else {
                        mvn -B -U versions:update-properties -Dincludes=io.gravitee.*:* -DallowMajorUpdates=false -DallowMinorUpdates=false -DallowIncrementalUpdates=true -DgenerateBackupPoms=false
                    }

# enfin, on veux faire le mvn clean install en insérant le git commit id pour le BUILD NUMBER

                    withEnv(["GIT_COMMIT=${git_commit}"]) {
                        // deploy
                        if (dryRun) {
                            sh "mvn -B -U clean install"
                            sh "mvn enforcer:enforce"
                        } else {
                            sh "mvn -B -U -P gravitee-release clean deploy"
                        }















# --- Cirlcle CI Team BATS Framework Filter
# (So BATS Can run its test suite, though they are not that valuable in
# my opinion. BATS is like Unit Tests, but for Shell Scripts.)
# ---
# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
    Greet
fi
