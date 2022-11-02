#!/bin/bash
#
# Terraform wrapper to simplify commonly used commands.

# ---------------------------------------- BEGIN LIBRARY ----------------------------------------- #

source "${BASH_FUNCTION_LIBRARY_SCRIPTS_DIR}/log.sh"

# ----------------------------------------- END LIBRARY ------------------------------------------ #

# ################################################################################################ #

# ------------------------------------ BEGIN GLOBAL VARIABLES ------------------------------------ #

declare SCRIPT_NAME
declare GETOPT_OPTS
declare GETOPT_LONGOPTS
declare GETOPT_PARSED_ARGS
declare -i GETOPT_RETURN_CODE

SCRIPT_NAME="$(basename ${0%.*})"

# ------------------------------------- END GLOBAL VARIABLES ------------------------------------- #

# ################################################################################################ #

# ----------------------------------------- BEGIN CLEAR ------------------------------------------ #

display_tf_clear_usage() {
  cat << EOL
Usage: ${SCRIPT_NAME} clear [DIRECTORIES...] [OPTION...]
Recursively deletes all Terraform cache files. If no directory is
provided, the current directory will be used as starting location.

Options:
  --help    display this usage information.
EOL
}

tf_clear() {
  GETOPT_LONGOPTS="help"
  GETOPT_PARSED_ARGS="$(getopt -n "${SCRIPT_NAME}" -o "${GETOPT_OPTS}" -l "${GETOPT_LONGOPTS}" -- "$@")"
  GETOPT_RETURN_CODE=$?
  if [[ GETOPT_RETURN_CODE -ne 0 ]]; then
    display_tf_clear_usage
    exit 2
  fi

  local -a DIRECTORIES
  local DIRECTORY

  eval set -- "${GETOPT_PARSED_ARGS}"
  while true; do
    case "${1}" in
      "--help")
        display_tf_clear_usage
        return 0
      ;;

      "--")
        shift 1
        DIRECTORIES=("$@")
        shift $#
        break
      ;;
    esac
  done
  
  if [[ ${#DIRECTORIES[@]} -eq 0 ]]; then
    DIRECTORIES=(".")
  fi

  for DIRECTORY in "${DIRECTORIES[@]}"; do
    if [[ "${DIRECTORY}" == "-"* ]]; then
      log --warning "skipping '${DIRECTORY}' ..."
      continue
    fi

    find "${DIRECTORY}" \
      -type "d" \
      -name ".terraform" \
      -prune \
      -exec echo "${SCRIPT_NAME}: removing '{}' ..." \; \
      -exec rm -rf {} \;

    find "${DIRECTORY}" \
      -type "f" \
      \( -name ".terraform.lock.hcl" -o \
        -name "terraform.tfstate" -o \
        -name "terraform.tfstate.backup" \) \
      -exec echo "${SCRIPT_NAME}: removing '{}' ..." \; \
      -delete
  done
}

# ------------------------------------------ END CLEAR ------------------------------------------- #

# ################################################################################################ #

# ------------------------------------------ BEGIN DOCS ------------------------------------------ #

display_tf_docs_usage() {
  cat << EOL
Usage: ${SCRIPT_NAME} clear [DIRECTORIES...] [OPTION...]
Generate README.adoc with Terraform Docs.

Options:
  --help    display this usage information.
EOL
}

tf_docs() {
  GETOPT_LONGOPTS="help"
  GETOPT_PARSED_ARGS="$(getopt -n "${SCRIPT_NAME}" -o "${GETOPT_OPTS}" -l "${GETOPT_LONGOPTS}" -- "$@")"
  GETOPT_RETURN_CODE=$?
  if [[ GETOPT_RETURN_CODE -ne 0 ]]; then
    display_tf_docs_usage
    exit 2
  fi

  eval set -- "${GETOPT_PARSED_ARGS}"
  while true; do
    case "${1}" in
      "--help")
        display_tf_docs_usage
        return 0
      ;;

      "--")
        shift 1
        break
      ;;
    esac
  done
  
  terraform-docs "." --config "docs/.terraform-docs.yml" > "README.adoc"
}

# ------------------------------------------- END DOCS ------------------------------------------- #

# ################################################################################################ #

# ---------------------------------------- BEGIN VALIDATE ---------------------------------------- #

display_tf_validate_usage() {
  cat << EOL
Usage: ${SCRIPT_NAME} clear [DIRECTORIES...] [OPTION...]
Initialize Terraform and validate configuration.

Options:
  --clear    delete all Terraform cache files afterwards.
  --help     display this usage information.
EOL
}

tf_validate() {
  GETOPT_LONGOPTS="clear,help"
  GETOPT_PARSED_ARGS="$(getopt -n "${SCRIPT_NAME}" -o "${GETOPT_OPTS}" -l "${GETOPT_LONGOPTS}" -- "$@")"
  GETOPT_RETURN_CODE=$?
  if [[ GETOPT_RETURN_CODE -ne 0 ]]; then
    display_tf_validate_usage
    exit 2
  fi

  local -i CLEAR

  eval set -- "${GETOPT_PARSED_ARGS}"
  while true; do
    case "${1}" in
      "--clear")
        CLEAR=1
      ;;

      "--help")
        display_tf_validate_usage
        return 0
      ;;

      "--")
        shift 1
        break
      ;;
    esac
  done
  
  terraform init
  terraform validate

  if [[ $CLEAR -eq 1 ]]; then
    rm -rf \
      ".terraform" \
      ".terraform.lock.hcl" \
      "terraform.tfstate" \
      "terraform.tfstate.backup"
  fi
}

# ----------------------------------------- END VALIDATE ----------------------------------------- #

# ################################################################################################ #

# ------------------------------------------ BEGIN MAIN ------------------------------------------ #

display_main_usage() {
  cat << EOL
Usage: ${SCRIPT_NAME} <COMMAND GROUP> [OPTION...]
Terraform wrapper to simplify commonly used commands.

Command groups:
  clear       recursively delete all Terraform cache files.
  docs        generate README.adoc with Terraform Docs.
  validate    initialize Terraform and validate configuration.

Options:
  --help    display this usage information.
EOL
}

main() {
  local COMMAND_GROUP

  COMMAND_GROUP="${1}"
  shift 1

  case "${COMMAND_GROUP}" in
    "clear")
      tf_clear "$@"
    ;;

    "docs")
      tf_docs "$@"
    ;;

    "validate")
      tf_validate "$@"
    ;;

    "--help")
      display_main_usage
      return 0
    ;;

    *)
      display_main_usage
      exit 2
    ;;
  esac
}

# ------------------------------------------- END MAIN ------------------------------------------- #

main "$@"
