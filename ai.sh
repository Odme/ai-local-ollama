#!/bin/bash
cd "$(dirname "$0")" || exit 1
AI_COMPOSE="docker-compose.yml"

get_models() {
  local flag="$1"
  if [[ "$flag" =~ ^--level=([1-4])$ ]]; then
    level="${BASH_REMATCH[1]}"
    jq -r ".level${level}[] | @sh" models.json 2>/dev/null
  else
    jq -r ".${flag:2} // empty" models.json 2>/dev/null
  fi
}

case "${1:-}" in
  --chat|--code|--arch|--think|--level=*)
    docker compose -f $AI_COMPOSE up -d
    get_models "$1" | while read model; do
      docker compose exec -T ollama ollama pull "$model" >/dev/null 2>&1 && echo "✅ $model"
    done
    echo "🚀 localhost:11434 - $(get_models "$1" | wc -l) models"
    ;;
  --stop) docker compose -f $AI_COMPOSE down && echo "🛑 Off";;
  --status) docker compose -f $AI_COMPOSE ps && docker compose exec ollama ollama list;;
  *) echo "Uso: $0 [--chat|--level=2|--stop]  (lee models.json)";;
esac
