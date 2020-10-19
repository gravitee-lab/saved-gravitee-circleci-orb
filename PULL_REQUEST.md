# Next Pull Request

Reference test :
* https://circleci.com/developer/orbs/orb/orbinoid2/gravitee : the published Orb on Orb Registry
* The 2 pipelines triggered by the Gravitee CI CD Orchestrator (other triggers were cancelled, because of maven errors  :
  * https://app.circleci.com/pipelines/github/gravitee-lab/gravitee-definition/74/workflows/5d5ef256-02f4-4d33-9011-e04e339df9ad/jobs/74
  * https://app.circleci.com/pipelines/github/gravitee-lab/gravitee-fetcher-api/64/workflows/af9ef109-b57e-4e0a-b3cc-34d8b6ff7cae/jobs/64
* The shell script used to perform the maven release, from `Orb`, to each repo : `src/scripts/mvn_release.sh`
