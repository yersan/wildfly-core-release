#!/bin/bash

###################################
# WildFly Core Release Process
###################################
#
# This script is used to create releases of WildFly Core.
# It accepts 4 parameters:
# 1. the current version in the POMs (something like 5.0.0.Alpha1-SNAPSHOT)
# 2. the version to release (e.g. 5.0.0.Alpha1)
# 3. the next version after the release (e.g. 5.0.0.Beta1-SNAPSHOT)
# 4. the GitHub user that will contains the branch and tag used to create the release
#
# This script does *not* push anything to the WildFly GitHub repositories.
# Commits and tag are stored in the user GitHub repo and he/she will have to push
# the tag and the release branch in separate steps after the script is finished.
#
# The script requires to *close* the Nexus stating repositories to test WildFly
# with the tentative Core releases.
#
# /!\ Releasing the Nexus repository must be done after the script is finished.
#
###################################

# For debugging purpose
#set -x

################################
# Prompt user for confirmation
#
# Accept an optional prompt message (else "Continue?" is displayed)
#
# Return 0 if user confirmed (by typing y or Y)
# Return 1 if user did not confirm (by typing n or N)
################################
prompt_confirm() {
  while true; do
    read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
      [yY]) echo ; return 0 ;;
      [nN]) echo ; return 1 ;;
      *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac
  done
}

################################
# Clone a Git repo from the wildfly org and update to latest main branch
# Add a remote endpoint for the user GitHub repository
#
# 1st parameter is the user name of the GitHub repo (e.g. jmesnil or kabir)
# 2nd parameter is the name of the project (e.g. wildfly-core)
# 3rd parameter is the branch to update of the project (e.g. main)
################################
git_clone_and_update() {
  user=$1
  project=$2
  branch=$3

  if [ "${project}" == "wildfly" ]; then
    echo "Using WildFly Repo: ${WILDFLY_OFFICIAL_GITHUB_REPO}"
    upstream_url="${WILDFLY_OFFICIAL_GITHUB_REPO}/${project}.git"
  else
    echo "Using Core WildFly Repo: ${WILDFLY_CORE_OFFICIAL_GITHUB_REPO}"
    upstream_url="${WILDFLY_CORE_OFFICIAL_GITHUB_REPO}/${project}.git"
  fi

  #Check if the project has been checked out and clone or update
  if [ ! -d "${HOME}/checkouts/${project}" ]; then
    user_url="git@github.com:${user}/${project}.git"
    echo "=================================================================================================="
    echo "The ${project} checkout folder does not exist. Cloning ${upstream_url}"
    echo "=================================================================================================="
    git clone $upstream_url
    echo "=================================================================================================="
    echo "Adding the remote ${user} for ${user_url} repository"
    echo "=================================================================================================="
    cd ${project}
    git remote add ${user} ${user_url}
    cd ..
  else
    echo "=================================================================================================="
    echo "The ${project} checkout folder exists. Refreshing the latest from ${branch} branch"
    echo "=================================================================================================="
    cd ${project}
    git checkout ${branch}
    git fetch origin
    git reset --hard origin/${branch}
    cd ..
  fi
}

################################
# Change the version of the Core modules
#
# 1st parameter is the *current* version
# 2nd parameter is the *next* version
################################
change_core_version() {
  current_version=$1
  next_version=$2

  # Now replace the versions in the poms
  echo ""
  echo "=================================================================================================="
  echo " Replacing ${current_version} with ${next_version} in the poms"
  echo "=================================================================================================="
  echo ""
  find . -type f -name "pom.xml" -print0 | xargs -0 -t sed -i "s/${current_version}/${next_version}/g"
  echo ""
  echo "=================================================================================================="
  echo " Modified files"
  echo "=================================================================================================="
  echo ""
  git status
}

################################
# Command Arguments
################################
FROM_VERSION=$1
TO_VERSION=$2
NEXT_VERSION=$3
GITHUB_USER=$4
GITHUB_USER_REPO=git@github.com:${GITHUB_USER}
WILDFLY_CORE_BRANCH=$5
WILDFLY_BRANCH=$6
# This environment variable can be used in case you need to integrate wildfly-core changes with other commits when you
# when upgrading the wildfly-core version on full. You could use this environment variable to point out to a topic branch
# probably rebased on top of the latest wildfly#main branch. This topic branch could contain other WFLY Jiras PRs that
# need to be merged together with the wildfly-core upgrade. When using it, remember to rebase your topic branch on top of
# the latest wildfly#main
WILDFLY_CORE_OFFICIAL_GITHUB_REPO=${7:-'git@github.com:wildfly'}
WILDFLY_OFFICIAL_GITHUB_REPO=${8:-'git@github.com:wildfly'}
# Needed for gnupg pinentry when signing commits
GPG_TTY=$(tty)

cd $HOME
if [ "x$FROM_VERSION" = "x" ]; then
	echo "from version is not set"
	exit 1
fi

if [ "x$TO_VERSION" = "x" ]; then
	echo "to version is not set"
	exit 1
fi

if [ "x$NEXT_VERSION" = "x" ]; then
	echo "next version is not set"
	exit 1
fi

if [ "x$GITHUB_USER" = "x" ]; then
	echo "GitHub user is not set"
	exit 1
fi

echo "=================================================================================================="
echo "Current Env:"
env
echo "FROM_VERSION=$FROM_VERSION"
echo "TO_VERSION=$TO_VERSION"
echo "NEXT_VERSION=$NEXT_VERSION"
echo "GITHUB_USER=$GITHUB_USER"
echo "GITHUB_USER_REPO=$GITHUB_USER_REPO"
echo "WILDFLY_CORE_OFFICIAL_GITHUB_REPO=$WILDFLY_CORE_OFFICIAL_GITHUB_REPO"
echo "WILDFLY_OFFICIAL_GITHUB_REPO=$WILDFLY_OFFICIAL_GITHUB_REPO"
echo "WILDFLY_CORE_BRANCH=$WILDFLY_CORE_BRANCH"
echo "WILDFLY_BRANCH=$WILDFLY_BRANCH"
echo "=================================================================================================="

echo "=================================================================================================="
echo "You are preparing to release WildFly Core ${TO_VERSION} at ${GITHUB_USER_REPO}"
echo "    from ${FROM_VERSION}"
echo "    and prepare next release ${NEXT_VERSION}"
echo "=================================================================================================="
prompt_confirm || exit 1

#Check that the checkouts folder was mapped, if not create a temp one and cd into it
if [ ! -d "${HOME}/checkouts" ]; then
    echo "No checkouts folder was exists so creating a temp one. To cache this in the future between all jobs:"
    echo "-Create a persistent docker volume which can be reused by running (this only needs doing once):"
    echo "     docker volume create --name wfcore-release-checkouts"
    echo "-Pass in the following parameter to docker run to reuse the checkouts folder:"
    echo "   -v wfcore-release-checkouts:/home/wfcore/checkouts"
    mkdir $HOME/checkouts
fi
cd $HOME/checkouts

# Start SSH agent to avoid typing everytime the SSH passphrase
eval `ssh-agent -s`

echo "=================================================================================================="
echo "Clone WildFly Branch ${WILDFLY_BRANCH}"
git_clone_and_update ${GITHUB_USER} "wildfly" ${WILDFLY_BRANCH}
echo "=================================================================================================="
cd wildfly
git fetch origin ${WILDFLY_BRANCH}
git checkout --track origin/${WILDFLY_BRANCH}
git status
cd ..

echo "=================================================================================================="
echo "Clone WildFly Core Branch ${WILDFLY_CORE_BRANCH}"
git_clone_and_update ${GITHUB_USER} "wildfly-core" ${WILDFLY_CORE_BRANCH}
echo "=================================================================================================="
cd wildfly-core
git checkout ${WILDFLY_CORE_BRANCH}
BRANCH_NAME=release_wildfly-core_${TO_VERSION}
#TODO this will give an error, but nothing serious if $BRANCH_NAME does not exist. It would be nice though to check somehow and only delete if it exists
git branch -D ${BRANCH_NAME}
git checkout -b ${BRANCH_NAME}
git status

# check that there is some SNAPSHOT versions to release...
FROM_COUNT=`git grep "$current_version" | wc -l`
if [ ${FROM_COUNT} -lt 10 ]; then
    echo "Only $FROM_COUNT references to $current_version were found in existing poms. As a sanity check we look for at least five of those. Make sure you used the correct 'from' version."
    echo "Searching for -SNAPSHOT in main pom.xml:"
    git grep "\-SNAPSHOT" pom.xml
    exit 1
fi
echo "Found $FROM_COUNT occurrences of $current_version in poms..."


echo ""
echo "=================================================================================================="
echo " Remaining -SNAPSHOT versions"
echo "=================================================================================================="
echo ""

change_core_version ${FROM_VERSION} ${TO_VERSION}

git grep "\-SNAPSHOT"
prompt_confirm "Do the remaining SNAPSHOTs above look correct?" || exit 1

echo ""
echo "=================================================================================================="
echo " Doing the WildFly Core build "
echo "=================================================================================================="
#Run the build with all the flags set
mvn clean install -Pjboss-release -Prelease -DallTests --fail-at-end
BUILD_STATUS=$?
if [ ${BUILD_STATUS} != 0 ]; then
    echo "=================================================================================================="
    echo " Build failed "
    echo "  ./run-docker-ls.sh <dir>"
    echo "and"
    echo "  ./run-docker-more.sh <dir>"
    echo "from another terminal window to get more information about the failures."
    echo "=================================================================================================="
    prompt_confirm "Are you sure you want to continue the release process?" || exit 1
fi

# Any error in the script will now exit the script
set -e

echo ""
echo "=================================================================================================="
echo " Verifying WildFly Full still builds"
echo "=================================================================================================="

# Refresh WildFly to make sure we have the latest
cd ..
git_clone_and_update ${GITHUB_USER} wildfly ${WILDFLY_BRANCH}
cd wildfly
git checkout ${WILDFLY_BRANCH}
git status

# Build WildFly skipping tests, but overriding the core version
mvn clean install -DallTests -DskipTests -Dversion.org.wildfly.core=${TO_VERSION}

echo ""
echo "=================================================================================================="
echo " Committing the wildfly-core changes "
echo " Pushing the branch ${GITHUB_USER}/${BRANCH_NAME}"
echo " Pushing the tag ${GITHUB_USER}/${TO_VERSION}"
echo "=================================================================================================="
cd ../wildfly-core
git status

git commit -am "Prepare for the $TO_VERSION release"
# Force push to overwrite any previous attempt to release the version
git push -f ${GITHUB_USER} ${BRANCH_NAME}
# Force the tag and push to overwrite any previous attempt to release the version
git tag -f ${TO_VERSION}
git push -f ${GITHUB_USER} ${TO_VERSION}

echo ""
echo "=================================================================================================="
echo " Deploying the core release to the staging repository"
echo "=================================================================================================="

# Deploy the core release to the staging repository
mvn deploy -Pjboss-release -Prelease -DallTests -DskipTests

# Action needed to close the repository
echo ""
echo "=================================================================================================="
echo "Now close the staging repository on Nexus."
echo "DO NOT RELEASE IT! WildFly will be tested with the version in the staging repository"
echo "=================================================================================================="
prompt_confirm "Has the staging repository been closed in Nexus?" || exit 1

# Blow away the wildfly core artifacts and rebuild full.
echo ""
echo "=================================================================================================="
echo "Deleting all wildfly-core artifacts from the local maven repository, and rebuilding full."
echo "=================================================================================================="
rm -rf $HOME/.m2/repository/org/wildfly/core
cd ../wildfly
# Use the staged-releases profile to use the Core release that is deployed in Nexus staging repository
mvn install -DallTests -DskipTests -Pstaged-releases -Dversion.org.wildfly.core=${TO_VERSION}

echo ""
echo "=================================================================================================="
echo "Prepare the next release ${NEXT_VERSION} and push it to ${GITHUB_USER}/${BRANCH_NAME}"
echo "=================================================================================================="
cd ../wildfly-core
# Now replace the versions in the poms for the next release
change_core_version ${TO_VERSION} ${NEXT_VERSION}
git commit -am "Next is ${NEXT_VERSION} release"
git push ${GITHUB_USER} ${BRANCH_NAME}

echo ""
echo "=================================================================================================="
echo "All Done!!! Well, ALMOST...."
echo "=================================================================================================="
echo "See https://developer.jboss.org/wiki/WildFlyCoreReleaseProcess"
echo "1) Push from ${GITHUB_USER_REPO} to the wildfly repository:"
echo "   * the ${TO_VERSION} tag"
echo "       git push upstream ${TO_VERSION}"
echo "   * the ${BRANCH_NAME} branch to wildfly main branch"
echo "       git push upstream ${BRANCH_NAME}:main"
echo "2) Release WildFly Core staging repository in Nexus"
echo "3) Now open a WildFly pull request upgrading the wildfly-core version to ${TO_VERSION}"
echo "4) Cleanup/release JIRA, and add the next fix version"
echo "5) Update the CI jobs"
