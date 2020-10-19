
# ---
# This script is unsed by the Circle CI Orb, here just for the record, and was used to
# create this script on-the-fly with the [mvn_release.sh] script
# ---
# This plugin will edit the [pom.xml] to resetthe maven project version.
# The purpose here, is to "get rid of the [-SNAPSHOT] suffix comming
# from the release.json"
# ---
# Example :
# --> the [pom.xml] has version [1.3.1-SNAPSHOT], so we run :
# mvn -B versions:set -DnewVersion=1.3.1 -DgenerateBackupPoms=false
# ---
# 1./ Ok,so first, need to pick up the maven project version from [pom.xml], using the maven exec plugin
export MVN_PRJ_VERSION=$(mvn -Dexec.executable='echo' -Dexec.args='${project.version}' --non-recursive exec:exec -q; echo "$?" > maven.exit.code)

export MVN_EXIT_CODE=$(cat maven.exit.code)
echo "[$0] The exit code of the previous maven command is [${MVN_EXIT_CODE}] "
if ! [ "${MVN_EXIT_CODE}" == "0" ]; then
  echo "[$0] The exit code of the script is [${MVN_EXIT_CODE}], so not zero "
  rm maven.exit.code
  exit ${MVN_EXIT_CODE}
fi;
rm maven.exit.code

echo "Resolved Maven Project version : [${MVN_PRJ_VERSION}]"
# But MVN_PRJ_VERSION has the '-SNAPSHOT' suffix, we need to strip it off, to pass that exact verion to maven version plugin
# export MVN_PRJ_VERSION=1.3.1-SNAPSHOT
export MVN_PRJ_VERSION=$(echo "${MVN_PRJ_VERSION}" | awk -F '-SNAPSHOT' '{print $1}')
echo "trimmed [-SNAPSHOT] suffix from Maven Project version : [${MVN_PRJ_VERSION}]"
# So we can retrieve the project versionout of container
echo "${MVN_PRJ_VERSION}" > ./gio.maven.project.version
# 2../ and then we can run the [mvn -B versions:set -DnewVersion=1.3.1 -DgenerateBackupPoms=false]
mvn -B versions:set -DnewVersion=${MVN_PRJ_VERSION} -DgenerateBackupPoms=false
export MVN_EXIT_CODE=$?
echo "[$0] The exit code of the script is [${MVN_EXIT_CODE}] "
exit ${MVN_EXIT_CODE}
# --> So we createa shell script with the required commands, and then run the script with the [runMavenShellScript] function
