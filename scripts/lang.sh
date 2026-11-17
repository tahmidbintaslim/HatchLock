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

# lang_disabled <name>: true when the user turned that language off.
# Claude Code exposes the plugin's userConfig value as CLAUDE_PLUGIN_OPTION_<KEY>;
# both key spellings are accepted because the docs do not pin the case.
lang_disabled() {
  local list
  list=$(tr '[:upper:]' '[:lower:]' <<<"${CLAUDE_PLUGIN_OPTION_DISABLED_LANGUAGES:-${CLAUDE_PLUGIN_OPTION_disabled_languages:-}}" | tr -d '[:space:]')
  [[ -n "$1" && ",$list," == *",$1,"* ]]
}
