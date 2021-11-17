#!/usr/bin/env bash

# -------------------------------------------------------------------------------- #
# Description                                                                      #
# -------------------------------------------------------------------------------- #
# When building docker containers it is considered best (or at least good)         #
# practice to pin the packages you install to specific versions. Identifying all   #
# these versions can be a long, slow and often boring process.                     #
#                                                                                  #
# This is a tool to assist in generating a list of packages and their associated   #
# versions for use within a Dockerfile.                                            #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Required commands                                                                #
# -------------------------------------------------------------------------------- #
# These commands MUST exist in order for the script to correctly run.              #
# -------------------------------------------------------------------------------- #

PREREQ_COMMANDS=( "docker" )

# -------------------------------------------------------------------------------- #
# Flags                                                                            #
# -------------------------------------------------------------------------------- #
# A set of global flags that we use for configuration.                             #
# -------------------------------------------------------------------------------- #

NO_HEADERS=false                 # Shouold we hide the header / footer?
USE_COLOURS=true                 # Should we use colours in our output ?
FORCE_TERMINAL=true              # Force terminal type if requied
TERMINAL_TYPE=xterm              # What terminal should we force?
WIDTH=128                        # Force terminal width

# -------------------------------------------------------------------------------- #
# The wrapper function                                                             #
# -------------------------------------------------------------------------------- #
# This is where you code goes and is effectively your main() function.             #
# -------------------------------------------------------------------------------- #

function wrapper()
{
    draw_header

    PACKAGES=$(docker run --rm -v "${GRABBER_SCRIPT}":/version-grabber --env-file="${CONFIG_FILE}" "${OSNAME}":"${TAGNAME}" "${SHELLNAME}" /version-grabber)

    echo "${PACKAGES}"

    draw_line
}

# -------------------------------------------------------------------------------- #
# Usage (-h parameter)                                                             #
# -------------------------------------------------------------------------------- #
# This function is used to show the user 'how' to use the script.                  #
# -------------------------------------------------------------------------------- #

function usage()
{
    [[ -n "${*}" ]] && error "  Error: ${*}"

cat <<EOF
  Usage: $0 [ -hd ] [ -p ] [ -c value ] [ -g value ] [ -o value ] [ -s value ] [ -t value ]
    -h | --help     : Print this screen
    -d | --debug    : Enable debugging (set -x)
    -p | --package  : Package list only (No headers or other information)
    -c | --config   : config file name (including path)
    -g | --grabber  : version grabber script (including path) [Default: ~/bin/version-grabber.sh]
    -o | --os       : which operating system to use (docker container)
    -s | --shell    : which shell to use inside the container [Default: bash]
    -t | --tag      : which tag to use [Default: latest]
EOF
    clean_exit 1;
}

# -------------------------------------------------------------------------------- #
# Test Getopt                                                                      #
# -------------------------------------------------------------------------------- #
# Test to ensure we have the GNU getopt available.                                 #
# -------------------------------------------------------------------------------- #

function test_getopt
{
    if getopt --test > /dev/null && true; then
        error "'getopt --test' failed in this environment - Please ensure you are using the gnu getopt."
        if [[ "$(uname -s)" == "Darwin" ]]; then
            error "You are using MAcOS - please ensure you have installed gnu-getopt and updated your path."
        fi
        exit 1
    fi
}

# -------------------------------------------------------------------------------- #
# Process Arguments                                                                #
# -------------------------------------------------------------------------------- #
# This function will process the input from the command line and work out what it  #
# is that the user wants to see.                                                   #
#                                                                                  #
# This is the main processing function where all the processing logic is handled.  #
# -------------------------------------------------------------------------------- #

function process_arguments()
{
    local options
    local longopts
    local error_msg

    if [[ $# -eq 0 ]]; then
        usage
    fi

    test_getopt

    options=hdpc:g:o:s:t:
    longopts=help,debug,package,config:,grabber:,os:,shell:,tag:

    if ! PARSED=$(getopt --options=$options --longoptions=$longopts --name "$0" -- "$@" 2>&1) && true; then
        error_msg=$(echo -e "${PARSED}" | head -n 1 | awk -F ':' '{print $2}')
        usage "${error_msg}"
    fi
    eval set -- "${PARSED}"

    while true; do
        case "${1}" in
            -h|--help)
                usage
                ;;
            -d|--debug)
                set -x
                shift
                ;;
            -p|--package)
                NO_HEADERS=true
                shift
                ;;
            -c|--config)
                CONFIG_FILE=$(realpath "${2}")
                if [[ ! -r "${CONFIG_FILE}" ]]; then
                    error "Cannot read config file: ${CONFIG_FILE}"
                fi
                shift 2
                ;;
            -g|--grabber)
                GRABBER_SCRIPT=$(realpath "${2}")
                if [[ ! -r "${GRABBER_SCRIPT}" ]]; then
                    error "Cannot read grabber script: ${GRABBER_SCRIPT}"
                fi
                shift 2
                ;;
            -o|--os)
                OSNAME=${2}
                shift 2
                ;;
            -s|--shell)
                SHELLNAME=${2}
                shift 2
                ;;
            -t|--tag)
                TAGNAME=${2}
                shift 2
                ;;
            --)
                shift
                break
                ;;
        esac
    done

    [[ -z "${CONFIG_FILE}" ]] && usage
    [[ -z "${GRABBER_SCRIPT}" ]] && GRABBER_SCRIPT="$(realpath ~/bin/version-grabber.sh)"
    [[ -z "${OSNAME}" ]] &&  usage

    SHELLNAME="${SHELLNAME:-bash}"
    TAGNAME="${TAGNAME:-latest}"

    wrapper
    clean_exit
}

# -------------------------------------------------------------------------------- #
# STOP HERE!                                                                       #
# -------------------------------------------------------------------------------- #
# The functions below are part of the template and should not require any changes  #
# in order to make use of this template. If you are going to edit code beyound     #
# this point please ensure you fully understand the impact of those changes!       #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Utiltity Functions                                                               #
# -------------------------------------------------------------------------------- #
# The following functions are all utility functions used within the script but are #
# not specific to the display of the colours and only serve to handle things like, #
# signal handling, user interface and command line option processing.              #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Init Colours                                                                     #
# -------------------------------------------------------------------------------- #
# This function will check to see if we are able to support colours and how many   #
# we are able to support.                                                          #
#                                                                                  #
# The script will give and error and exit if there is no colour support or there   #
# are less than 8 supported colours.                                               #
#                                                                                  #
# Variables intentionally not defined 'local' as we want them to be global.        #
# -------------------------------------------------------------------------------- #

function init_colours()
{
    local ncolors

    fgRed=''
    fgGreen=''
    fgYellow=''
    fgCyan=''
    bold=''
    reset=''

    if [[ "${USE_COLOURS}" = false ]]; then
        return
    fi

    if ! test -t 1; then
        if [[ "${FORCE_TERMINAL}" = true ]]; then
            export TERM=${TERMINAL_TYPE}
        else
            return
        fi
    fi

    if ! tput longname > /dev/null 2>&1; then
        return
    fi

    ncolors=$(tput colors)

    if ! test -n "${ncolors}" || test "${ncolors}" -le 7; then
        return
    fi

    fgRed=$(tput setaf 1)
    fgGreen=$(tput setaf 2)
    fgYellow=$(tput setaf 3)
    fgCyan=$(tput setaf 6)

    bold=$(tput bold)
    reset=$(tput sgr0)
}

# -------------------------------------------------------------------------------- #
# Error                                                                            #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to show something was an error.                        #
# -------------------------------------------------------------------------------- #

function error()
{
    notify 'error' "${@}"
}

# -------------------------------------------------------------------------------- #
# Warning                                                                          #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to show something was a warning.                       #
# -------------------------------------------------------------------------------- #

function warn()
{
    notify 'warning' "${@}"
}

# -------------------------------------------------------------------------------- #
# Success                                                                          #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to show something was a success.                       #
# -------------------------------------------------------------------------------- #

function success()
{
    notify 'success' "${@}"
}

# -------------------------------------------------------------------------------- #
# Info                                                                             #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to show something is information.                      #
# -------------------------------------------------------------------------------- #

function info()
{
    notify 'info' "${@}"
}

# -------------------------------------------------------------------------------- #
# Notify                                                                           #
# -------------------------------------------------------------------------------- #
# Handle all types of notification in one place.                                   #
# -------------------------------------------------------------------------------- #

function notify()
{
    local type="${1:-}"
    shift
    local message="${*:-}"
    local fgColor

    if [[ -n $message ]]; then
        case "${type}" in
            error)
                fgColor="${fgRed}";
                ;;
            warning)
                fgColor="${fgYellow}";
                ;;
            success)
                fgColor="${fgGreen}";
                ;;
            info)
                fgColor="${fgCyan}";
                ;;
            *)
                fgColor='';
                ;;
        esac
        printf '%s%b%s\n' "${fgColor}${bold}" "${message}" "${reset}" 1>&2
    fi
}


# -------------------------------------------------------------------------------- #
# Draw Header                                                                      #
# -------------------------------------------------------------------------------- #
# Draw a nice header if -p has not been passed.                                    #
# -------------------------------------------------------------------------------- #

function draw_header
{
    if [[ "${NO_HEADERS}" = false ]]; then

        local config_string_raw config_string
        config_string_raw="Config File: $(basename "${CONFIG_FILE}")  Grabber Script: $(basename "${GRABBER_SCRIPT}")  Docker Container: ${OSNAME}:${TAGNAME}  Shell: ${SHELLNAME}"
        config_string="${fgGreen}Config File:${reset} $(basename "${CONFIG_FILE}")  ${fgGreen}Grabber Script:${reset} $(basename "${GRABBER_SCRIPT}")  ${fgGreen}Docker Container:${reset} ${OSNAME}:${TAGNAME}  ${fgGreen}Shell:${reset} ${SHELLNAME}"

        draw_line
        center_text "Package version grabber by Wolf Software Limited"
        draw_line
        center_text "${config_string}" "${#config_string_raw}"
        draw_line
    fi
}

# -------------------------------------------------------------------------------- #
# abs                                                                              #
# -------------------------------------------------------------------------------- #
# Return the absolute value for a given number.                                    #
# -------------------------------------------------------------------------------- #

function abs()
{
    (( $1 < 0 )) && echo "$(( $1 * -1 ))" || echo "$1"
}

# -------------------------------------------------------------------------------- #
# Center Text                                                                      #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to some text centered on the screen.                   #
# -------------------------------------------------------------------------------- #

function center_text()
{
    if [[ -n ${2:-} ]]; then
        textsize=${2}
        extra=$(abs "$(( textsize - ${#1} ))")
    else
        textsize=${#1}
        extra=0
    fi
    span=$(( ( (WIDTH + textsize) / 2) + extra ))

    printf '%*s\n' "${span}" "$1"
}

# -------------------------------------------------------------------------------- #
# Draw Line                                                                        #
# -------------------------------------------------------------------------------- #
# A simple wrapper function to draw a line on the screen.                          #
# -------------------------------------------------------------------------------- #

function draw_line()
{
    if [[ "${NO_HEADERS}" = false ]]; then

        local start=$'\e(0' end=$'\e(B' line='qqqqqqqqqqqqqqqq'

        while ((${#line} < "${WIDTH}"));
        do
            line+="$line";
        done
        printf '%s%s%s\n' "$start" "${line:0:WIDTH}" "$end"
    fi
}


# -------------------------------------------------------------------------------- #
# Check Prerequisites                                                              #
# -------------------------------------------------------------------------------- #
# Check to ensure that the prerequisite commmands exist.                           #
# -------------------------------------------------------------------------------- #

function check_prereqs()
{
    local error_count=0

    for i in "${PREREQ_COMMANDS[@]}"
    do
        command=$(command -v "${i}" || true)
        if [[ -z $command ]]; then
            warning "$i is not in your command path"
            error_count=$((error_count+1))
        fi
    done

    if [[ $error_count -gt 0 ]]; then
        error "$error_count errors located - fix before re-running";
        clean_exit 1;
    fi
}

# -------------------------------------------------------------------------------- #
# Clean Exit                                                                       #
# -------------------------------------------------------------------------------- #
# Unset the traps and exit cleanly, with an optional exit code / message.          #
# -------------------------------------------------------------------------------- #

function clean_exit()
{
    [[ -n ${2:-} ]] && error "${2}"
    
    exit "${1:-0}"
}

# -------------------------------------------------------------------------------- #
# Enable strict mode                                                               #
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

function main()
{
    set_strict_mode
    init_colours
    check_prereqs
    process_arguments "${@}"
}

# -------------------------------------------------------------------------------- #
# Main()                                                                           #
# -------------------------------------------------------------------------------- #
# This is the actual 'script' and the functions/sub routines are called in order.  #
# -------------------------------------------------------------------------------- #

main "${@}"

# -------------------------------------------------------------------------------- #
# End of Script                                                                    #
# -------------------------------------------------------------------------------- #
# This is the end - nothing more to see here.                                      #
# -------------------------------------------------------------------------------- #
