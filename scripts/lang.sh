# shellcheck shell=bash
# Shared by the hook scripts (sourced, not executed).

# lang_of <path>: language name for a file, matching the names users list in
# the "Disabled languages" setting. Prints nothing for unknown extensions.
lang_of() {
  case "$(tr '[:upper:]' '[:lower:]' <<<"${1##*.}")" in
    ts|tsx|js|jsx|mjs|cjs|vue) echo typescript ;;
    py|pyi|ipynb) echo python ;;
    rs) echo rust ;;
    go) echo go ;;
    c|cpp|cc|h|hpp) echo cpp ;;
    zig) echo zig ;;
    java) echo java ;;
    cs) echo csharp ;;
    php) echo php ;;
    rb) echo ruby ;;
    ex|exs) echo elixir ;;
    swift) echo swift ;;
    kt|kts) echo kotlin ;;
    dart) echo dart ;;
    lua) echo lua ;;
    sh|bash|zsh) echo shell ;;
    tf|tfvars) echo terraform ;;
    r) echo r ;;
  esac
}

# disabled_languages: the user's comma-separated opt-out list. HATCHLOCK_DISABLED_LANGUAGES
# (set in settings.json "env") is the setting; CLAUDE_PLUGIN_OPTION_* is the pre-1.2 userConfig
# value, still honoured for anyone who saved it.
disabled_languages() {
  printf '%s' "${HATCHLOCK_DISABLED_LANGUAGES:-${CLAUDE_PLUGIN_OPTION_DISABLED_LANGUAGES:-${CLAUDE_PLUGIN_OPTION_disabled_languages:-}}}"
}

# lang_disabled <name>: true when the user turned that language off.
lang_disabled() {
  local list
  list=$(disabled_languages | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')
  [[ -n "$1" && ",$list," == *",$1,"* ]]
}
