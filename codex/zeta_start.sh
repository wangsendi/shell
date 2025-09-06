#!/usr/bin/env bash

ZETA_API_KEY=${ZETA_API_KEY:-"sk-1234567890"}

__init() {
  command -v codex 1>&2 || {
    echo "codex is not installed, install it"
    npm install -g @openai/codex
  }
  mkdir -p "$_home"
}

__zeta_config() {
  cat <<EOF >"$_file"
preferred_auth_method = "apikey"

[model_providers.azure]
name = "azure"
base_url = "https://api.zetatechs.com/v1"
wire_api = "chat"
http_headers = { "Authorization" = "Bearer $ZETA_API_KEY" }


[profiles.gpt-5-mini]
model_provider = "azure"
model = "gpt-5-mini-2025-08-07"


[profiles.gpt-5]
model_provider = "azure"
model = "gpt-5"
EOF
}

__main() {

  _file="${HOME}/.config/codex/zeta/config.toml"
  _home="${_file%/*}"
  rm -rf "$_home"
  __init
  __zeta_config
  CODEX_HOME="$_home" codex --ask-for-approval never --sandbox danger-full-access --profile gpt-5
}
__main
