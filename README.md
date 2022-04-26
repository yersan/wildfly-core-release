# Release WildFly Core (using Docker)

WildFly Core release process requires a significant amount of memory.
Please ensure that your Docker can have 4 GiB of memory.

First you need to build the image by starting up your Docker daemon, and executing
    `docker build -t jmesnil/wildfly-core-release:11 .`
Whenever the contents of this git repository are updated you will need to rebuild the image.

To speed things up when running the container we do some volume mapping, so that we don't have to repopulate everything from scratch each time we run a build. Some of these mappings require persistent docker volumes. The `run-docker-release.sh` script does all the passing of parameters, but I will list them here:

    * `-v ~/.m2/settings.xml:/home/wfcore/.m2/settings.xml` -   This maps your `settings.xml` to `/home/wfcore/.m2/settings.xml` in the docker image. The docker image will by default use `/home/wfcore/.m2` as its maven home folder.
    * `-v wfcore-release-maven-repo:/home/wfcore/.m2` - The docker image will by default use `/home/wfcore/.m2` as its maven home folder. This command maps the host OS's `wfcore-release-maven-repo` folder to that, which means that we can run builds quickly without having to download the world every time we run a build. `wfcore-release-maven-repo` is a docker persistent volume which is reused between builds. It needs to be created only once (although you can delete it and recreate it) by running `docker volume create --name wfcore-release-maven-repo`. All writes under this location will end up in this Docker volume rather than in your main maven repository, so you can happily run this container while doing builds in your main OS - without the two interfering.
    * `-v wfcore-release-checkouts:/home/wfcore/checkouts` - To avoid having to wait for a lengthy checkout process, we map the `wfcore-release-checkouts` docker persistent volume to a folder within docker called `/home/wfcore/checkouts`. It needs to be created only once (although you can delete it and recreate it) by running `docker volume create --name wfcore-release-checkouts`. The first time the image is used, it will do a `git clone`, and on subsequent runs it will do a `git fetch` and then reset the branch to the latest.
    * `	-v ~/.ssh:/root/.ssh` - maps your local `~/.ssh` folder to Docker's `/home/wfcore/.ssh` folder so that we can push to GitHub.
    * `	-it wildfly-core-release:11` - specifies the name of the image to use when running the container.

To do a release you run this script:
	`./run-docker-release.sh <SNAPSHOT_VERSION> <RELEASE_VERSION> <NEXT_SNAPSHOT_VERSION> <GITHUB_USER> <WILDFLY_CORE_BRANCH> <WILDFLY_BRANCH>`

For example, if Core is at 19.0.0.Beta1-SNAPSHOT, the command to release 19.0.0.Beta1 and prepare for the next snapshot at 19.0.0.Beta2-SNAPSHOT is:

```
./run-docker-release.sh 19.0.0.Beta1-SNAPSHOT 19.0.0.Beta1 19.0.0.Beta2-SNAPSHOT jmesnil main main
```

where `jmesnil` is the GitHub user that is releasing WildFly Core.
