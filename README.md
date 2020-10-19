# The Gravitee Circle CI `Orb`

This repo versions the source code of the first Circle CI `Orb`, in the Gravitee.io CI CD system.

The Circle CI pipeline defintion for any git repo is done using a yaml file, in that git repo, of path `.circleci/config.yml`.

This `Orb` is a reusable component, which can be reused to define any Circle CI Pipeline, of any Gravitee.io git repo, in the `.circleci/config.yml` file.

The first release of this `Orb`, will contain the definition of a standard maven release process, for all Gravitee Software Development Process.

## The Release Job

Using the Release Job in a  `.circleci/config.yml` is simple, and can be done as such :

```Yaml
version: 2.1
parameters:
  # 'gio_action' will soon be renamed 'cicd_process'
  gio_action:
    type: enum
    enum: [product_release, lts_support_release, sts_support_release, dev_pr_review, support_pr_review, pull_requests_bot]
    # default parameter value will for now, select no workflow to execute.
    default: pull_requests_bot
  dry_run:
    type: boolean
    # always run in dry run modeby default
    default: true

orbs:
  # secrethub: secrethub/cli@1.0.0
  gravitee: orbinoid2/gravitee@0.0.14
  # gravitee: gravitee-io/gravitee@0.0.1

workflows:
  version: 2.1
  release:
    when:
      equal: [ product_release, << pipeline.parameters.gio_action >> ]
    jobs:
      # Job defined from the CICD Circle CI Orb , using a Machine executor.
      - gravitee/release:
          dry_run: << pipeline.parameters.dry_run >>
          maven_version: 3.6.3
```

The _parameters_ of the release Orb Job, are :

* `dry_run` : a boolean, if set to `true` (actually to `1`) , will activate the dry-run mode. DEfaults to `true`
* `maven_version` : a string, which alows to set the version of the `maven` utility used at (Pipeline) runtime.


**Meta**: This repository is open for contributions! Feel free to open a pull request with your changes. Due to the nature of this repository, it is not built on CircleCI. The Resources and How to Contribute sections relate to an orb created with this template, rather than the template itself.

## Resources

[CircleCI Orb Registry Page](https://circleci.com/orbs/registry/orb/<namespace>/<project-name>) - The official registry page of this orb for all versions, executors, commands, and jobs described.
[CircleCI Orb Docs](https://circleci.com/docs/2.0/orb-intro/#section=configuration) - Docs for using and creating CircleCI Orbs.

### How to Contribute

We welcome [issues](https://github.com/<organization>/<project-name>/issues) to and [pull requests](https://github.com/<organization>/<project-name>/pulls) against this repository!

### How to Publish
* Create and push a branch with your new features.
* When ready to publish a new production version, create a Pull Request from fore _feature branch_ to `master`.
* The title of the pull request must contain a special semver tag: `[semver:<segement>]` where `<segment>` is replaced by one of the following values.

| Increment | Description|
| ----------| -----------|
| major     | Issue a 1.0.0 incremented release|
| minor     | Issue a x.1.0 incremented release|
| patch     | Issue a x.x.1 incremented release|
| skip      | Do not issue a release|

Example: `[semver:major]`

* Squash and merge. Ensure the semver tag is preserved and entered as a part of the commit message.
* On merge, after manual approval, the orb will automatically be published to the Orb Registry.


For further questions/comments about this or other orbs, visit the Orb Category of [CircleCI Discuss](https://discuss.circleci.com/c/orbs).
