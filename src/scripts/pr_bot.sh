echo "This job will run the pull request bot, in its docker image "
echo " ---"
echo "Here are the values of the Circle CI Pipeline Parameters : "
echo " ---"
echo "PIPELINE_PARAM_GIO_ACTION=[${PIPELINE_PARAM_GIO_ACTION}] "
echo "PIPELINE_PARAM_PR_BOT_IMAGE_TAG=[${PIPELINE_PARAM_PR_BOT_IMAGE_TAG}] "
echo "PIPELINE_PARAM_IS_TRIGGERED_FROM_PR=[${PIPELINE_PARAM_IS_TRIGGERED_FROM_PR}]"
echo " ---"
echo "Here are the values of the Circle CI pull requests related native env. var. : "
echo " ---"
echo "CIRCLE_PULL_REQUEST=[${CIRCLE_PULL_REQUEST}] "
echo "CIRCLE_PULL_REQUESTS=[${CIRCLE_PULL_REQUESTS}] "
echo "Those env.var. are not set empty (do not know why yet: are they set only on Pull request creation events ?)"
echo "CIRCLE_PR_NUMBER=[${CIRCLE_PR_NUMBER}] "
echo "CIRCLE_PR_REPONAME=[${CIRCLE_PR_REPONAME}] "
echo "CIRCLE_PR_USERNAME=[${CIRCLE_PR_USERNAME}] "
echo " ---"
echo "Here are the values infered from Circle CI env. var., releated to the checked out git branch, and the last commit that branch : "
echo " ---"
echo "CHECKED OUT GIT BRANCH IS : [${CIRCLE_BRANCH}] "
echo "LAST COMMIT ON THIS BRANCH IS : [$(git rev-parse ${CIRCLE_BRANCH})] "
echo "Circle CI [CIRCLE_SHA1] value is [${CIRCLE_SHA1}]"
echo " ---"
docker pull quay.io/gravitee-lab/cicd-orchestrator:stable-latest
# checking docker image pulled in previous step is there
docker images
# --> .secrets.json is used by Gravitee CI CD Orchestrator to authenticate to Circle CI
CCI_SECRET_FILE=$PWD/.secrets.json
secrethub read --out-file ${CCI_SECRET_FILE} gravitee-lab/cicd-orchestrator/dev/cci/botuser/.secret.json
ls -allh ${CCI_SECRET_FILE}
# Docker volumes to map pipeline checked out git tree, .env file and .secrets.json files inside the docker container
# export DOCKER_VOLUMES="-v $PWD:/graviteeio/cicd/pipeline -v $PWD/.secrets.json:/graviteeio/cicd/.secrets.json"
export DOCKER_VOLUMES="-v $PWD:/graviteeio/cicd/pipeline -v $PWD/.secrets.json:/graviteeio/cicd/.secrets.json"
docker run --name orchestrator ${DOCKER_VOLUMES} --restart no -it quay.io/gravitee-lab/cicd-orchestrator:stable-latest -s pull_req --dry-run false
