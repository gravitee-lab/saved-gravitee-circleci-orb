# The Gravitee Ghallagher Orb


## Secrets Initialization for https://github.com/gravitee-io

```bash
export SECRETHUB_ORG="gravitee-io"
export SECRETHUB_REPO="cicd"
secrethub org init "${SECRETHUB_ORG}"
secrethub repo init "${SECRETHUB_ORG}/${SECRETHUB_REPO}"

# --- #
# for the DEV CI CD WorkFlow of
# the Gravitee CI CD Orchestrator
secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/"

# --- #
# write quay secrets for the DEV CI CD WorkFlow of
# the Gravitee CI CD Orchestrator
export ARTIFACTORY_BOT_USER_NAME="graviteebot"
export ARTIFACTORY_BOT_USER_PWD="inyourdreams;)"
export ARTIFACTORY_REPO_RELEASE_URL="http://<domain name here>/dry-run-releases/"
export ARTIFACTORY_REPO_SNAPSHOTS_URL="http://<domain name here>/dry-run-snapshots/"

echo "ARTIFACTORY_REPO_SNAPSHOTS_URL=[${ARTIFACTORY_REPO_SNAPSHOTS_URL}]"
echo "ARTIFACTORY_REPO_RELEASE_URL=[${ARTIFACTORY_REPO_RELEASE_URL}]"


echo "${ARTIFACTORY_BOT_USER_NAME}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/user-name"
echo "${ARTIFACTORY_BOT_USER_PWD}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/user-pwd"
echo "${ARTIFACTORY_REPO_SNAPSHOTS_URL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/snaphots-repo-url"
echo "${ARTIFACTORY_REPO_RELEASE_URL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/release-repo-url"


# From the latest secrets, create the secret settings.xml file
export SECRETHUB_ORG="gravitee-io"
export SECRETHUB_REPO="cicd"
export ARTIFACTORY_BOT_USER_NAME=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/user-name")
export ARTIFACTORY_BOT_USER_PWD=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/user-pwd")
export ARTIFACTORY_REPO_SNAPSHOTS_URL=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/snaphots-repo-url")
export ARTIFACTORY_REPO_RELEASE_URL=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/release-repo-url")

if [ -f ./.secret.settings.xml ]; then
  rm ./.secret.settings.xml
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

  <servers>
    <server>
      <id>clever-cloud-artifactory-dry-run-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>clever-cloud-artifactory-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>gravitee-dry-run</id>
        <properties>
          <altDeploymentRepository>clever-cloud-artifactory-dry-run-releases::default::${ARTIFACTORY_REPO_RELEASE_URL}</altDeploymentRepository>
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

# secrethub write --in-file ./.secret.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.xml"
secrethub write --in-file ./.secret.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.xml"
secrethub read --out-file ./test.retrievieving.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.xml"

cat ./test.retrievieving.settings.xml
rm ./test.retrievieving.settings.xml

```

* And finally, the Circle CI `cicd-orchestrator` _context_ must have the following env .var. :
  * `SECRETHUB_CREDENTIAL` : This Orb uses secrethub secret manager, so you ahve to set the value of this env.var. with a secrethub service account with read permissions
<!--
  * `DRY_RUN_MVN_PROFILE_ID` : The maven profile
  * `SECRETHUB_CREDENTIAL` :
  * `SECRETHUB_ORG` :
  * `SECRETHUB_REPO` :
-->


## Secrets Initialization for https://github.com/gravitee-lab

```bash
export SECRETHUB_ORG="gravitee-lab"
export SECRETHUB_REPO="cicd"
secrethub org init "${SECRETHUB_ORG}"
secrethub repo init "${SECRETHUB_ORG}/${SECRETHUB_REPO}"

# --- #
# for the DEV CI CD WorkFlow of
# the Gravitee CI CD Orchestrator
secrethub mkdir --parents "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/"

# --- #
# write quay secrets for the DEV CI CD WorkFlow of
# the Gravitee CI CD Orchestrator
export ARTIFACTORY_BOT_USER_NAME="graviteebot"
export ARTIFACTORY_BOT_USER_PWD="inyourdreams;)"
export ARTIFACTORY_REPO_RELEASE_URL="http://<domain name here>/dry-run-releases/"
export ARTIFACTORY_REPO_SNAPSHOTS_URL="http://<domain name here>/dry-run-snapshots/"

echo "ARTIFACTORY_REPO_SNAPSHOTS_URL=[${ARTIFACTORY_REPO_SNAPSHOTS_URL}]"
echo "ARTIFACTORY_REPO_RELEASE_URL=[${ARTIFACTORY_REPO_RELEASE_URL}]"


echo "${ARTIFACTORY_BOT_USER_NAME}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/user-name"
echo "${ARTIFACTORY_BOT_USER_PWD}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/user-pwd"
echo "${ARTIFACTORY_REPO_SNAPSHOTS_URL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/snaphots-repo-url"
echo "${ARTIFACTORY_REPO_RELEASE_URL}" | secrethub write "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/release-repo-url"


# From the latest secrets, create the secret settings.xml file
export SECRETHUB_ORG="gravitee-lab"
export SECRETHUB_REPO="cicd"
export ARTIFACTORY_BOT_USER_NAME=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/user-name")
export ARTIFACTORY_BOT_USER_PWD=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/user-pwd")
export ARTIFACTORY_REPO_SNAPSHOTS_URL=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/snaphots-repo-url")
export ARTIFACTORY_REPO_RELEASE_URL=$(secrethub read "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/release-repo-url")

if [ -f ./.secret.settings.xml ]; then
  rm ./.secret.settings.xml
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

  <servers>
    <server>
      <id>clever-cloud-artifactory-dry-run-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
    <server>
      <id>clever-cloud-artifactory-releases</id>
      <username>${ARTIFACTORY_BOT_USER_NAME}</username>
      <password>${ARTIFACTORY_BOT_USER_PWD}</password>
    </server>
  </servers>
  <profiles>
    <profile>
      <id>gravitee-dry-run</id>
        <properties>
          <altDeploymentRepository>clever-cloud-artifactory-dry-run-releases::default::${ARTIFACTORY_REPO_RELEASE_URL}</altDeploymentRepository>
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

# secrethub write --in-file ./.secret.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.xml"
secrethub write --in-file ./.secret.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.xml"
secrethub read --out-file ./test.retrievieving.settings.xml "${SECRETHUB_ORG}/${SECRETHUB_REPO}/graviteebot/infra/maven/dry-run/artifactory/settings.xml"

cat ./test.retrievieving.settings.xml
rm ./test.retrievieving.settings.xml

```

* And finally, the Circle CI `cicd-orchestrator` _context_ must have the following env .var. :
  * `SECRETHUB_CREDENTIAL` : This Orb uses secrethub secret manager, so you ahve to set the value of this env.var. with a secrethub service account with read permissions
<!--
  * `DRY_RUN_MVN_PROFILE_ID` : The maven profile
  * `SECRETHUB_CREDENTIAL` :
  * `SECRETHUB_ORG` :
  * `SECRETHUB_REPO` :
-->



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
