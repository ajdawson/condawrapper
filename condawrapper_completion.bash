# Bash completion for condawrapper.
#
#| Copyright (c) 2014 Andrew Dawson
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
#   Defines a completion for condawrapper's activate function allowing
#   the use of tab completion for environment names.
#

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
# Find the root environment's Python interpreter.
#
# This is found rather crudely by looking at the '#!' line of the conda
# executable to get the full path to the required Python interpreter.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   The full path to the root environment's Python interpreter, or
#   empty if the root environment cannot be located.
#-----------------------------------------------------------------------
__find_root_python () {
  if __conda_check; then
    head -n 1 $(which conda) | cut -c 3-
  fi
}

#-----------------------------------------------------------------------
# Find the directories containing 
#-----------------------------------------------------------------------
__find_env_dirs () {
  local root_python=$(__find_root_python)
  if [ -z "$root_python" ]; then
    echo "$HOME/envs"
  else
    "$root_python" << EOF
from __future__ import print_function
import sys

try:
    import conda.config
except ImportErrors:
    print("failed to import conda, aborting", file=sys.stderr)
    sys.exit(1)


print(" ".join(conda.config.envs_dirs))
sys.exit(0)
EOF
  fi
}

#-----------------------------------------------------------------------
# Build a list of environment names.
#
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   A list of environment names.
#-----------------------------------------------------------------------
__generate_env_list () {
  local envdir
  for envdir in $(__find_env_dirs); do
    ls -1 "$envdir"
  done
}


#-----------------------------------------------------------------------
# Completion function for condawrapper's activate function.
#
# Globals:
#   COMPREPLY
#   COMP_WORDS
#   COMP_CWORD
# Arguments:
#   None
# Returns:
#   None
#-----------------------------------------------------------------------
_activate () {
  local cur
  local env_list
  COMPREPLY=()
  cur=${COMP_WORDS[COMP_CWORD]}
  case "$cur" in
    *)
      env_list="$(__generate_env_list)"
      COMPREPLY=($(compgen -W "$env_list" -- $cur))
      ;;
  esac
  return 0
}

# Register the completion:
complete -F _activate activate
