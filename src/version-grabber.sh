# shellcheck disable=SC2148

# -------------------------------------------------------------------------------- #
# Description                                                                      #
# -------------------------------------------------------------------------------- #
# This script will attempt to get the version information for specific packages.   #
# The aim is to make it work in multiples OSs, Shells and Package managers.        #
#                                                                                  #
# It will display ready to use config that can be added directly into a Dockerfile #
# and meets the current hadolint specifications.                                   #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Global Variables                                                                 #
# -------------------------------------------------------------------------------- #
# Global variables that we use throughout the script.                              #
# -------------------------------------------------------------------------------- #

CRLF='\\\n'
TAB1='\t'
TAB2='\t\t'

# -------------------------------------------------------------------------------- #
# Get apk versions                                                                 #
# -------------------------------------------------------------------------------- #
# Get version information for apk based operating systems.                         #
# -------------------------------------------------------------------------------- #

function get_apk_versions()
{
    local packages="${1:-}"
    local virtual_packages="${2:-}"
    local output=''
    local IFS=' '

    output="${output}${TAB1}apk update && ${CRLF}"
    if [[ -n "${packages}" ]]; then
        output="${output}${TAB1}apk add --no-cache ${CRLF}"

        for package in $packages; do
            version=$(apk policy "${package}" 2>/dev/null | sed -n 2p | sed 's/:$//g' | sed 's/^[[:space:]]*//' || true)
            if [[ -n "${version}" ]]; then
                output="${output}${TAB2}$package=$version ${CRLF}"
            fi
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi

    if [[ -n "${virtual_packages}" ]]; then
        output="${output}${TAB1}apk add --no-cache --virtual ${CRLF}"
        for package in $virtual_packages; do
            output="${output}${TAB2}$package ${CRLF}"
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi
    echo -e "${output}"
}

# -------------------------------------------------------------------------------- #
# Get apt versions                                                                 #
# -------------------------------------------------------------------------------- #
# Get version information for apt based operating systems.                         #
# -------------------------------------------------------------------------------- #

function get_apt_versions()
{
    local packages="${1:-}"
    local output=''
    local IFS=' '

    output="${output}${TAB1}apt-get update && ${CRLF}"

    packages=$(clean_string "${packages}")
    if [[ -n "${packages}" ]]; then
        output="${output}${TAB1}apt-get -y --no-install-recommends install ${CRLF}"

       for package in $packages; do
            version=$(apt-cache policy "${package}" 2>/dev/null | grep 'Candidate:' | awk -F ' ' '{print $2}' || true)
            if [[ -n "${version}" ]]; then
                output="${output}${TAB2}$package=$version ${CRLF}"
            fi
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi
    echo -e "${output}"
}

# -------------------------------------------------------------------------------- #
# Get microdnf versions                                                            #
# -------------------------------------------------------------------------------- #
# Get version information for apt based operating systems.                         #
# -------------------------------------------------------------------------------- #

function get_microdnf_versions()
{
    local packages="${1:-}"
    local group_list="${2:-}"
    local output=''
    local IFS=' '
    local yum_version=''

    yum_version=$(microdnf repoquery yum | tail -n 1)

    output="${output}${TAB1}microdnf -y update && ${CRLF}"
    output="${output}${TAB1}microdnf install -y ${yum_version} && ${CRLF}"
    output="${output}${TAB1}yum makecache && ${CRLF}"

    if [[ -n "${packages}" ]]; then
        output="${output}${TAB1}yum install -y ${CRLF}"

        for package in $packages; do
            version=$(yum info "${package}" 2>/dev/null | grep '^Version' | head -n 1 | awk -F ' : ' '{print $2}' || true)
            if [[ -n "${version}" ]]; then
                output="${output}${TAB2}$package-$version ${CRLF}"
            fi
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi
    if [[ -n "${group_list}" ]]; then
        #
        # We have to do some clever sliting to honour ""
        #
        declare -a "groups=($( echo "$group_list" | sed 's/[][`~!@#$%^&*():;<>.,?/\|{}=+-]/\\&/g' ))"

        output="${output}${TAB1}yum groupinstall -y ${CRLF}"
        # shellcheck disable=SC2154
        for group in "${groups[@]}"; do
            output="${output}${TAB2}\"$group\" ${CRLF}"
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi
    echo -e "${output}"
}

# -------------------------------------------------------------------------------- #
# Get pacman versions                                                              #
# -------------------------------------------------------------------------------- #
# Get version information for pacman based operating systems.                      #
# -------------------------------------------------------------------------------- #

function get_pacman_versions()
{
    local packages="${1:-}"
    local output=''
    local IFS=' '

    output="${output}${TAB1}pacman -Syu --noconfirm && ${CRLF}"
    if [[ -n "${packages}" ]]; then
        output="${output}${TAB1}pacman -S --noconfirm ${CRLF}"

        for package in $packages; do
            version=$(pacman -Si "${package}" 2>/dev/null | grep 'Version' | awk -F ' ' '{print $3}' || true)
            if [[ -n "${version}" ]]; then
                output="${output}${TAB2}$package=$version ${CRLF}"
            fi
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi
    echo -e "${output}"
}

# -------------------------------------------------------------------------------- #
# Get tdnf versions                                                                #
# -------------------------------------------------------------------------------- #
# Get version information for tdnf based operating systems.                        #
# -------------------------------------------------------------------------------- #

function get_tdnf_versions()
{
    local packages="${1:-}"
    local output=''
    local IFS=' '

    output="${output}${TAB1}tdnf makecache && ${CRLF}"
    if [[ -n "${packages}" ]]; then
        output="${output}${TAB1}tdnf install -y ${CRLF}"

        for package in $packages; do
            version=$(tdnf info "${package}" 2>/dev/null | grep '^Version' | head -n 1 | awk -F ' : ' '{print $2}' || true)
            if [[ -n "${version}" ]]; then
                output="${output}${TAB2}$package-$version ${CRLF}"
            fi
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi
    echo -e "${output}"
}

# -------------------------------------------------------------------------------- #
# Get yum versions                                                                 #
# -------------------------------------------------------------------------------- #
# Get version information for yum based operating systems.                         #
# -------------------------------------------------------------------------------- #

function get_yum_versions()
{
    local packages="${1:-}"
    local group_list="${2:-}"
    local output=''
    local IFS=' '

    output="${output}${TAB1}yum makecache && ${CRLF}"
    if [[ -n "${packages}" ]]; then
        output="${output}${TAB1}yum install -y ${CRLF}"

        for package in ${packages}; do
            version=$(yum info "${package}" 2>/dev/null | grep '^Version' | head -n 1 | awk -F ' : ' '{print $2}' || true)
            if [[ -n "${version}" ]]; then
                output="${output}${TAB2}$package-$version ${CRLF}"
            fi
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi

    if [[ -n "${group_list}" ]]; then
        #
        # We have to do some clever sliting to honour ""
        #
        declare -a "groups=($( echo "$group_list" | sed 's/[][`~!@#$%^&*():;<>.,?/\|{}=+-]/\\&/g' ))"

        output="${output}${TAB1}yum groupinstall -y ${CRLF}"
        # shellcheck disable=SC2154
        for group in "${groups[@]}"; do
            output="${output}${TAB2}\"$group\" ${CRLF}"
        done
        output="${output}${TAB2}&& ${CRLF}"
    fi
    echo -e "${output}"
}

# -------------------------------------------------------------------------------- #
# Clean String                                                                     #
# -------------------------------------------------------------------------------- #
# Clean the presented string and remove unwanted characters. [Order IS important!] #
#                                                                                  #
# To ensure that this works in multiple shells we have to avoid using bashisms.    #
#                                                                                  #
# clean="${clean##*( )}"                  # Remove leading spaces                  #
# clean="${clean%%*( )}"                  # Remove trailing spaces                 #
# clean="${clean##+([[:space:]])}"        # globbing to remove repeated whitespace #
# -------------------------------------------------------------------------------- #

function clean_string()
{
    clean="${1:-}"

    # Remove leading and trailing spaces
    clean="$(echo -e "${clean}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Remove leading and trailing "
    clean="$(echo "${clean}" | sed -e 's/^"//' -e 's/"$//')"

    # Remove leading and trailing spaces
    clean="$(echo -e "${clean}" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Remove repeated whitespace
    # shellcheck disable=SC2001
    clean="$(echo "${clean}" | sed -e 's/ \{2,\}/ /g')"

    echo "${clean}"
}

# -------------------------------------------------------------------------------- #
# Identify provider                                                                #
# -------------------------------------------------------------------------------- #
# Identify which package provider the OS is using.                                 #
# -------------------------------------------------------------------------------- #

function detect_distribution
{
    local os_name

    if type "lsb_release" > /dev/null 2>&1; then
        os_name=$(lsb_release -a | grep 'Distributor ID' | awk -F: '{ print $2 }')
    else
        if [[ -f /etc/redhat-release ]]; then
            os_name=$(sed s/\ release.*// < /etc/redhat-release)
        fi

        if [[ -f /etc/os-release ]]; then
            os_name=$(grep '^ID' /etc/os-release | grep -v '^ID_LIKE' | awk -F= '{ print $2 }')
        fi
    fi
    if [[ -z "${os_name}" ]]; then
        os_name="unknown"
    fi
    os_name=$(clean_string "${os_name}")
    echo "${os_name}"
}

# -------------------------------------------------------------------------------- #
# Identify provider                                                                #
# -------------------------------------------------------------------------------- #
# Identify which package provider the OS is using.                                 #
# -------------------------------------------------------------------------------- #

function discover_by_operating_system
{
    local os_name

    os_name=$(detect_distribution)
    case "${os_name}" in
        # Alma Linux (almalinux)
        almalinux)
            get_yum_versions "${ALMA_PACKAGES:-}" "${ALMA_GROUPS:-}"
            ;;
        # Alpine Linux (alpine)
        alpine)
            get_apk_versions "${ALPINE_PACKAGES:-}" "${ALPINE_VIRTUAL_PACKAGES:-}"
            ;;
        # Amazon Linux (amazonlinux)
        amzn)
            get_yum_versions "${AMAZON_PACKAGES:-}" "${AMAZON_GROUPS:-}"
            ;;
        # Arch Linux (archlinux)
        arch)
            get_pacman_versions "${ARCH_PACKAGES:-}"
            ;;
        # Centos (centos)
        centos)
            get_yum_versions "${CENTOS_PACKAGES:-}" "${CENTOS_GROUPS:-}"
            ;;
        # Debian (debian)
        debian)
            get_apt_versions "${DEBIAN_PACKAGES:-}"
            ;;
        # Oracle Linux (oraclelinux)
        ol)
            get_yum_versions "${ORACLE_PACKAGES:-}" "${ORACLE_GROUPS:-}"
            ;;
        # Photon (photon)
        photon)
            get_tdnf_versions "${PHOTON_PACKAGES:-}"
            ;;
        # Rocky Linux (rocky)
        rocky)
            get_yum_versions "${ROCKY_PACKAGES:-}" "${ROCKY_GROUPS:-}"
            ;;
        # Scientific Linux (sl)
        scientific)
            get_yum_versions "${SCIENTIFIC_PACKAGES:-}" "${SCIENTIFIC_GROUPS:-}"
            ;;
        # Ubuntu
        ubuntu)
            get_apt_versions "${UBUNTU_PACKAGES:-}"
            ;;
        *)
            echo "Unknown OS (${os_name})"
    esac
}

# -------------------------------------------------------------------------------- #
# Identify provider                                                                #
# -------------------------------------------------------------------------------- #
# Identify which package provider the OS is using.                                 #
# -------------------------------------------------------------------------------- #

#
# Should we change the order to the most useful ones come first ?? eg tdnf comes with yum  as well 
#
function discover_by_package_manager
{
    if command -v apk > /dev/null; then
        get_apk_versions "${APK_PACKAGES:-}" "${APK_VIRTUAL_PACKAGES:-}"
    elif command -v apt > /dev/null; then
        get_apt_versions "${APT_PACKAGES:-}"
    elif command -v microdnf > /dev/null; then
        get_microdnf_versions "${YUM_PACKAGES:-}" "${YUM_GROUPS:-}"
    elif command -v pacman > /dev/null; then
        get_pacman_versions "${PACMAN_PACKAGES:-}"
    elif command -v tdnf  > /dev/null; then
        get_tdnf_versions "${TDNF_PACKAGES:-}"
    elif command -v yum  > /dev/null; then
        get_yum_versions "${YUM_PACKAGES:-}" "${YUM_GROUPS:-}"
    else
        echo "Unsupport OS type"
    fi
}

# -------------------------------------------------------------------------------- #
# Force Install of Awk                                                             #
# -------------------------------------------------------------------------------- #
# Some of the OS' e.g. Photon do not have aws installed and we need it.            #
# -------------------------------------------------------------------------------- #

function force_update_and_install_of_prereqs
{
    if command -v apk > /dev/null; then
        {
            apk update &&
            apk add gawk
        } > /dev/null 2>&1 || true
    elif command -v apt > /dev/null; then
       {
            apt-get update &&
            apt-get install -y gawk
        } > /dev/null 2>&1 || true
    elif command -v microdnf > /dev/null; then
       {
            microdnf -y update &&
            microdnf install -y yum &&
            yum makecache
        } > /dev/null 2>&1 || true
    elif command -v pacman > /dev/null; then
        {
            pacman -Syu &&
            pacman -S --noconfirm awk
        } > /dev/null 2>&1 || true
    elif command -v tdnf  > /dev/null; then
        {
            tdnf makecache &&
            tdnf install -y gawk
        } > /dev/null 2>&1 || true
    elif command -v yum  > /dev/null; then
        {
            yum makecache &&
            yum install -y awk gawk
        } > /dev/null 2>&1 || true
    else
        echo "Unsupport OS"
        exit
    fi
}

# -------------------------------------------------------------------------------- #
# Set strict mode                                                                  #
# -------------------------------------------------------------------------------- #
# errexit = Any expression that exits with a non-zero exit code terminates         #
# execution of the script, and the exit code of the expression becomes the exit    #
# code of the script.                                                              #
#                                                                                  #
# pipefail = This setting prevents errors in a pipeline from being masked. If any  #
# command in a pipeline fails, that return code will be used as the return code of #
# the whole pipeline. By default, the pipeline's return code is that of the last   #
# command - even if it succeeds.                                                   #
#                                                                                  #
# noclobber = Prevents files from being overwritten when redirected (>|).          #
#                                                                                  #
# nounset = Any reference to any variable that hasn't previously defined, with the #
# exceptions of $* and $@ is an error, and causes the program to immediately exit. #
# -------------------------------------------------------------------------------- #

function set_strict_mode()
{
    set -o errexit -o noclobber -o nounset -o pipefail
    IFS=$'\n\t'
}

# -------------------------------------------------------------------------------- #
# Main()                                                                           #
# -------------------------------------------------------------------------------- #
# The main function where all of the heavy lifting and script config is done.      #
# -------------------------------------------------------------------------------- #

function main
{
    set_strict_mode

    force_update_and_install_of_prereqs

    #
    # Ensuring case-insensitive matching works in any shell - avoid bashisms like ^^
    #
    if [[ -n "${DISCOVER_BY:-}" ]] && echo "${DISCOVER_BY}" | grep -qi '^OS$'; then
        discover_by_operating_system
    else
        discover_by_package_manager
    fi
}

# -------------------------------------------------------------------------------- #
# Main()                                                                           #
# -------------------------------------------------------------------------------- #
# This is the actual 'script' and the functions/sub routines are called in order.  #
# -------------------------------------------------------------------------------- #

main

# -------------------------------------------------------------------------------- #
# End of Script                                                                    #
# -------------------------------------------------------------------------------- #
# This is the end - nothing more to see here.                                      #
# -------------------------------------------------------------------------------- #
