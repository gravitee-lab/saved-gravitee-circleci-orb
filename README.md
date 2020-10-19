# The Gravitee Circle CI Orb

This repo versions the source code of the first Circle CI `Orb`, in the Gravitee.io CI CD system.

The Circle CI pipeline defintion for any git repo is done using a yaml file, in that git repo, of path `.circleci/config.yml`.

This `Orb` is a reusable component, which can be reused to define any Circle CI Pipeline, of any Gravitee.io git repo, in the `.circleci/config.yml` file.

The first release of this `Orb`, will contain the definition of a standard maven release process, for all Gravitee Software Development Process.
