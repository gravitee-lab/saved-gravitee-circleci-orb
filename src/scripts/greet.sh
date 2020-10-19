
export PARAM_TO=${PARAM_TO:-"this is the default value of the 'PARAM_TO' env. var., defined in the [$0] script."}
export PARAM_TEAM=${PARAM_TEAM:-"this is the default value of the 'PARAM_TEAM' env. var., defined in the [$0] script."}


Greet() {
    echo "Hello ${PARAM_TO} ! :)"
    echo "Welcome to the ${PARAM_TEAM} Team! "
}

# Will not run if sourced for bats-core tests.
# View src/tests for more information.
ORB_TEST_ENV="bats-core"
if [ "${0#*$ORB_TEST_ENV}" == "$0" ]; then
    Greet
fi
