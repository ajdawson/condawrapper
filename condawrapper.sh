# Wrapper for activating and deactivating conda environments.
#
#| Copyright (c) 2014-2015 Andrew Dawson
#| 
#| Permission is hereby granted, free of charge, to any person obtaining
#| a copy of this software and associated documentation files (the
#| "Software"), to deal in the Software without restriction, including
#| without limitation the rights to use, copy, modify, merge, publish,
#| distribute, sublicense, and/or sell copies of the Software, and to
#| permit persons to whom the Software is furnished to do so, subject to
#| the following conditions:
#| 
#| The above copyright notice and this permission notice shall be
#| included in all copies or substantial portions of the Software.
#| 
#| THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#| EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#| MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
#| NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
#| BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
#| ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
#| CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#| SOFTWARE.
#
# Description:
#   Defines functions to activate and deactivate conda environments with
#   support for running arbitrary hooks before and after these
#   operations. The behaviour is based on virtualenv wrapper, with the
#   philosophy that only one conda environment should be active at any
#   one time.
#
# Notes:
#   This script should be sourced into your running shell, running it in
#   a new shell will do nothing.
#


#=======================================================================
# Constants:
#=======================================================================

# Location of the directory storing configurations:
CONDAWRAPPER_HOME=${CONDAWRAPPER_HOME:-"$HOME/.condawrapper"}


#=======================================================================
# Functions:
#=======================================================================

#-----------------------------------------------------------------------
# Write output to stderr.
#
# Globals:
#   None
# Arguments:
#   Message to write to stderr.
# Returns:
#   None
#-----------------------------------------------------------------------
__err () {
  echo "$@" 1>&2
}

#-----------------------------------------------------------------------
# Check that conda is available in the current shell.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   0 if conda is available, 1 otherwise.
#-----------------------------------------------------------------------
__conda_check () {
  if ! which conda &> /dev/null; then
    return 1
  fi
  return 0
}

#-----------------------------------------------------------------------
# Apply a named hook to an environment.
#
# Globals:
#   CONDAWRAPPER_HOME
# Arguments:
#   env_name
#     Name of an existing conda environment.
#   hook
#     Name of the hook to be run.
# Returns:
#   None
# Exits:
#   0 on success, >0 on failure.
#-----------------------------------------------------------------------
__apply_hook () {
  local env_name="$1"
  local hook="$2"
  local config_dir="$CONDAWRAPPER_HOME/$env_name"
  if [[ -z "$env_name" ]]; then
    __err "error: an environment name is required"
    return 1
  fi
  if [[ -z "$hook" ]]; then
    __err "error: a hook name is required"
    return 2
  fi
  if [[ -s "$config_dir/$hook" ]]; then
    . "$config_dir/$hook"
  fi
  return 0
}

#-----------------------------------------------------------------------
# Activate a conda environment.
#
# Globals:
#   CONDA_DEFAULT_ENV (set by conda)
# Arguments:
#   env_name
#     Name of an existing conda environment.
# Returns:
#   None
# Exits:
#   0 on success, >0 on error.
#-----------------------------------------------------------------------
activate () {
  local env_name="$1"

  # Ensure an environment name is given:
  if [[ $# -ne 1 ]] || [[ -z "$env_name" ]]; then
    __err "usage: activate env_name"
    return 1
  fi

  # Check conda is available on the current path:
  if ! __conda_check; then
    __err "error: conda is not found on your path, aborting"
    return 1
  fi
  
  # Apply pre-activate hooks if defined:
  __apply_hook "$env_name" "preactivate"

  # Activate the specified environment. Check for errors activating, if
  # errors occurred attempt to run the deactivation for the environment
  # to make sure any environment changes applied by the preactivate hook
  # are undone if required:
  source activate "$env_name" 2> /dev/null
  if [[ $? -ne 0 ]]; then
    __err "error: failed to activate environment '$env_name': not found or invalid"
    __apply_hook "$env_name" "predeactivate"
    __apply_hook "$env_name" "postdeactivate"
    return 1
  fi
  
  # Run the remaining hook:
  __apply_hook "$env_name" "postactivate"

  return 0
}

#-----------------------------------------------------------------------
# Deactivate a conda environment.
#
# Globals:
#   CONDA_DEFAULT_ENV (set by conda)
# Arguments:
#   None
# Returns:
#   None
# Exits:
#   0 on success, >0 on failure.
#-----------------------------------------------------------------------
deactivate () {
  local env_name
  local status

  # Check conda is available on the current path:
  if ! __conda_check; then
    __err "error: conda is not found on your path, aborting"
    return 1
  fi

  # Check if an environment is activated, if not exit with an error:
  if [[ -z "$CONDA_DEFAULT_ENV" ]]; then
    __err "error: no environment is activated, deactivation failed"
    return 1
  fi
  
  # Get the environment name:
  env_name="$CONDA_DEFAULT_ENV"
  
  # Apply the pre-deactivation hook:
  __apply_hook "$env_name" "predeactivate"

  # Deactivate the environment:
  source deactivate 2> /dev/null
  status=$?

  # Apply the post-deactivation hook:
  __apply_hook "$env_name" "postdeactivate"

  # Return with the exit status of the deactivation command:
  return $status
}


#-----------------------------------------------------------------------
# Create a new conda environment and activate it.
#
# Globals:
#   CONDAWRAPPER_HOME
# Arguments:
#   env_name
#     Name of the environment.
#   *conda_create_args
#     Any extra arguments that will be passed to conda create.
# Returns:
#   None
# Exits:
#   0 on success, >0 on failure.
#-----------------------------------------------------------------------
mkcondaenv () {
  local env_name
  local env_dir
  local status
  # Store the environment name (first argument) and remove it from the
  # argument list (so we can use $@ to represent the rest).
  env_name="$1"
  shift
  # Create the environment:
  conda create -n "$env_name" $@
  status=$?
  if [ $status -ne 0 ]; then
    __err "error: failed to create the conda environment"
    return $status
  fi
  # Create a condawrapper config for the environment:
  env_dir="$CONDAWRAPPER_HOME/$env_name"
  if ! mkdir $env_dir; then
    __err "error: failed to create condawrapper configuration directory: $env_dir"
    return 1
  fi
  # Activate the new environment:
  if ! activate "$env_name"; then
    __err "error: failed to activate the new environment '${env_name}'"
    return 2
  fi
  return 0
}


#-----------------------------------------------------------------------
# Remove a conda environment.
#
# Globals:
#   CONDAWRAPPER_HOME
# Arguments:
#   env_name
#     Name of the environment.
# Returns:
#   None
# Exits:
#   0 on success, >0 on failure.
#-----------------------------------------------------------------------
rmcondaenv () {
  local env_name
  local env_dir
  local status
  # Store the environment name (first argument):
  env_name="$1"
  # Use conda to remove the environment:
  conda remove -n "$env_name" --all
  status=$?
  if [ $status -ne 0 ]; then
    __err "error: failed to remove the conda environment properly"
    return $status
  fi
  # Remove the condawrapper configuration directory for the environment:
  env_dir="$CONDAWRAPPER_HOME/$env_name"
  if [ -d "$env_dir" ]; then
    rm -rf "$env_dir"
  fi
  return 0
}
