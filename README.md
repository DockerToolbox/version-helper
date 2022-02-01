<p align="center">
    <a href="https://github.com/DockerToolbox/">
        <img src="https://cdn.wolfsoftware.com/assets/images/github/organisations/dockertoolbox/black-and-white-circle-256.png" alt="DockerToolbox logo" />
    </a>
    <br />
    <a href="https://github.com/DockerToolbox/version-helper/actions/workflows/ci.yml">
        <img src="https://img.shields.io/github/workflow/status/DockerToolbox/version-helper/ci/master?style=for-the-badge" alt="Github Build Status">
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

It works by starting the required docker container and executing the [version grabber](src/version-grabber.sh) script, which will query the package manager for the selected packages and extract the version numbers.

## Supported Operating Systems

| Operating System | Versions                     | Docker Hub                                             |
| ---------------- | ---------------------------- | ------------------------------------------------------ |
| Alpine           | 3.11, 3.12, 3.13 & 3.14      | [Official Image](https://hub.docker.com/_/alpine)      |
| Amazon Linux     | 1 & 2                        | [Official Image](https://hub.docker.com/_/amazonlinux) |
| Arch Linux       | base                         | [Official Image](https://hub.docker.com/_/archlinux)   |
| Centos           | 7 & 8                        | [Official Image](https://hub.docker.com/_/centos)      |
| Debian           | 9, 10, 11 & 12 (full & slim) | [Official Image](https://hub.docker.com/_/debian)      |
| Oracle Linux     | 6, 7 & 8 (full & slim)       | [Official Image](https://hub.docker.com/_/oraclelinux) |
| Photon           | 1.0, 2.0, 3.0 & 4.0          | [Official Image](https://hub.docker.com/_/photon)      |
| Rocky Linux      | 8                            | [Official Image](https://hub.docker.com/_/rockylinux)  |
| Scientific Linux | 7                            | [Official Image](https://hub.docker.com/_/sl)          |
| Ubuntu           | 14.04, 16.04, 18.04 & 20.04  | [Official Image](https://hub.docker.com/_/ubuntu)      |

## Installation

We recommend copying the [get-versions.sh](src/get-versions.sh) and the [version-grabber.sh](src/version-grabber.sh) into your ~/bin directory so that you can execute them from anywhere.

## Usage

```shell
  Usage: get-versions.sh [ -hd ] [ -p ] [ -c value ] [ -g value ] [ -o value ] [ -s value ] [ -t value ]
    -h | --help     : Print this screen
    -d | --debug    : Enable debugging (set -x)
    -p | --package  : Package list only (No headers or other information)
    -c | --config   : config file name (including path)
    -g | --grabber  : version grabber script (including path) [Default: ~/bin/version-grabber.sh]
    -o | --os       : which operating system to use (docker container)
    -s | --shell    : which shell to use inside the container [Default: bash]
    -t | --tag      : which tag to use [Default: latest]
```

> Unless you have a specific reason to, we suggest you stick to using our supplied [version grabber](src/version-grabber.sh) script. The version grabber needs to be shell agnostic and process each package management output correctly.

### Alpine Latest (example)

```
get-versions.sh -c ../config/config.example -g version-grabber.sh -o alpine -s ash
```
> With Alpine we need to set the shell to ash (alpine doesn't have bash by default)

### Debian stretch (example)

```
get-versions.sh -c ../config/config.example -g version-grabber.sh -o debian -t stretch
```
> The tag names reflect the tags used by the docker container, if you are unsure what tags there are then have a lot of at the relevant contains on [Docker Hub](https://hub.docker.com/).

### What is actually being run ?

The [get-versions](src/get-versions.sh) script takes all of the input from the command line and basically executes the following:

```shell
docker run --rm -v "${GRABBER_SCRIPT}":/version-grabber --env-file="${CONFIG_FILE}" "${OSNAME}":"${TAGNAME}" "${SHELLNAME}" /version-grabber
```

## Packages Configuration

The [packages file](config/config.example) lists all of the packages that you want/need to install during the creation of the containers. This is used to generate the required commands needed to install those packages for any given operating system (that is supported). The code tries to correctly identify the specific version of the package in relation to the specific version of the OS within the container. This might be considered overkill as you could simply install based on the package name but we wanted to go one step further and install the latest specific versioned package.

Configuration can done in one of two ways:

### Package Manager Based

This is the default and the code attempts to work out which package manager is available for a given operating system and then used the correct list of packages.

There are **NO** quotes around the list of packages, this is a `space separated` list of package names. The only exception is `groups` which are a space separated list of quoted strings.

```
APK_PACKAGES=                   # Alpine Packages
APK_VIRTUAL_PACKAGE=            # Alpine Virtual Packages (These are not versioned) 
APT_PACKAGES=                   # Debian / Ubuntu Packages
PACMAN_PACKAGES=                # Arch Linux
TDNF_PACKAGES=                  # Photon Packages
YUM_PACKAGES=                   # Amazon Linux / Centos / Oracle Linux / Rocky Linux / Scientific Linux
YUM_GROUPS=                     # Yum Groups
```
> Oracle Linux 8 slim comes with `microdnf` instead of `yum` but we simply install yum using `microdnf` and then carry on as normal.

### Operating System Based

```
DISCOVER_BY=OS                  # Use Operating System ID instead of package manager
ALPINE_PACKAGES=                # Alpine Packages
ALPINE_VIRTUAL_PACKAGES=        # Alpine Virtual Packages (These are not versioned)
AMAZON_PACKAGES=                # Amazon Linux Packages
AMAZON_GROUPS=                  # Amazon Groups
ARCH_PACKAGES=                  # Arch Linux Packages
CENTOS_PACKAGES=                # Centos Packages
CENTOS_GROUPS=                  # Centos Groups
DEBIAN_PACKAGES=                # Debian Packages
ORACLE_PACKAGES=                # Oracle Linux Packages
ORACLE_GROUPS=                  # Oracle Groups
PHOTON_PACKAGES=                # Photon Linux Packages
ROCKY_PACKAGES=                 # Rocky Linux Packages
ROCKY_GROUPS=                   # Rocky Linux Groups
SCIENTIFIC_PACKAGES=            # Scientific Linux Packages
SCIENTIFIC_GROUPS=              # Scientific Linux Groups
UBUNTU_PACKAGES=                # Ubuntu Packages
```

#### What are Virtual Packages and Groups?

Virtual Packages and Groups are `meta packages` or `packages of packages`, they allow for the simple installation of a collection or group of packages.

Apk based virtual packages are things such as build-dependencies, build-base or linux-headers, and Yum based groups as things like "Development Tools" or "Security Tools".

## Sample output

This is a set of example output using the same [config file](config/config.example) but different operating systems, each time we let the tag default to latest.

One key thing to note is that we do not output RUN before the package installation commands, this is so that the generated commands can be used in a bigger variety of ways.

The output is a [hadolint](https://github.com/CICDToolbox/hadolint) compliant piece of code that you can add directly to your Dockerfile.

> If no version can be found then the package is omitted from the list.

### Alpine

```
apk update && \
apk add --no-cache \
	bash=5.1.4-r0 \
	curl=7.79.1-r0 \
	git=2.32.0-r0 \
	openssl-dev=1.1.1l-r0 \
	wget=1.21.1-r1 \
	&& \
```

### Amazon Linux

```
yum makecache && \
yum install -y \
	bash-4.2.46 \
	curl-7.76.1 \
	git-2.32.0 \
	openssl-devel-1.0.2k \
	wget-1.14 \
	&& \
```

### Arch Linux

```
pacman -Syu --noconfirm && \
pacman -S --noconfirm \
	bash=5.1.008-1 \
	curl=7.79.1-1 \
	git=2.33.1-1 \
	wget=1.21.2-1 \
	&& \
```

### Centos

```
yum makecache && \
yum install -y \
	bash-4.4.19 \
	curl-7.61.1 \
	git-2.27.0 \
	openssl-devel-1.1.1g \
	wget-1.19.5 \
	&& \
```

### Debian

```
apt-get update && \
apt-get -y --no-install-recommends install \
	bash=5.1-2+b3 \
	curl=7.74.0-1.3+b1 \
	git=1:2.30.2-1 \
	libssl-dev=1.1.1k-1+deb11u1 \
	wget=1.21-1+b1 \
	&& \
```

### Oracle Linux (Excluding 8-slim)

```
yum makecache && \
yum install -y \
	bash-4.4.20 \
	curl-7.61.1 \
	git-2.27.0 \
	openssl-devel-1.1.1g \
	wget-1.19.5 \
	&& \
```

### Oracle Linux (8-slim)

```
microdnf update && \
microdnf install yum && \
yum makecache && \
yum install -y \
	bash-4.4.20 \
	curl-7.61.1 \
	git-2.27.0 \
	openssl-devel-1.1.1g \
	wget-1.19.5 \
	&& \
```
> Note the installation of yum via microdnf - this is because 8-slim does not come with yum pre-installed.

### Photon

```
tdnf makecache && \
tdnf install -y \
	bash-5.0 \
	curl-7.78.0 \
	git-2.30.0 \
	wget-1.20.3 \
	&& \
```

### Rocky Linux

```
yum makecache && \
yum install -y \
	bash-4.4.20 \
	curl-7.61.1 \
	git-2.27.0 \
	openssl-devel-1.1.1k \
	wget-1.19.5 \
	&& \
```

### Scientific Linux

```
yum makecache && \
yum install -y \
	bash-4.2.46 \
	curl-7.29.0 \
	git-1.8.3.1 \
	openssl-devel-1.0.2k \
	wget-1.14 \
	&& \
```

### Ubuntu

```
apt-get update && \
apt-get -y --no-install-recommends install \
	bash=5.0-6ubuntu1.1 \
	curl=7.68.0-1ubuntu2.7 \
	git=1:2.25.1-1ubuntu3.2 \
	libssl-dev=1.1.1f-1ubuntu2.8 \
	wget=1.20.3-1ubuntu1 \
	&& \
```
### Comparing different versions of the same operating system

The following is a demonstration of the output from 4 different versions of the same operating system (Ubuntu), just to demonstrate the results.

**Ubuntu 14.04**

```
get-versions.sh -c ../config/config.example -g version-grabber.sh -o ubuntu -t 14.04

apt-get update && \
apt-get -y --no-install-recommends install \
	bash=4.3-7ubuntu1.7 \
	curl=7.35.0-1ubuntu2.20 \
	git=1:1.9.1-1ubuntu0.10 \
	libssl-dev=1.0.1f-1ubuntu2.27 \
	wget=1.15-1ubuntu1.14.04.5 \
	&& \
```

**Ubuntu 16.04**

```
get-versions.sh -c ../config/config.example -g version-grabber.sh -o ubuntu -t 16.04

apt-get update && \
apt-get -y --no-install-recommends install \
	bash=4.3-14ubuntu1.4 \
	curl=7.47.0-1ubuntu2.19 \
	git=1:2.7.4-0ubuntu1.10 \
	libssl-dev=1.0.2g-1ubuntu4.20 \
	wget=1.17.1-1ubuntu1.5 \
	&& \
```

**Ubuntu 18.04**

```
get-versions.sh -c ../config/config.example -g version-grabber.sh -o ubuntu -t 18.04

apt-get update && \
apt-get -y --no-install-recommends install \
	bash=4.4.18-2ubuntu1.2 \
	curl=7.58.0-2ubuntu3.16 \
	git=1:2.17.1-1ubuntu0.9 \
	libssl-dev=1.1.1-1ubuntu2.1~18.04.13 \
	wget=1.19.4-1ubuntu2.2 \
	&& \
```

**Ubuntu 20.04**

```
get-versions.sh -c ../config/config.example -g version-grabber.sh -o ubuntu -t 20.04

apt-get update && \
apt-get -y --no-install-recommends install \
	bash=5.0-6ubuntu1.1 \
	curl=7.68.0-1ubuntu2.7 \
	git=1:2.25.1-1ubuntu3.2 \
	libssl-dev=1.1.1f-1ubuntu2.8 \
	wget=1.20.3-1ubuntu1 \
	&& \
```

It should be very clear to see the different versions for each of the packages.

## Config file

```
APK_PACKAGES=bash curl git openssl-dev wget
APT_PACKAGES=bash curl git libssl-dev wget
PACMAN_PACKAGES=bash curl git libssl-dev wget
TDNF_PACKAGES=bash curl git libssl-dev wget
YUM_PACKAGES=bash curl git openssl-devel wget
```

## Real world usage

We use this tool to maintain all of our own Docker containers and have incorporated it into our [container framework](https://github.com/DockerToolbox/container-framework)

## Caveat

You might find, as we do, that there are subtle differences between difference OSs using the same package manager. I.e. amazon linux and centos, there the former has tar pre-installed but the latter does not.

We get around this by using a super set of packages from across the different OSs, we find this makes little to no difference to the speed of the build or the size of the container because if it is already installed then nothing needs to change during the build.
