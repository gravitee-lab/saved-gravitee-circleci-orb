
# ---
# This script is unsed by the Circle CI Orb, here just for the record, and will be used to
# create this script on-the-fly with the [mvn_release.sh] script, if necessary
# ---
# This command updates the maven project dependencies"
mvn -B -U versions:update-properties -Dincludes=io.gravitee.*:* -DallowMajorUpdates=false -DallowMinorUpdates=false -DallowIncrementalUpdates=true -DgenerateBackupPoms=false
