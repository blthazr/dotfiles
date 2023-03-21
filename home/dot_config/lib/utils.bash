function check_binary() {
  if [[ $# -lt 1 ]]; then
    fatal "Missing required argument for function check_binary()"
  fi

  if ! command -v "$1" > /dev/null 2>&1; then

    if [[ -n ${2-} ]]; then
      fatal "Missing dependency: Couldn't locate $1."
    else
      debug "Missing dependency: $1"
      return 1
    fi

  fi

  debug "Dependency found: $1"
  return 0
}
