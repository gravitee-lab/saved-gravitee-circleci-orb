# The Gravitee Ghallagher Orb


# Secrets Management for https://github.com/<Your Project's Org>

This Orb makes use of secrets, and of secrethub as a secret manager.

Therefore, to use this Orb in your repo, in your github Org (instead of https://github.com/<Your Project s Org>) you must initialize a set of secrets.

This Orb assumes you will manage all the secrets of your CICD System in one single Secrethub repo, and :
* This Orb has one parameter, to set the name of the Secrethub Organization you use : we recommand you use a name as close as possible from your Github Organization s name.
* This Orb has another parameter, to set the name of the Secrethub Repo you use : this name is freeof choice, we have no recommendation for its naming.
* What we do At gravitee :
  * in every repo where we use this Orb, we have Circle CI Pipeline parameters `SECRETHUB_ORG` and `SECRETHUB_REPO` to dynamically set those two parameters.
  * this makes Pipelines easily testable


## CICD Secrets taxonomy trees

All CI CD Secrets have to be managed with Secrethub.

The Glocal CI CD system, will run into two isolated worlds :
* the "real world" (production) : where the CI CD System works for the Gravitee.io Team. That's the https
* the "test world" (tests) : where the CI CD System is tested
* isolation is reached at the Githbu Organization level :
  * 2 completely different Github organizations
  * and therefore 2 completely different secrets taxonomy trees to operate.

With this point of view, the _**The Gravitee Secrets Inventory**_ will therefore have to extensively docuement those two taxonomy trees.

## CICD Secrets taxonomy tree for https://github.com/<Your Project's Org> (Production)

* Secrethub orgs:
  * `${SECRETHUB_ORG}`
* Secrethub repos:
  * `${SECRETHUB_ORG}/${SECRETHUB_REPO}`


* secrets :
  * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/secrethub-svc-account/token`: Secrethub Service Account (Robot user) for Circle CI Pipelines (Secrethub / Circle CI integration)
  * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/api/token` : Circle CI Token used by the Gravitee CI CD Orchestrator
  * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/api/.secrets.json` : Circle CI secret file used by the Gravitee CI CD Orchestrator
  * [Your Project bot](https://github.com/graviteeio) `GnuPG` identity :
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/user_name`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/user_name_comment`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/user_email`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/passphrase`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/key_id`
    * (file) `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/pub_key`
    * (file) `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/private_key`
  * [Your Project bot](https://github.com/graviteeio) git config in all Git Service providers (Github, Gitlab, Bitbucket etc...) :
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/user/name` : [Your Project's Bot](https://github.com/graviteeio) git user name
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/user/email` : [Your Project's Bot](https://github.com/graviteeio) git user email
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/ssh/private_key` : [Your Project's Bot](https://github.com/graviteeio) git ssh private key
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/ssh/public_key` :  [Your Project's Bot](https://github.com/graviteeio) git ssh public key
  * [Your Project bot](https://github.com/graviteeio) artifactory credentials and the multiple `settings.xml` (maven) files used in all CI CD Processes :
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/user-name`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/user-pwd`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/snaphots-repo-url`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/dry-run-release-repo-url`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/release-repo-url`
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/settings.xml` : `settings.xml` to use when not in dry-run mode
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/settings.non.dry.run.xml` :  `settings.xml` to use when **not** in dry-run mode (true release)
  * Quay.io credentials to manage `Gravitee CI CD Orchestrator` Container image (and all container images of all "meta-CI/CD" components - the components of the CICD of the CICD System ) :
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/meta-cicd/orchestrator/docker/quay/username` : [Your Project bot](https://github.com/graviteeio) username to authenticate to Quay.io in `<your_quay_org>/cicd-orchestrator` repository
    * `${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/meta-cicd/orchestrator/docker/quay/token` :  [Your Project bot](https://github.com/graviteeio) token to authenticate to Quay.io in `<your_quay_org>/cicd-orchestrator` repository

## Install Secrethub CLI

* To install Secrethub CLI on Windows, go to https://secrethub.io/docs/reference/cli/install/#windows
* To install Secrethub CLI on any GNU/Linux or Mac OS:

```bash
# eg : https://github.com/secrethub/secrethub-cli/releases/download/v0.41.2/secrethub-v0.41.2-darwin-amd64.tar.gz
export SECRETHUB_CLI_VERSION=0.41.0
# Use [export SECRETHUB_OS=linux] instead of [export SECRETHUB_OS=darwin] for
# most of GNU/Linux Distribution that is not Mac OS.
export SECRETHUB_OS=darwin
export SECRETHUB_CPU_ARCH=amd64


curl -LO https://github.com/secrethub/secrethub-cli/releases/download/v${SECRETHUB_CLI_VERSION}/secrethub-v${SECRETHUB_CLI_VERSION}-${SECRETHUB_OS}-${SECRETHUB_CPU_ARCH}.tar.gz

sudo mkdir -p /usr/local/bin
sudo mkdir -p /usr/local/secrethub/${SECRETHUB_CLI_VERSION}
sudo tar -C /usr/local/secrethub/${SECRETHUB_CLI_VERSION} -xzf secrethub-v${SECRETHUB_CLI_VERSION}-${SECRETHUB_OS}-${SECRETHUB_CPU_ARCH}.tar.gz

sudo ln -s /usr/local/secrethub/${SECRETHUB_CLI_VERSION}/bin/secrethub /usr/local/bin/secrethub

secrethub --version
```

### Init/Rotate secrets

#### `Secrethub` Service Account (Robot user) for `Circle CI` Pipelines

* Secrethub Service Account (Robot user) for Circle CI Pipelines (Secrethub / Circle CI integration) :

```bash
# made with a Github User who is owner of your Project's Github Org
export SECRETHUB_ORG=<your cicd secrethub org>
export SECRETHUB_REPO=<your cicd secrethub repo>

secrethub org init ${SECRETHUB_ORG}
secrethub repo init ${SECRETHUB_ORG}/${SECRETHUB_REPO}
# --- #
# create a service account
secrethub service init "${SECRETHUB_ORG}/${SECRETHUB_REPO}" --description "Circle CI  Service Account for the [cicd-orchestrator] Cirlce CI context for the https://github.com/<Your Project's Org> Organization" --permission read | tee ./.the-created.service.token
secrethub service ls "${SECRETHUB_ORG}/${SECRETHUB_REPO}"
echo "Beware : you will see the service token only once, then you will not ever be able to see it again, don'tloose it (or create another)"
# --- #
# and give the service accoutn access to all directories and secrets in the given repo, with the option :
# --- #
# finally, in Circle CI, you created a 'cicd-orchestrator' context in the [gravitee-io] organization
# dedicated to the Gravitee Ci CD Orchestrator application
# and in that 'cicd-orchestrator' Circle CI context, you set the 'SECRETHUB_CREDENTIAL' env. var. with
# value the token of the service account you just created


# saving service account token
secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/secrethub-svc-account"
cat ./.the-created.service.token | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/secrethub-svc-account/token"
```

#### Circle CI Token used by the Gravitee CI CD Orchestrator

* Circle CI Token and secret file used by the Gravitee CI CD Orchestrator :

```bash
export CCI_SECRET_FILE=$PWD/.secrets.json
export SECRETHUB_ORG=<your cicd secrethub org>
export SECRETHUB_REPO=<your cicd secrethub repo>

# echo "<value of the Circle CI token>" | secrethub write ${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/api/token

export CIRCLECI_TOKEN=$(secrethub read ${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/api/token)

echo "{" | tee -a ${CCI_SECRET_FILE}
echo "  \"circleci\": {" | tee -a ${CCI_SECRET_FILE}
echo "    \"auth\": {" | tee -a ${CCI_SECRET_FILE}
echo "      \"username\": \"Your Project Bot\"," | tee -a ${CCI_SECRET_FILE}
echo "      \"token\": \"${CIRCLECI_TOKEN}\"" | tee -a ${CCI_SECRET_FILE}
echo "    }" | tee -a ${CCI_SECRET_FILE}
echo "  }" | tee -a ${CCI_SECRET_FILE}
echo "}" | tee -a ${CCI_SECRET_FILE}


secrethub write --in-file ./test.retrievieving.secret.json "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/api/.secret.json"
secrethub read ${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/circleci/api/token

```

#### Your Project CI CD Bot GPG identity

* Init / Rotate the Your Project CI CD Bot GPG identity :

```bash
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
#        GPG Key Pair of the Your Project bot         #
#                for Github SSH Service               #
#                to GPG sign maven artifacts          #
#        >>> GPG version 2.x ONLY!!!                  #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# -------------------------------------------------------------- #
# -------------------------------------------------------------- #
# for the Your Project's CI CD Bot in
# the https://github.com/<Your Project's Org> Github Org
# -------------------------------------------------------------- #
# -------------------------------------------------------------- #
# https://www.gnupg.org/documentation/manuals/gnupg-devel/Unattended-GPG-key-generation.html
export GRAVITEEBOT_GPG_USER_NAME="Your Project CI CD Bot"
export GRAVITEEBOT_GPG_USER_NAME_COMMENT="Your Project's CI CD Bot in the https://github.com/<Your Project's Org> Github Org"
export GRAVITEEBOT_GPG_USER_EMAIL="contact@gravitee.io"
export GRAVITEEBOT_GPG_PASSPHRASE="th3gr@vit331sd${RANDOM}ab@s3${RANDOM}"

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ------------------------------------------------------------------------------------------------ #
# -- CREATE THE GPG KEY PAIR for the Your Project CI CD Bot --                               -- SECRET -- #
# ------------------------------------------------------------------------------------------------ #
echo "# ---------------------------------------------------------------------- "
echo "Creating a GPG KEY Pair for the Your Project CI CD Bot"
echo "# ---------------------------------------------------------------------- "
# https://www.gnupg.org/documentation/manuals/gnupg-devel/Unattended-GPG-key-generation.html
export GNUPGHOME="$(mktemp -d)"
cat >./gravitee-io-cicd-bot.gpg <<EOF
%echo Generating a basic OpenPGP key
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: ${GRAVITEEBOT_GPG_USER_NAME}
Name-Comment: ${GRAVITEEBOT_GPG_USER_NAME_COMMENT}
Name-Email: ${GRAVITEEBOT_GPG_USER_EMAIL}
Expire-Date: 0
Passphrase: ${GRAVITEEBOT_GPG_PASSPHRASE}
# Do a commit here, so that we can later print "done" :-)
%commit
%echo done
EOF

gpg --batch --generate-key ./gravitee-io-cicd-bot.gpg
echo "GNUPGHOME=[${GNUPGHOME}] remove that directory when finished initializing secrets"
ls -allh ${GNUPGHOME}
gpg --list-secret-keys
gpg --list-keys

export GRAVITEEBOT_GPG_SIGNING_KEY_ID=$(gpg --list-signatures -a "${GRAVITEEBOT_GPG_USER_NAME} (${GRAVITEEBOT_GPG_USER_NAME_COMMENT}) <${GRAVITEEBOT_GPG_USER_EMAIL}>" | grep 'sig' | tail -n 1 | awk '{print $2}')
echo "GRAVITEEBOT - GPG_SIGNING_KEY=[${GRAVITEEBOT_GPG_SIGNING_KEY_ID}]"

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ------------------------------------------------------------------------------------------------ #
# -- SAVING SECRETS TO SECRETHUB --                                                   -- SECRET -- #
# ------------------------------------------------------------------------------------------------ #
echo "To verify the GPG signature \"Somewhere else\" we will also need the GPG Public key"
export GPG_PUB_KEY_FILE="$(pwd)/yourbot.gpg.pub.key"
export GPG_PRIVATE_KEY_FILE="$(pwd)/yourbot.gpg.priv.key"

# --- #
# saving public and private GPG Keys to files
gpg --export -a "${GRAVITEEBOT_GPG_USER_NAME} (${GRAVITEEBOT_GPG_USER_NAME_COMMENT}) <${GRAVITEEBOT_GPG_USER_EMAIL}>" | tee ${GPG_PUB_KEY_FILE}
# gpg --export -a "Jean-Baptiste Lasselle <jean.baptiste.lasselle.pegasus@gmail.com>" | tee ${GPG_PUB_KEY_FILE}
# -- #
# Will be interactive for private key : you
# will have to type your GPG password
gpg --export-secret-key -a "${GRAVITEEBOT_GPG_USER_NAME} (${GRAVITEEBOT_GPG_USER_NAME_COMMENT}) <${GRAVITEEBOT_GPG_USER_EMAIL}>" | tee ${GPG_PRIVATE_KEY_FILE}
# gpg --export-secret-key -a "Jean-Baptiste Lasselle <jean.baptiste.lasselle.pegasus@gmail.com>" | tee ${GPG_PRIVATE_KEY_FILE}



export SECRETHUB_ORG=<your secrethub org for cicd>
export SECRETHUB_REPO=<your secrehub repo for cicd>
secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg"


echo "${GRAVITEEBOT_GPG_USER_NAME}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/user_name"
echo "${GRAVITEEBOT_GPG_USER_NAME_COMMENT}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/user_name_comment"
echo "${GRAVITEEBOT_GPG_USER_EMAIL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/user_email"
echo "${GRAVITEEBOT_GPG_PASSPHRASE}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/passphrase"
echo "${GRAVITEEBOT_GPG_SIGNING_KEY_ID}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/key_id"
secrethub write --in-file ${GPG_PUB_KEY_FILE} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/pub_key"
secrethub write --in-file ${GPG_PRIVATE_KEY_FILE} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/private_key"
```

#### Your Project CI CD Bot git config

* SSH Key Pair used by the Your Project CI CD Bot to git commit n push to https://github.com/<Your Project Org> repos :

```bash
# --
# ENV. VARS
export SECRETHUB_ORG=<your cicd secrethub org>
export SECRETHUB_REPO=<your cicd secrethub repo>

# secrethub org init ${SECRETHUB_ORG}
# secrethub repo init ${SECRETHUB_ORG}/${SECRETHUB_REPO}

secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/user"
secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/gpg"
secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/ssh"


# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
#            Git user name and email of               #
#                 the Your Project CI CD Bot                 #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #

# --- #
# https://github.com/graviteeio is the Github User of the Your Project CI CD Bot
# --- #
export GIT_USER_NAME="Your Project CI CD Bot"
export GIT_USER_EMAIL="contact@gravitee.io"

echo "${GIT_USER_NAME}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/user/name"
echo "${GIT_USER_EMAIL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/user/email"



# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
#        SSH RSA Key Pair of the Your Project CI CD Bot      #
#                for Github SSH Service               #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #
# --- # --- # --- # --- # --- # --- # --- # --- # --- #


export LOCAL_SSH_PUBKEY=${HOME}/.ssh.cicd.yourbot/id_rsa.pub
export LOCAL_SSH_PRVIKEY=${HOME}/.ssh.cicd.yourbot/id_rsa
# --- #
# https://github.com/graviteeio is the Github User of the Your Project CI CD Bot
# --- #
export ROBOTS_ID=graviteeio

export LE_COMMENTAIRE_DE_CLEF="[$ROBOTS_ID]-cicd-bot@github.com"
# --- #
# Is it extremely important that the Private Key passphrase is empty, for
# the Key Pair to be used as SSH Key with Github.com Git Service
# --- #
export PRIVATE_KEY_PASSPHRASE=''

mkdir -p ${HOME}/.ssh.cicd.yourbot
ssh-keygen -C "${LE_COMMENTAIRE_DE_CLEF}" -t rsa -b 4096 -f ${LOCAL_SSH_PRVIKEY} -q -P "${PRIVATE_KEY_PASSPHRASE}"

sudo chmod 700 ${HOME}/.ssh.cicd.yourbot
sudo chmod 644 ${LOCAL_SSH_PUBKEY}
sudo chmod 600 ${LOCAL_SSH_PRVIKEY}

secrethub write --in-file ${LOCAL_SSH_PUBKEY} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/ssh/public_key"
secrethub write --in-file ${LOCAL_SSH_PRVIKEY} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/ssh/private_key"

# --- The admin who can add an SSH Key to the Your Project s Bot s Github User
export SECRETHUB_ORG=<your cicd secrethub org>
export SECRETHUB_REPO=<your cicd secrethub repo>
secrethub read --out-file ".retrieved.ssh.cicd.yourbot.id_rsa.pub" "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/git/ssh/public_key"
echo ''
echo "Add the below PUBLIC Rsa Key to the SSH Keys of https://github.com/graviteeio, the Github User of the Your Project CI CD Bot, then proceed secrets initalization"
cat .retrieved.ssh.cicd.yourbot.id_rsa.pub
echo ''

secrethub account inspect

# --- #

```


#### Your Project CI CD Bot artifactory credentials

* init / rotate the Your Project CI CD Bot artifactory credentials

```bash
export SECRETHUB_ORG=<your secrethub org for cicd>
export SECRETHUB_REPO=<your secrehub repo for cicd>
secrethub org init "${SECRETHUB_ORG}"
secrethub repo init "${SECRETHUB_ORG}/${SECRETHUB_REPO}"

# --- #
# for the DEV CI CD WorkFlow of
# the Gravitee CI CD Orchestrator
secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/"

# --- #
# write quay secrets for the DEV CI CD WorkFlow of
# the Gravitee CI CD Orchestrator
export ARTIFACTORY_BOT_USER_NAME="yourbot"
export ARTIFACTORY_BOT_USER_PWD="inyourdreams;)"

echo "${ARTIFACTORY_BOT_USER_NAME}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/user-name"
echo "${ARTIFACTORY_BOT_USER_PWD}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/user-pwd"

```

#### Gravitee.io CI CD `settings.xml` files in https://github.com/<YOUR ORG>

* init / rotate the Your Project CI CD Bot `settings.xml` files used in all CI CD Processes :

```bash
export SECRETHUB_ORG=<your secrethub org for cicd>
export SECRETHUB_REPO=<your secrehub repo for cicd>
export ARTIFACTORY_REPO_DRY_RUN_RELEASE_URL="http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/dry-run-releases/"
export ARTIFACTORY_REPO_RELEASE_URL="http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/gravitee-releases/"
export ARTIFACTORY_REPO_SNAPSHOTS_URL="http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/dry-run-snapshots/"

echo "ARTIFACTORY_REPO_SNAPSHOTS_URL=[${ARTIFACTORY_REPO_SNAPSHOTS_URL}]"
echo "ARTIFACTORY_REPO_DRY_RUN_RELEASE_URL=[${ARTIFACTORY_REPO_DRY_RUN_RELEASE_URL}]"
echo "ARTIFACTORY_REPO_RELEASE_URL=[${ARTIFACTORY_REPO_RELEASE_URL}]"


echo "${ARTIFACTORY_REPO_SNAPSHOTS_URL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/snaphots-repo-url"
echo "${ARTIFACTORY_REPO_DRY_RUN_RELEASE_URL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/dry-run-release-repo-url"
echo "${ARTIFACTORY_REPO_RELEASE_URL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/release-repo-url"

# From the latest secrets, create the secret settings.xml file
export SECRETHUB_ORG=<your secrethub org for cicd>
export SECRETHUB_REPO=<your secrehub repo for cicd>
export ARTIFACTORY_BOT_USER_NAME=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/user-name")
export ARTIFACTORY_BOT_USER_PWD=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/user-pwd")
export ARTIFACTORY_REPO_SNAPSHOTS_URL=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/snaphots-repo-url")
export ARTIFACTORY_REPO_DRY_RUN_RELEASE_URL=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/dry-run-release-repo-url")
export ARTIFACTORY_REPO_RELEASE_URL=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/release-repo-url")

export GRAVITEEBOT_GPG_PASSPHRASE=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/passphrase")

echo "ARTIFACTORY_BOT_USER_NAME=[${ARTIFACTORY_BOT_USER_NAME}]"
echo "ARTIFACTORY_BOT_USER_PWD=[${ARTIFACTORY_BOT_USER_PWD}]"
echo "ARTIFACTORY_REPO_SNAPSHOTS_URL=[${ARTIFACTORY_REPO_SNAPSHOTS_URL}]"
echo "ARTIFACTORY_REPO_DRY_RUN_RELEASE_URL=[${ARTIFACTORY_REPO_DRY_RUN_RELEASE_URL}]"
echo "ARTIFACTORY_REPO_RELEASE_URL=[${ARTIFACTORY_REPO_RELEASE_URL}]"
echo "GRAVITEEBOT_GPG_PASSPHRASE=[${GRAVITEEBOT_GPG_PASSPHRASE}]"


if [ -f ./.secret.settings.xml ]; then
  rm ./.secret.settings.xml
fi;
if [ -f ./.secret.settings.non.dry.run.xml ]; then
  rm ./.secret.settings.non.dry.run.xml
fi;

cat <<EOF >>./.secret.settings.xml
<?xml version="1.0" encoding="UTF-8"?>
<!--

    Copyright (C) 2015 The Gravitee team (http://gravitee.io)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

            http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

-->
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <pluginGroups></pluginGroups>
  <proxies></proxies>
  <mirrors>
    <mirror>
      <!--The maven referential for all CI CD Processes in  Dry Run Mode -->
      <id>artifactory-gravitee-dry-run</id>
      <mirrorOf>external:*</mirrorOf>
      <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/nexus-and-dry-run-releases/</url>
    </mirror>
  </mirrors>
  <servers>
    <server>
      <id>artifactory-gravitee-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>artifactory-gravitee-dry-run</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>artifactory-plugin-repository-remote-nexus</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>artifactory-repository-dry-run-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>your-artifactory-dry-run-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>your-artifactory-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <!-- as of https://maven.apache.org/plugins/maven-gpg-plugin/usage.html -->
      <id>gpg.passphrase</id>
      <passphrase>${GRAVITEEBOT_GPG_PASSPHRASE}</passphrase>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>gravitee-dry-run</id>
        <properties>
          <altDeploymentRepository>your-artifactory-dry-run-releases::default::${ARTIFACTORY_REPO_DRY_RUN_RELEASE_URL}</altDeploymentRepository>
        </properties>
        <activation>
            <property>
                <name>performRelease</name>
                <value>true</value>
            </property>
        </activation>
        <repositories>
          <repository>
            <id>artifactory-repository-remote-nexus</id>
            <name>Artifactory Repository Remote Nexus</name>
            <releases>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </releases>
            <snapshots>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </snapshots>
            <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/remote-nexus/</url>
            <layout>default</layout>
          </repository>
          <repository>
            <id>artifactory-repository-dry-run-releases</id>
            <name>Artifactory Repository Dry Run Releases</name>
            <releases>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </releases>
            <snapshots>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </snapshots>
            <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/dry-run-releases/</url>
            <layout>default</layout>
          </repository>
          <repository>
            <id>artifactory-gravitee-releases</id>
            <name>Artifactory Repository Dry Run Releases</name>
            <releases>
              <enabled>true</enabled>
              <updatePolicy>always</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </releases>
            <snapshots>
              <enabled>true</enabled>
              <updatePolicy>always</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </snapshots>
            <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/gravitee-releases/</url>
            <layout>default</layout>
          </repository>
        </repositories>
        <pluginRepositories>
          <pluginRepository>
            <id>artifactory-plugin-repository-remote-nexus</id>
            <name>Artifactory Proxy Releases</name>
            <releases>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </releases>
            <snapshots>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </snapshots>
            <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/remote-nexus/</url>
            <layout>default</layout>
          </pluginRepository>
        </pluginRepositories>
    </profile>

    <profile>
      <id>gravitee-release</id>
        <properties>
          <altDeploymentRepository>your-artifactory-releases::default::${ARTIFACTORY_REPO_RELEASE_URL}</altDeploymentRepository>
        </properties>
        <activation>
            <property>
                <name>performRelease</name>
                <value>true</value>
            </property>
        </activation>
    </profile>
  </profiles>
  <activeProfiles>
  <activeProfile>gravitee-dry-run</activeProfile>
  </activeProfiles>
</settings>
EOF


cat <<EOF >>./.secret.settings.non.dry.run.xml
<?xml version="1.0" encoding="UTF-8"?>
<!--

    Copyright (C) 2015 The Gravitee team (http://gravitee.io)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

            http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

-->
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0 http://maven.apache.org/xsd/settings-1.0.0.xsd">
  <pluginGroups></pluginGroups>
  <proxies></proxies>
  <mirrors>
    <mirror>
      <!--The maven referential for all CI CD Processes in NON Dry Run Mode -->
      <id>artifactory-gravitee-non-dry-run</id>
      <mirrorOf>external:*</mirrorOf>
      <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/nexus-and-non-dry-run-releases/</url>
    </mirror>
  </mirrors>
  <servers>
    <server>
      <id>artifactory-gravitee-non-dry-run</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>artifactory-plugin-repository-remote-nexus</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>artifactory-repository-dry-run-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>your-artifactory-dry-run-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>your-artifactory-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <!-- as of https://maven.apache.org/plugins/maven-gpg-plugin/usage.html -->
      <id>gpg.passphrase</id>
      <passphrase>${GRAVITEEBOT_GPG_PASSPHRASE}</passphrase>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>gio-release</id>
        <properties>
          <altDeploymentRepository>your-artifactory-dry-run-releases::default::${ARTIFACTORY_REPO_RELEASE_URL}</altDeploymentRepository>
        </properties>
        <activation>
            <property>
                <name>performRelease</name>
                <value>true</value>
            </property>
        </activation>
        <repositories>
          <repository>
            <id>artifactory-gravitee-releases</id>
            <name>Artifactory Repository Dry Run Releases</name>
            <releases>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </releases>
            <snapshots>
              <enabled>true</enabled>
              <updatePolicy>always</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </snapshots>
            <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/gravitee-releases/</url>
            <layout>default</layout>
          </repository>
          <repository>
            <id>artifactory-repository-remote-nexus</id>
            <name>Artifactory Repository Remote Nexus</name>
            <releases>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </releases>
            <snapshots>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </snapshots>
            <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/remote-nexus/</url>
            <layout>default</layout>
          </repository>
          <repository>
            <id>artifactory-repository-dry-run-releases</id>
            <name>Artifactory Repository Dry Run Releases</name>
            <releases>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </releases>
            <snapshots>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </snapshots>
            <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/dry-run-releases/</url>
            <layout>default</layout>
          </repository>
        </repositories>
        <pluginRepositories>
          <pluginRepository>
            <id>artifactory-plugin-repository-remote-nexus</id>
            <name>Artifactory Proxy Releases</name>
            <releases>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </releases>
            <snapshots>
              <enabled>true</enabled>
              <updatePolicy>never</updatePolicy>
              <checksumPolicy>warn</checksumPolicy>
            </snapshots>
            <url>http://YOUR_ARTIFACTORY_SERVICE_HOSTNAME/remote-nexus/</url>
            <layout>default</layout>
          </pluginRepository>
        </pluginRepositories>
    </profile>
    <profile>
      <id>gravitee-release</id>
        <properties>
          <altDeploymentRepository>your-artifactory-releases::default::${ARTIFACTORY_REPO_RELEASE_URL}</altDeploymentRepository>
        </properties>
        <activation>
            <property>
                <name>performRelease</name>
                <value>true</value>
            </property>
        </activation>
    </profile>
  </profiles>
  <activeProfiles>
  <activeProfile>gio-release</activeProfile>
  </activeProfiles>
</settings>
EOF


# secrethub write --in-file ./.secret.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/settings.xml"
secrethub write --in-file ./.secret.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/settings.xml"
secrethub write --in-file ./.secret.settings.non.dry.run.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/settings.non.dry.run.xml"
secrethub read --out-file ./test.retrievieving.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/infra/maven/dry-run/artifactory/settings.non.dry.run.xml"

cat ./test.retrievieving.settings.xml

rm ./test.retrievieving.settings.xml

exit 0
```


#### Gravitee.io CI CD System Container library : Quay.io credentials

* Quay.io credentials to manage `Gravitee CI CD Orchestrator` Container image (and all container images of all "meta-CI/CD" components - the components of the CICD of the CICD System ) :

```bash
export SECRETHUB_ORG=<your cicd secrethub org>
export SECRETHUB_REPO=<your cicd secrethub repo>

secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/meta-cicd/orchestrator/docker/quay/botuser"

# Credentials to authenticate to quay.io
export QUAY_BOT_USERNAME="your_gh_org+yourbot"
export QUAY_BOT_SECRET="very long value of the quay.io authentication token"



# [Your Project's Bot] username to authenticate to Quay.io in [<your_quay_org>/cicd-orchestrator] repository
echo "${QUAY_BOT_USERNAME}" | secrethub write ${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/meta-cicd/orchestrator/docker/quay/botuser/username
# [Your Project's Bot] token to authenticate to Quay.io in `<your_quay_org>/cicd-orchestrator` repository
echo "${QUAY_BOT_SECRET}" | secrethub write ${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/meta-cicd/orchestrator/docker/quay/botuser/token

```



## ANNEX A : Testing the GPG Signature


* Test on any machine, using the `GnuPG` Bot Identity to sign files :

```bash
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ------------------------------------------------------------------------------------------------ #
# ---         Restore GPG Private and Public Keys to be able to sign Files AGAIN  !!!!!        --- #
# -------------------------------------------------------------------------------------------------#
# (replace `export SECRETHUB_ORG=<your secrethub org for cicd>` by `export SECRETHUB_ORG="gravitee-lab"` to test the GnuPG Identity in the https://github.com/<YOUR ORG> Github Organization)
export SECRETHUB_ORG=<your secrethub org for cicd>
export SECRETHUB_REPO=<your secrehub repo for cicd>

export EPHEMERAL_KEYRING_FOLDER_ZERO=$(mktemp -d)
export RESTORE_GPG_TMP_DIR=$(mktemp -d)
export RESTORED_GPG_PUB_KEY_FILE="$(pwd)/yourbot.gpg.pub.key"
export RESTORED_GPG_PRIVATE_KEY_FILE="$(pwd)/yourbot.gpg.priv.key"

chmod 700 ${EPHEMERAL_KEYRING_FOLDER_ZERO}
export GNUPGHOME=${EPHEMERAL_KEYRING_FOLDER_ZERO}
# gpg --list-secret-keys
# gpg --list-pub-keys
gpg --list-keys

secrethub read --out-file ${RESTORED_GPG_PUB_KEY_FILE} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/pub_key"
secrethub read --out-file ${RESTORED_GPG_PRIVATE_KEY_FILE} "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/private_key"

# ---
# - > to import the private key file, the
# - > passphrase of the private key will
# - > interactively be asked to the user.
# ---
# gpg --import ${RESTORED_GPG_PRIVATE_KEY_FILE}

# ---
# - > to import the private key file, but
# - > wthout interactive input required
# - > that's how you do it
# ---
gpg --batch --import ${RESTORED_GPG_PRIVATE_KEY_FILE}

# ---
# --- non-interactive
gpg --import ${RESTORED_GPG_PUB_KEY_FILE}
# ---
# now we trust ultimately the Public Key in the Ephemeral Context,
export GRAVITEEBOT_GPG_SIGNING_KEY_ID=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/key_id")
echo "GRAVITEEBOT_GPG_SIGNING_KEY_ID=[${GRAVITEEBOT_GPG_SIGNING_KEY_ID}]"

echo -e "5\ny\n" |  gpg --command-fd 0 --expert --edit-key ${GRAVITEEBOT_GPG_SIGNING_KEY_ID} trust

# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# -- TESTS --   Testing using the Restored GPG Key :                                   -- TESTS -- #
# -- TESTS --   to sign a file, and verify file signature                              -- TESTS -- #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #
# ------------------------------------------------------------------------------------------------ #

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ------------------------------------------------------------------------------------------------ #
# -- TESTS --                          First Let's Sign a file                         -- TESTS -- #
# ------------------------------------------------------------------------------------------------ #
cat >./some-file-to-sign.txt <<EOF
Hey I ma sooo important a file that
I am in a file which is going to be signed to proove my integrity
EOF

export GRAVITEEBOT_GPG_PASSPHRASE=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/passphrase")

# echo "${GRAVITEEBOT_GPG_PASSPHRASE}" | gpg --pinentry-mode loopback --passphrase-fd 0 --sign ./some-file-to-sign.txt

# ---
# That's Jean-Baptiste Lasselle's GPG SIGNING KEY ID for signing git commits n tags (used as example)
# export GPG_SIGNING_KEY_ID=7B19A8E1574C2883
# ---
# That's the GPG_SIGNING_KEY used buy the "Your Project CI CD Bot" for git and signing any file
# export GRAVITEEBOT_GPG_SIGNING_KEY_ID=$(gpg --list-signatures -a "${GRAVITEEBOT_GPG_USER_NAME} (${GRAVITEEBOT_GPG_USER_NAME_COMMENT}) <${GRAVITEEBOT_GPG_USER_EMAIL}>" | grep 'sig' | tail -n 1 | awk '{print $2}')
export GRAVITEEBOT_GPG_SIGNING_KEY_ID=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/key_id")
echo "GRAVITEEBOT_GPG_SIGNING_KEY_ID=[${GRAVITEEBOT_GPG_SIGNING_KEY_ID}]"

gpg --keyid-format LONG -k "0x${GRAVITEEBOT_GPG_SIGNING_KEY}"

echo "${GRAVITEEBOT_GPG_PASSPHRASE}" | gpg -u "0x${GRAVITEEBOT_GPG_SIGNING_KEY}" --pinentry-mode loopback --passphrase-fd 0 --sign ./some-file-to-sign.txt
echo "${GRAVITEEBOT_GPG_PASSPHRASE}" | gpg -u "0x${GRAVITEEBOT_GPG_SIGNING_KEY}" --pinentry-mode loopback --passphrase-fd 0 --detach-sign ./some-file-to-sign.txt



# -- #
# Will be interactive for private key : you
# will have to type your GPG password
# gpg --export-secret-key -a "${GRAVITEEBOT_GPG_USER_NAME} <${GRAVITEEBOT_GPG_USER_EMAIL}>" | tee ${GPG_PRIVATE_KEY_FILE}

# ------------------------------------------------------------------------------------------------ #
# # - To sign a GPG Key  with 1 specific private keys
# gpg --local-user 0xDEADBEE5 --sign file
# # - To sign a GPG Key  with 2 private keys
# gpg --local-user 0xDEADBEE5 --local-user 0x12345678 --sign file
# # - To sign a GPG Key  with 1 specific private keys
# gpg -u 0xDEADBEE5 --sign file
# # - To sign a GPG Key  with 2 private keys
# gpg -u 0xDEADBEE5 --local-user 0x12345678 --sign file
# ------------------------------------------------------------------------------------------------ #
echo "# ------------------------------------------------------------------------------------------------ #"
echo "the [$(pwd)/some-file-to-sign.txt] file is the file which was signed"
ls -allh ./some-file-to-sign.txt
echo "the [$(pwd)/some-file-to-sign.txt.sig] file is the signed file which was signed, and has its signature embedded"
ls -allh ./some-file-to-sign.txt.gpg
echo "the [$(pwd)/some-file-to-sign.txt.sig] file is the (detached) signature of the file which was signed"
ls -allh ./some-file-to-sign.txt.sig
echo "# ------------------------------------------------------------------------------------------------ #"
echo "In software, we use detached signatures, because when you sign a very "
echo "big size file, distributing the signature does not force distributing a very big file"
echo "# ------------------------------------------------------------------------------------------------ #"


# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# ------------------------------------------------------------------------------------------------ #
# -- TESTS --   Now test verifying the signed file, using its detached signature       -- TESTS -- #
# ------------------------------------------------------------------------------------------------ #

echo "  Now testing verifying the file with its detached signature :"
gpg --verify ./some-file-to-sign.txt.sig some-file-to-sign.txt
echo "# ------------------------------------------------------------------------------------------------ #"
echo "  Now testing verifying the file with its detached signature, in another Ephemeral GPG Keyring "
echo "# ------------------------------------------------------------------------------------------------ #"
export EPHEMERAL_KEYRING_FOLDER_TWO=$(mktemp -d)
chmod 700 ${EPHEMERAL_KEYRING_FOLDER_TWO}
export GNUPGHOME=${EPHEMERAL_KEYRING_FOLDER_TWO}
# gpg --list-secret-keys
# gpg --list-pub-keys
gpg --list-keys
echo "# ------------------------------------------------------------------------------------------------ #"
unset GNUPGHOME
echo "  First, without resetting GNUPGHOME env. var.  "
echo "  (we are still in the default Keyring for the current Linux User, so verifying will be successful) "
echo "# ------------------------------------------------------------------------------------------------ #"
gpg --verify ./some-file-to-sign.txt.sig some-file-to-sign.txt
echo "# ------------------------------------------------------------------------------------------------ #"
echo "  Now let's switch to the created Ephemeral GPG Keyring (Ephemeral GPG Context)"
echo "# ------------------------------------------------------------------------------------------------ #"
export GNUPGHOME=${EPHEMERAL_KEYRING_FOLDER_TWO}
# gpg --list-secret-keys
# gpg --list-pub-keys
gpg --list-keys
echo "# ------------------------------------------------------------------------------------------------ #"
echo "  Ok, there is no GPG Public key in this Ephemral GPG context"
echo "  That's why verifying the signed file with its detached signature, will fail : "
echo "    => a GPG signature is \"bound\" to its associated Public Key "
echo "    => GPG signature is Asymetric Cryptography (very important)"
echo "# ------------------------------------------------------------------------------------------------ #"
gpg --verify ./some-file-to-sign.txt.sig some-file-to-sign.txt

# now we import the Public Key in the Ephemeral Context, trust it ultimately, and verify the file signature again
gpg --import "${GPG_PUB_KEY_FILE}"
# now we trust ultimately the Public Key in the Ephemeral Context,
# export GRAVITEEBOT_GPG_SIGNING_KEY_ID=$(gpg --list-signatures -a "${GRAVITEEBOT_GPG_USER_NAME} (${GRAVITEEBOT_GPG_USER_NAME_COMMENT}) <${GRAVITEEBOT_GPG_USER_EMAIL}>" | grep 'sig' | tail -n 1 | awk '{print $2}')
export GRAVITEEBOT_GPG_SIGNING_KEY_ID=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/ghallagerbot/gpg/key_id")
echo "GRAVITEEBOT_GPG_SIGNING_KEY_ID=[${GRAVITEEBOT_GPG_SIGNING_KEY_ID}]"

echo -e "5\ny\n" |  gpg --command-fd 0 --expert --edit-key ${GPG_SIGNING_KEY_ID} trust

# ++
# ++ To ultimately trust ALL Keys :
# for fpr in $(gpg --list-keys --with-colons  | awk -F: '/fpr:/ {print $10}' | sort -u); do  echo -e "5\ny\n" |  gpg --command-fd 0 --expert --edit-key $fpr trust; done
# ++

# ++
# And finally verify the file signature again
gpg --verify ./some-file-to-sign.txt.sig some-file-to-sign.txt
```



# Orb Source Code Packaging

Orbs are shipped as individual `orb.yml` files, however, to make development easier, it is possible to author an orb in _unpacked_ form, which can be _packed_ with the CircleCI CLI and published.

The default `.circleci/config.yml` file contains the configuration code needed to automatically pack, test, and deploy and changes made to the contents of the orb source in this directory.

## @orb.yml

This is the entry point for our orb "tree", which becomes our `orb.yml` file later.

Within the `@orb.yml` we generally specify 4 configuration keys

**Keys**

1. **version**
    Specify version 2.1 for orb-compatible configuration `version: 2.1`
2. **description**
    Give your orb a description. Shown within the CLI and orb registry
3. **display**
    Specify the `home_url` referencing documentation or product URL, and `source_url` linking to the orb's source repository.
4. **orbs**
    (optional) Some orbs may depend on other orbs. Import them here.

## See:
 - [Orb Author Intro](https://circleci.com/docs/2.0/orb-author-intro/#section=configuration)
 - [Reusable Configuration](https://circleci.com/docs/2.0/reusing-config)
