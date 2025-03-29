#!/usr/bin/env bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#   @author         :   Chris Burnham
#   @date           :   2024-08-08
#   @description    :   Setup dotfiles
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

# --------------------------------------------------------------------------------------------------
#   @description    :   Startup
# --------------------------------------------------------------------------------------------------
# Enable xtrace if the DEBUG environment variable is set
if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
    set -o xtrace       # Trace the execution of the script (debug)
fi

# Unofficial BASH strict mode when not sourced
if ! (return 0 2> /dev/null); then
    set -o errexit      # Exit on most errors
    set -o pipefail     # Use last non-zero exit code in a pipeline
fi

# Enable errtrace or the error trap handler will not work as expected
set -o errtrace         # Ensure the error trap handler is inherited
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Global Variables
# --------------------------------------------------------------------------------------------------
# Define the required variables
LOG_LEVEL="${LOG_LEVEL:-4}"
NO_COLOR="${NO_COLOR:-}"    # true = disable color, otherwise autodetected

# Dotfiles Repo
GIT_HOST="github.com"
GIT_USER="blthazr"
GIT_URL="https://${GIT_HOST}/${GIT_USER}/"
GIT_REPO="dotfiles"
CODE_REPO=false
CODE_REPO_PATH="~/Code/${GIT_HOST}/${GIT_USER}/${GIT_REPO}"
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Display usage in cli
# --------------------------------------------------------------------------------------------------
function usage() {
  cat << EOF
Usage: ${script_name} [OPTIONS]

Dotfiles Setup

Options:
  -h, --help            show this help message and exit
  -nc, --no-color       don't use colors for logging
  -r, --repository      save repo in ~/Code directory
  -v, --verbose         verbose console logging
EOF
}
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Display script logo
# --------------------------------------------------------------------------------------------------
function display_logo() {
# https://patorjk.com/software/taag/
# Font | Larry 3D
  echo -e "${GREEN}
  __              __         ___          ___
 /\ \            /\ \__    /'___\  __    /\_ \\
 \_\ \     ___   \ \ ,_\  /\ \__/ /\_\   \//\ \       __     ____
 /'_\` \   / __\`\  \ \ \/  \ \ ,__ \\/\ \    \ \ \    /'__\`\  /',__\\
/\ \L\ \ /\ \L\ \  \ \ \_  \ \ \_/ \ \ \    \_\ \_ /\  __/ /\__, \`\\
\ \___,_\\\\\\ \____/   \ \__\  \ \_\   \ \_\   /\____\\\\\\ \____\\\\\\/\____/
 \/__,_ / \/___/     \/__/   \/_/    \/_/   \/____/ \/____/ \/___/
${VIOLET}
          *** This is bootstrap script for my dotfiles ***${WHITE}
                ${GIT_URL}${GIT_REPO}${NOFORMAT}

 " >&1
}
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Console Logging Functions
# --------------------------------------------------------------------------------------------------
function console_log () {
  local log_level="${1}"
  shift

  local param
  while [[ $# -gt 0 ]]; do
    param="$1"
    case $param in
      -category)
        if [[ -n "${2:-}" ]]; then
          local local_log_category="${2}"
          shift
        fi
        ;;
      -icon)
        if [[ -n "${2:-}" ]]; then
          local local_log_category_icon="${2}"
          shift
        fi
        ;;
      *)
        local_positional_param+=("${1}") # save positional parameters
        ;;
    esac
    shift
  done

    # restore positional parameters
  if ! [[ -z ${local_positional_param+x} ]]; then
    set -- "${local_positional_param[@]}"
    unset local_positional_param
  fi

  local_log_category="${local_log_category:-false}"
  local_log_category_icon="${local_log_category_icon:-🌐}"

  # shellcheck disable=SC2034
  local color_debug="\\x1b[34m"
  # shellcheck disable=SC2034
  local color_info="\\x1b[32m"
  # shellcheck disable=SC2034
  local color_warning="\\x1b[33m"
  # shellcheck disable=SC2034
  local color_error="\\x1b[31m"
  # shellcheck disable=SC2034
  local color_critical="\\x1b[1;4;37;41m"

  local colorvar="color_${log_level}"
  local color="${!colorvar:-${color_error}}"
  local color_reset="\\x1b[0m"

  if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]]; } || [[ ! -t 2 ]]; then
    if [[ "${NO_COLOR:-}" != "false" ]]; then
      # Don't use colors on pipes or non-recognized terminals
      color=""; color_reset=""
    fi
  fi

  # all remaining arguments are to be printed
  local log_level_block="${color}$(printf "[%9s]" "${log_level}")${color_reset}"
  local log_line=""

  while IFS=$'\n' read -r log_line; do
    if test "$local_log_category" = false; then
      echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${color}${log_level_block}${color_reset} ${log_line}" 1>&2
    else
      local log_category="$(printf "[${local_log_category_icon}%17s]" "${local_log_category:0:16}")"
      echo -e "$(date -u +"%Y-%m-%d %H:%M:%S UTC") ${log_level_block} ${log_category} ${log_line}" 1>&2
    fi
  done <<< "${@:-}"
}

function debug()    { [[ "${LOG_LEVEL:-0}" -ge 5 ]] && console_log debug "${@}"; true; }
function info()     { [[ "${LOG_LEVEL:-0}" -ge 4 ]] && console_log info "${@}"; true; }
function warning()  { [[ "${LOG_LEVEL:-0}" -ge 3 ]] && console_log warning "${@}"; true; }
function error()    { [[ "${LOG_LEVEL:-0}" -ge 2 ]] && console_log error "${@}"; true; }
function critical() { [[ "${LOG_LEVEL:-0}" -ge 1 ]] && console_log critical "${@}"; exit 1; }
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Verify that a command exists
# --------------------------------------------------------------------------------------------------
function check_command() {
  if [[ $# -lt 1 ]]; then
    critical "Missing required argument for function::check_binary()."
  fi

  if ! command -v "$1" > /dev/null 2>&1; then

    if [[ -n ${2-} ]]; then
      critical "Missing dependency: Could not locate $1." -category "function::check_command"
    else
      debug "Missing dependency: $1." -category "function::check_command"
      return 1
    fi

  fi

  debug "Dependency found: $1" -category "function::check_command"
  return 0
}
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Initialize script constants/variables
# --------------------------------------------------------------------------------------------------
function init() {
  readonly orig_cwd="$PWD"
  readonly script_params="$*"
  readonly script_path="${BASH_SOURCE[0]}"
  script_dir="$(dirname "$script_path")"
  script_name="$(basename "$script_path")"
  readonly script_dir script_name

  # setup colors
  if [[ "${NO_COLOR:-}" = "true" ]] || { [[ "${TERM:-}" != "xterm"* ]] && [[ "${TERM:-}" != "screen"* ]]; } || [[ ! -t 2 ]]; then
    if [[ "${NO_COLOR:-}" != "false" ]]; then
      # Don't use colors on pipes or non-recognized terminals
      NOFORMAT="" RED="" YELLOW="" BLUE="" ORANGE="" GREEN="" VIOLET="" WHITE=""
    fi
  else
    NOFORMAT="\033[0m" RED="\033[0;31m" YELLOW="\033[1;33m" BLUE="\033[0;34m" ORANGE="\033[0;33m" GREEN="\033[0;32m" VIOLET="\033[0;35m" WHITE="\033[97m"
  fi
}
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Parse arguments/parameters passed via cli
# --------------------------------------------------------------------------------------------------
function parse_params() {
  local param
  while [[ $# -gt 0 ]]; do
    param="$1"
    case $param in
      -h | --help)
        usage
        exit 0
        ;;
      -v | --verbose)
        LOG_LEVEL=5
        ;;
      -nc | --no-color)
        NO_COLOR=true
        ;;
      -r | --repository)
        CODE_REPO=true
        ;;
      -*|--*)
        error "unknown parameter \"${param}\""
        usage
        exit 0
        ;;
      *)
        # save positional parameters
        POSITIONAL_PARAM+=("${1}")
        ;;
    esac
    shift
  done

  # restore positional parameters
  if ! [[ -z ${POSITIONAL_PARAM+x} ]]; then
    set -- "${POSITIONAL_PARAM[@]}"
  fi
}
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Preflight Checks
# --------------------------------------------------------------------------------------------------
function preflight_checks() {
  # check for missing variables
  [[ "${LOG_LEVEL:-}" ]] || critical "Cannot continue without LOG_LEVEL."

  # verify OS Type
  case "$OSTYPE" in
    darwin*)
      initialize_macos
      ;;
    # linux*)
    #   initialize_linux
    #   ;;
    *)
      critical "Unsupported OS type: $OSTYPE"
      ;;
  esac
}
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Install MacOS prerequisites
# --------------------------------------------------------------------------------------------------
function initialize_macos() {
  info "Verifying prerequisite applications." -category "MacOS" -icon "🍎"

  # installation | Xcode Command Line Tools
  if ! xcode-select --print-path &>/dev/null; then
    info "Installing Xcode Command Line Tools." -category "xcode-cli"
    xcode-select --install &>/dev/null
  else
    debug "Application is installed." -category "xcode-cli"
  fi

  # installation | Homebrew
  if ! check_command brew; then
    # info "Administrator password needed to install Homebrew" -category "Homebrew" -icon "🍺"
    # verify_sudo

    info "Installing Homebrew, a MacOS package manager. Follow the instructions!" -category "Homebrew" -icon "🍺"
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    cpu_brand_string="$(sysctl -n machdep.cpu.brand_string)"
    if [[ "${cpu_brand_string}" =~ "Apple" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ "${cpu_brand_string}" =~ "Intel" ]]; then
      eval "$(/usr/local/bin/brew shellenv)"
    else
      critical "Unable to install. ${cpu_brand_string} is an unsupported CPU type." -category "Homebrew" -icon "🍺"
    fi

  else
    debug "Application is installed." -category "Homebrew" -icon "🍺"
  fi

  # installation | Chezmoi
  if ! check_command chezmoi; then
    info "Installing Chezmoi, a dotfiles manager." -category "Chezmoi" -icon "🧰"
    brew install chezmoi
  else
    debug "Application is installed." -category "Chezmoi" -icon "🧰"
  fi

  # verification | Xcode Command Line Tools
  debug "Verifying installation of application." -category "xcode-cli"
  if ! xcode-select --print-path &>/dev/null; then
    critical "Xcode Command Line Tools are not installed." -category "xcode-cli"
  fi

  # verification | Homebrew
  debug "Verifying installation of application." -category "Homebrew" -icon "🍺"
  if ! check_command brew; then
    critical "Application is not installed." -category "Homebrew" -icon "🍺"
  fi

  # verification | Chezmoi
  debug "Verifying installation of application." -category "Chezmoi" -icon "🧰"
  if ! check_command chezmoi; then
    critical "Application is not installed." -category "Chezmoi" -icon "🧰"
  fi

  info "Prerequisite applications are installed." -category "MacOS" -icon "🍎"

}
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Install linux prerequesites
#   @globals        :
#   @arguments      :
#   @outputs        :
#   @returns        :
# --------------------------------------------------------------------------------------------------
# function initialize_linux() {

# }
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   Main control function
#   @arguments      :   (optional) Arguments provided to the script
#   @outputs        :   None
# --------------------------------------------------------------------------------------------------
function main() {
  # script initialization
  init "$@"

  # parse parameters
  parse_params "$@"

  # display script logo
  display_logo

  # # perform preflight checks
  # preflight_checks

  # # apply dotfiles
  # info "Applying Chezmoi configuration." -category "Chezmoi" -icon "🧰"
  
  # if [[ "${CODE_REPO:-}" = "true" ]]; then
  #  chezmoi --source ${CODE_REPO_PATH} init "${GIT_URL}${GIT_REPO}" --apply
  # else
  #  chezmoi init "${GIT_URL}${GIT_REPO}" --apply
  # fi

}
# ==================================================================================================


# --------------------------------------------------------------------------------------------------
#   @description    :   call function::main with args if not sourced
# --------------------------------------------------------------------------------------------------
if ! (return 0 2> /dev/null); then
  main "$@"
fi
# ==================================================================================================
