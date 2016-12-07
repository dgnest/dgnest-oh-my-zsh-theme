NEWLINE='
'

# PROMPT
DGNEST_PROMPT_SYMBOL="${DGNEST_PROMPT_SYMBOL:-~>}"
DGNEST_PROMPT_ADD_NEWLINE="${DGNEST_PROMPT_ADD_NEWLINE:-true}"
DGNEST_PROMPT_SEPARATE_LINE="${DGNEST_PROMPT_SEPARATE_LINE:-true}"
DGNEST_PROMPT_TRUNC="${DGNEST_PROMPT_TRUNC:-3}"

# PREFIXES
DGNEST_PREFIX_SHOW="${SPACEHIP_PREFIX_SHOW:-true}"
DGNEST_PREFIX_HOST="${DGNEST_PREFIX_HOST:-" at "}"
DGNEST_PREFIX_DIR="${DGNEST_PREFIX_DIR:-" in "}"
DGNEST_PREFIX_GIT="${DGNEST_PREFIX_GIT:-" on "}"
DGNEST_PREFIX_ENV_DEFAULT="${DGNEST_PREFIX_ENV_DEFAULT:-". "}"
DGNEST_PREFIX_NVM="${DGNEST_PREFIX_NVM:-$DGNEST_PREFIX_ENV_DEFAULT}"
DGNEST_PREFIX_RUBY="${DGNEST_PREFIX_RUBY:-$DGNEST_PREFIX_ENV_DEFAULT}"
DGNEST_PREFIX_SWIFT="${DGNEST_PREFIX_SWIFT:-$DGNEST_PREFIX_ENV_DEFAULT}"
DGNEST_PREFIX_XCODE="${DGNEST_PREFIX_XCODE:-$DGNEST_PREFIX_ENV_DEFAULT}"
DGNEST_PREFIX_VENV="${DGNEST_PREFIX_VENV:-$DGNEST_PREFIX_ENV_DEFAULT}"

# GIT
DGNEST_GIT_SHOW="${DGNEST_GIT_SHOW:-true}"
DGNEST_GIT_UNCOMMITTED="${DGNEST_GIT_UNCOMMITTED:-+}"
DGNEST_GIT_UNSTAGED="${DGNEST_GIT_UNSTAGED:-!}"
DGNEST_GIT_UNTRACKED="${DGNEST_GIT_UNTRACKED:-?}"
DGNEST_GIT_STASHED="${DGNEST_GIT_STASHED:-$}"
DGNEST_GIT_UNPULLED="${DGNEST_GIT_UNPULLED:-⇣}"
DGNEST_GIT_UNPUSHED="${DGNEST_GIT_UNPUSHED:-⇡}"

# NVM
DGNEST_NVM_SHOW="${DGNEST_NVM_SHOW:-true}"
DGNEST_NVM_SYMBOL="${DGNEST_NVM_SYMBOL:-⬢}"

# RUBY
DGNEST_RUBY_SHOW="${DGNEST_RUBY_SHOW:-true}"
DGNEST_RUBY_SYMBOL="${DGNEST_RUBY_SYMBOL:-💎}"

# SWIFT
DGNEST_SWIFT_SHOW_LOCAL="${DGNEST_SWIFT_SHOW_LOCAL:-true}"
DGNEST_SWIFT_SHOW_GLOBAL="${DGNEST_SWIFT_SHOW_GLOBAL:-false}"
DGNEST_SWIFT_SYMBOL="${DGNEST_SWIFT_SYMBOL:-🐦}"

# XCODE
DGNEST_XCODE_SHOW_LOCAL="${DGNEST_XCODE_SHOW_LOCAL:-true}"
DGNEST_XCODE_SHOW_GLOBAL="${DGNEST_XCODE_SHOW_GLOBAL:-false}"
DGNEST_XCODE_SYMBOL="${DGNEST_XCODE_SYMBOL:-🛠}"

# VENV
DGNEST_VENV_SHOW="${DGNEST_VENV_SHOW:-true}"
DGNEST_VENV_SYMBOL="${DGNEST_VENV_SYMBOL:-🐍}"

# VI_MODE
DGNEST_VI_MODE_SHOW="${DGNEST_VI_MODE_SHOW:-true}"
DGNEST_VI_MODE_INSERT="${DGNEST_VI_MODE_INSERT:-[I]}"
DGNEST_VI_MODE_NORMAL="${DGNEST_VI_MODE_NORMAL:-[N]}"

# Username.
# If user is root, then pain it in red. Otherwise, just print in yellow.
dgnest_user() {
  if [[ $USER == 'root' ]]; then
    echo -n "%{$fg_bold[red]%}"
  else
    echo -n "%{$fg_bold[yellow]%}"
  fi
  echo -n "%n"
  echo -n "%{$reset_color%}"
}

# Username and SSH host
# If there is an ssh connections, then show user and current machine.
# If user is not $USER, then show username.
dgnest_host() {
  if [[ -n $SSH_CONNECTION ]]; then
    echo -n "$(dgnest_user)"

    # Do not show directory prefix if prefixes are disabled
    [[ $DGNEST_PREFIX_SHOW == true ]] && echo -n "%B${DGNEST_PREFIX_DIR}%b" || echo -n ' '
    # Display machine name
    echo -n "%{$fg_bold[green]%}%m%{$reset_color%}"
    # Do not show host prefix if prefixes are disabled
    [[ $DGNEST_PREFIX_SHOW == true ]] && echo -n "%B${DGNEST_PREFIX_HOST}%b" || echo -n ' '

  elif [[ $LOGNAME != $USER ]] || [[ $USER == 'root' ]]; then
    echo -n "$(dgnest_user)"

    # Do not show host prefix if prefixes are disabled
    [[ $DGNEST_PREFIX_SHOW == true ]] && echo -n "%B${DGNEST_PREFIX_HOST}%b" || echo -n ' '

    echo -n "%{$reset_color%}"
  fi
}

# Current directory.
# Return only three last items of path
dgnest_current_dir() {
  echo -n "%{$fg_bold[cyan]%}"
  echo -n "%${DGNEST_PROMPT_TRUNC}~";
  echo -n "%{$reset_color%}"
}

# Uncommitted changes.
# Check for uncommitted changes in the index.
dgnest_git_uncomitted() {
  if ! $(git diff --quiet --ignore-submodules --cached); then
    echo -n "${DGNEST_GIT_UNCOMMITTED}"
  fi
}

# Unstaged changes.
# Check for unstaged changes.
dgnest_git_unstaged() {
  if ! $(git diff-files --quiet --ignore-submodules --); then
    echo -n "${DGNEST_GIT_UNSTAGED}"
  fi
}

# Untracked files.
# Check for untracked files.
dgnest_git_untracked() {
  if [ -n "$(git ls-files --others --exclude-standard)" ]; then
    echo -n "${DGNEST_GIT_UNTRACKED}"
  fi
}

# Stashed changes.
# Check for stashed changes.
dgnest_git_stashed() {
  if $(git rev-parse --verify refs/stash &>/dev/null); then
    echo -n "${DGNEST_GIT_STASHED}"
  fi
}

# Unpushed and unpulled commits.
# Get unpushed and unpulled commits from remote and draw arrows.
dgnest_git_unpushed_unpulled() {
  # check if there is an upstream configured for this branch
  command git rev-parse --abbrev-ref @'{u}' &>/dev/null || return

  local count
  count="$(command git rev-list --left-right --count HEAD...@'{u}' 2>/dev/null)"
  # exit if the command failed
  (( !$? )) || return

  # counters are tab-separated, split on tab and store as array
  count=(${(ps:\t:)count})
  local arrows left=${count[1]} right=${count[2]}

  (( ${right:-0} > 0 )) && arrows+="${DGNEST_GIT_UNPULLED}"
  (( ${left:-0} > 0 )) && arrows+="${DGNEST_GIT_UNPUSHED}"

  [ -n $arrows ] && echo -n "${arrows}"
}

# Git status.
# Collect indicators, git branch and pring string.
dgnest_git_status() {
  [[ $DGNEST_GIT_SHOW == false ]] && return

  # Check if the current directory is in a Git repository.
  command git rev-parse --is-inside-work-tree &>/dev/null || return

  # Check if the current directory is in .git before running git checks.
  if [[ "$(git rev-parse --is-inside-git-dir 2> /dev/null)" == 'false' ]]; then
    # Ensure the index is up to date.
    git update-index --really-refresh -q &>/dev/null

    # String of indicators
    local indicators=''

    indicators+="$(dgnest_git_uncomitted)"
    indicators+="$(dgnest_git_unstaged)"
    indicators+="$(dgnest_git_untracked)"
    indicators+="$(dgnest_git_stashed)"
    indicators+="$(dgnest_git_unpushed_unpulled)"

    [ -n "${indicators}" ] && indicators=" [${indicators}]";

    # Do not show git prefix if prefixes are disabled
    [[ $DGNEST_PREFIX_SHOW == true ]] && echo -n "%B${DGNEST_PREFIX_GIT}%b" || echo -n ' '

    echo -n "%{$fg_bold[magenta]%}"
    echo -n "$(git_current_branch)"
    echo -n "%{$reset_color%}"
    echo -n "%{$fg_bold[red]%}"
    echo -n "$indicators"
    echo -n "%{$reset_color%}"
  fi
}

# Virtual environment.
# Show current virtual environment (Python).
dgnest_venv_status() {
  [[ $DGNEST_VENV_SHOW == false ]] && return

  # Check if the current directory running ~> Virtualenv
  if [ -n "$VIRTUAL_ENV" ]; then
	$(type deactivate >/dev/null 2>&1)
	venv_name=$(basename $VIRTUAL_ENV)
  fi

  python_version=$(python -V 2>&1 | grep -Po '(?<=Python )(.+)')

  if [ "${venv_name}" ]; then
	python_version=${python_version}@$(basename $VIRTUAL_ENV)
  fi

  # Do not show venv prefix if prefixes are disabled
  [[ $DGNEST_PREFIX_SHOW == true ]] && echo -n "%B${DGNEST_PREFIX_VENV}%b" || echo -n ' '

  echo -n "%{$fg_bold[green]%}"
  echo -n "${DGNEST_VENV_SYMBOL}‹${python_version}› "
  echo -n "%{$reset_color%}"
}

# NVM
# Show current version of node, exception system.
dgnest_nvm_status() {
  [[ $DGNEST_NVM_SHOW == false ]] && return

  $(type nvm >/dev/null 2>&1) || return

  local nvm_status=$(nvm current 2>/dev/null)
  [[ "${nvm_status}" == "system" ]] && return
  nvm_status=${nvm_status}

  # Do not show NVM prefix if prefixes are disabled
  #[[ ${DGNEST_PREFIX_SHOW} == true ]] && echo -n "%B${DGNEST_PREFIX_NVM}%b" || echo -n ' '

  echo -n "%{$fg_bold[magenta]%}"
  echo -n "${DGNEST_NVM_SYMBOL}‹${nvm_status}› "
  echo -n "%{$reset_color%}"
}

# Ruby
# Show current version of Ruby
dgnest_ruby_version() {
  [[ $DGNEST_RUBY_SHOW == false ]] && return

  rvm_current() {
    rvm current 2>/dev/null
  }
  
  rbenv_version() {
    rbenv version 2>/dev/null | awk '{print $1}'
  }
  
  if [ -e ~/.rvm/bin/rvm-prompt ]; then
    ruby_version=$(rvm_current)
  else
    if which rbenv &> /dev/null; then
      ruby_version=$(rvm_current)
    fi
  fi

  # Do not show ruby prefix if prefixes are disabled
  #[[ $DGNEST_PREFIX_SHOW == true ]] && echo -n "%B${DGNEST_PREFIX_RUBY}%b" || echo -n ' '

  echo -n "%{$fg_bold[red]%}"
  echo -n "${DGNEST_RUBY_SYMBOL}‹${ruby_version}›"
  echo -n "%{$reset_color%}"
}

# Swift
# Show current version of Swift
dgnest_swift_version() {
  command -v swiftenv > /dev/null 2>&1 || return

  if [[ $DGNEST_SWIFT_SHOW_GLOBAL == true ]] ; then
    local swift_version=$(swiftenv version | sed 's/ .*//')
  elif [[ $DGNEST_SWIFT_SHOW_LOCAL == true ]] ; then
    if swiftenv version | grep ".swift-version" > /dev/null; then
      local swift_version=$(swiftenv version | sed 's/ .*//')
    fi
  fi

  if [ -n "${swift_version}" ]; then
    echo -n " %B${DGNEST_PREFIX_SWIFT}%b "
    echo -n "%{$fg_bold[yellow]%}"
    echo -n "${DGNEST_SWIFT_SYMBOL}  ${swift_version}"
    echo -n "%{$reset_color%}"
  fi
}

# Xcode
# Show current version of Xcode
dgnest_xcode_version() {
  command -v xcenv > /dev/null 2>&1 || return

  if [[ $DGNEST_SWIFT_SHOW_GLOBAL == true ]] ; then
    local xcode_path=$(xcenv version | sed 's/ .*//')
  elif [[ $DGNEST_SWIFT_SHOW_LOCAL == true ]] ; then
    if xcenv version | grep ".xcode-version" > /dev/null; then
      local xcode_path=$(xcenv version | sed 's/ .*//')
    fi
  fi

  if [ -n "${xcode_path}" ]; then
    local xcode_version_path=$xcode_path"/Contents/version.plist"
    if [ -f ${xcode_version_path} ]; then
      if command -v defaults > /dev/null 2>&1 ; then
        xcode_version=$(defaults read ${xcode_version_path} CFBundleShortVersionString)
        echo -n " %B${DGNEST_PREFIX_XCODE}%b "
        echo -n "%{$fg_bold[blue]%}"
        echo -n "${DGNEST_XCODE_SYMBOL}  ${xcode_version}"
        echo -n "%{$reset_color%}"
      fi
    fi
  fi
}

# Temporarily switch to vi-mode
dgnest_enable_vi_mode() {
  function zle-keymap-select() { zle reset-prompt; zle -R; };
  zle -N zle-keymap-select;
  bindkey -v;
}

# Show current vi_mode mode
dgnest_vi_mode() {
  if bindkey | grep "vi-quoted-insert" > /dev/null 2>&1; then # check if vi-mode enabled
    echo -n "%{$fg_bold[white]%}"

    MODE_INDICATOR="${DGNEST_VI_MODE_INSERT}"

    case ${KEYMAP} in
      main|viins)
      MODE_INDICATOR="${DGNEST_VI_MODE_INSERT}"
      ;;
      vicmd)
      MODE_INDICATOR="${DGNEST_VI_MODE_NORMAL}"
      ;;
    esac
    echo -n "${MODE_INDICATOR}"
    echo -n "%{$reset_color%} "
  fi
}

# Command prompt.
# Pain $PROMPT_SYMBOL in red if previous command was fail and
# pain in green if all OK.
dgnest_return_status() {
  echo -n "%(?.%{$fg[green]%}.%{$fg[red]%})"
  echo -n "%B${DGNEST_PROMPT_SYMBOL}%b"
  echo    "%{$reset_color%}"
}

# Build prompt line
dgnest_build_top_prompt() {
  dgnest_nvm_status
  dgnest_xcode_version
  dgnest_swift_version
  dgnest_venv_status
}
dgnest_build_prompt() {
  dgnest_host
  dgnest_current_dir
  dgnest_git_status
}

# Build right prompt line
dgnest_build_rprompt() {
  dgnest_ruby_version
}

# Disable python virtualenv environment prompt prefix
VIRTUAL_ENV_DISABLE_PROMPT=true

# Compose PROMPT
PROMPT=''
# Top Prompt.
[[ $DGNEST_PROMPT_ADD_NEWLINE == true ]] && PROMPT="$PROMPT$NEWLINE"
PROMPT="$PROMPT"'$(dgnest_build_top_prompt) '
# Medium Prompt.
[[ $DGNEST_PROMPT_ADD_NEWLINE == true ]] && PROMPT="$PROMPT$NEWLINE"
PROMPT="$PROMPT"'$(dgnest_build_prompt) '

# Prompt.
[[ $DGNEST_PROMPT_SEPARATE_LINE == true ]] && PROMPT="$PROMPT$NEWLINE"
[[ $DGNEST_VI_MODE_SHOW == true ]] && PROMPT="$PROMPT"'$(dgnest_vi_mode)'
PROMPT="$PROMPT"'$(dgnest_return_status) '

# Set PS2 - continuation interactive prompt
PS2="%{$fg_bold[yellow]%}"
PS2+="%{$DGNEST_PROMPT_SYMBOL%} "
PS2+="%{$reset_color%}"

# LSCOLORS
export LSCOLORS="Gxfxcxdxbxegedabagacab"
export LS_COLORS='no=00:fi=00:di=01;34:ln=00;36:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=41;33;01:ex=00;32:ow=0;41:*.cmd=00;32:*.exe=01;32:*.com=01;32:*.bat=01;32:*.btm=01;32:*.dll=01;32:*.tar=00;31:*.tbz=00;31:*.tgz=00;31:*.rpm=00;31:*.deb=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.lzma=00;31:*.zip=00;31:*.zoo=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.tb2=00;31:*.tz2=00;31:*.tbz2=00;31:*.avi=01;35:*.bmp=01;35:*.fli=01;35:*.gif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mng=01;35:*.mov=01;35:*.mpg=01;35:*.pcx=01;35:*.pbm=01;35:*.pgm=01;35:*.png=01;35:*.ppm=01;35:*.tga=01;35:*.tif=01;35:*.xbm=01;35:*.xpm=01;35:*.dl=01;35:*.gl=01;35:*.wmv=01;35:*.aiff=00;32:*.au=00;32:*.mid=00;32:*.mp3=00;32:*.ogg=00;32:*.voc=00;32:*.wav=00;32:*.patch=00;34:*.o=00;32:*.so=01;35:*.ko=01;31:*.la=00;33'
# Zsh to use the same colors as ls
# Link: http://superuser.com/a/707567
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Compose RPROMPT
RPROMPT="$RPROMPT"'$(dgnest_build_rprompt)'
