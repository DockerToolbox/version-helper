<p align="center">
    <a href="https://github.com/DockerToolbox/">
        <img src="https://cdn.wolfsoftware.com/assets/images/github/organisations/dockertoolbox/black-and-white-circle-256.png" alt="DockerToolbox logo" />
    </a>
    <br />
    <a href="https://github.com/DockerToolbox/version-helper/actions/workflows/pipeline.yml">
        <img src="https://img.shields.io/github/workflow/status/DockerToolbox/version-helper/pipeline/master?style=for-the-badge" alt="Github Build Status">
    </a>
    <a href="https://github.com/DockerToolbox/version-helper/releases/latest">
        <img src="https://img.shields.io/github/v/release/DockerToolbox/version-helper?color=blue&label=Latest%20Release&style=for-the-badge" alt="Release">
    </a>
    <a href="https://github.com/DockerToolbox/version-helper/releases/latest">
        <img src="https://img.shields.io/github/commits-since/DockerToolbox/version-helper/latest.svg?color=blue&style=for-the-badge" alt="Commits since release">
    </a>
    <br />
    <a href=".github/CODE_OF_CONDUCT.md">
        <img src="https://img.shields.io/badge/Code%20of%20Conduct-blue?style=for-the-badge" />
    </a>
    <a href=".github/CONTRIBUTING.md">
        <img src="https://img.shields.io/badge/Contributing-blue?style=for-the-badge" />
    </a>
    <a href=".github/SECURITY.md">
        <img src="https://img.shields.io/badge/Report%20Security%20Concern-blue?style=for-the-badge" />
    </a>
    <a href="https://github.com/DockerToolbox/version-helper/issues">
        <img src="https://img.shields.io/badge/Get%20Support-blue?style=for-the-badge" />
    </a>
    <br />
    <a href="https://wolfsoftware.com/">
        <img src="https://img.shields.io/badge/Created%20by%20Wolf%20Software-blue?style=for-the-badge" />
    </a>
</p>

## Overview

When building docker containers it is considered best (or at least good) practice to pin the packages you install to specific versions. Identifying all these versions can be a long, slow and often boring process.

This is a tool to assist in generating a list of packages and their associated versions for use within a Dockerfile.

### How does it work?

It works by starting the required docker container and executing the version-grabber script, which will query the package manager for the selected packages and extract the version numbers.

## Usage

```shell
Usage: get-versions.sh [ -h ] [ -c value ] [ -g value ] [ -o value ] [ -s value ] [ -t value ]
  -h    : Print this screen
  -c    : config file name (including path)
  -g    : version grabber script (including path) [Default: ~/bin/version-grabber.sh]
  -o    : which operating system to use (docker container)
  -s    : which shell to use inside the container [Default: bash]
  -t    : which tag to use [Default: latest]
```

> Unless you have a specific reason to, we suggest you stick to using our supplied [version grabber](src/version-grabber.sh) script. The version grabber needs to be shell agnostic and process each package management output correctly.

## Installation

We recommend copying the [get-versions.sh](src/get-versions.sh) and the [version-grabber.sh](src/version-grabber.sh) into your ~/bin directory so that you can execute them from anywhere.

### Example usage

**Alpine Latest**

```shell
./get-versions.sh -c ../config/config.example -g ./version-grabber.sh -o alpine -s ash
```

> With Alpine we need to set the shell to ash (alpine doesn't have bash by default)

**Debian stretch**

```shell
./get-versions.sh -c ../config/config.example -g ./version-grabber.sh -o debian -t stretch
```

#### Tag Names

The tag names reflect the tags used by the docker container, if you are unsure what tags there are then have a lot of at the relevant contains on [Docker Hub](https://hub.docker.com/).

### What is actaually being run ?

The [get-versions](src/get-versions.sh) script takes all of the input from the command line and basically executes the following:

```shell
docker run --rm -v "${GRABBER_SCRIPT}":/version-grabber --env-file="${CONFIG_FILE}" "${OSNAME}":"${TAGNAME}" "${SHELLNAME}" /version-grabber
```

## Sample output

This is a set of example output using the same [config file](config/config.example) but different operating systems, each time we let the tag default to latest.

> If no version can be found then the package is omitted from the list.

### Alpine

```shell
RUN apk update && \ 
	apk add --no-cache \ 
		bash=5.1.0-r0 \ 
		curl=7.74.0-r0 \ 
		git=2.30.1-r0 \ 
		openssl-dev=1.1.1j-r0 \ 
		wget=1.21.1-r1 \
		&& \
```


### Amazon Linux

```shell
RUN yum makecache && \ 
	yum install -y \ 
		bash-4.2.46 \ 
		curl-7.61.1 \ 
		git-2.23.3 \ 
		openssl-devel-1.0.2k \ 
		wget-1.14 \
		&& \
```

### Centos

```shell
RUN yum makecache && \ 
	yum install -y \ 
		bash-4.4.19 \ 
		curl-7.61.1 \ 
		git-2.27.0 \ 
		openssl-devel-1.1.1g \ 
		wget-1.19.5 \
		&& \
```

### Debian

```shell
RUN apt-get update && \ 
	apt-get -y --no-install-recommends install \ 
		bash=5.0-4 \ 
		curl=7.64.0-4+deb10u1 \ 
		git=1:2.20.1-2+deb10u3 \ 
		libssl-dev=1.1.1d-0+deb10u5 \ 
		wget=1.20.1-1.1 \
		&& \
```

### Ubuntu

```shell
RUN apt-get update && \ 
	apt-get -y --no-install-recommends install \ 
		bash=5.0-6ubuntu1.1 \ 
		curl=7.68.0-1ubuntu2.4 \ 
		git=1:2.25.1-1ubuntu3 \ 
		libssl-dev=1.1.1f-1ubuntu2.2 \ 
		wget=1.20.3-1ubuntu1 \
		&& \
```

The output is a [hadolint](https://github.com/CICDToolbox/hadolint) compliant piece of code that you can add directly to your Dockerfile, it handles the formating of the version as again different OSs require different formats.

#### Comparing different versions of the same operating system

The following is a demonstration of the output from 3 different versions of the same OS, just to demonstrate the results.

**Ubuntu 16.04**

```shell
RUN apt-get update && \ 
	apt-get -y --no-install-recommends install \ 
		bash=4.3-14ubuntu1.4 \ 
		curl=7.47.0-1ubuntu2.18 \ 
		git=1:2.7.4-0ubuntu1.9 \ 
		libssl-dev=1.0.2g-1ubuntu4.19 \ 
		wget=1.17.1-1ubuntu1.5 \
		&& \
```

**Ubuntu 18.04**

```shell
RUN apt-get update && \ 
	apt-get -y --no-install-recommends install \ 
		bash=4.4.18-2ubuntu1.2 \ 
		curl=7.58.0-2ubuntu3.12 \ 
		git=1:2.17.1-1ubuntu0.7 \ 
		libssl-dev=1.1.1-1ubuntu2.1~18.04.8 \ 
		wget=1.19.4-1ubuntu2.2 \
		&& \
```

**Ubuntu 20.04**

```shell
RUN apt-get update && \ 
	apt-get -y --no-install-recommends install \ 
		bash=5.0-6ubuntu1.1 \ 
		curl=7.68.0-1ubuntu2.4 \ 
		git=1:2.25.1-1ubuntu3 \ 
		libssl-dev=1.1.1f-1ubuntu2.2 \ 
		wget=1.20.3-1ubuntu1 \
		&& \
```

It should be very clear to see the different versions for each of the packages.

## Config file

```
APK_PACKAGES=bash curl git openssl-dev wget
APT_PACKAGES=bash curl git libssl-dev wget
YUM_PACKAGES=bash curl git openssl-devel wget
```

> Notice there are NOT quotes around the list of packages!

There are 3 parts to the config file, this is because there are multiple different package management systems in use and different systems name their packages differently.

* APK_PACKAGES - apk specific package names
* APT_PACKAGES - apt specific package names
* YUM_PACKAGES - yum specific package names

## Real world usage

We use this tool to maintain all of our own Docker containers and for each type we build we create a config file and pass this to get_versions.sh

## Caveat

You might find, as we do, that there are subtle differences between difference OSs using the same package manager. I.e. amazon linux and centos, there the former has tar pre-installed but the latter does not.

We get around this by using a super set of packages from across the different OSs, we find this makes little to no difference to the speed of the build or the size of the container because if it is already installed then nothing needs to change during the build.
