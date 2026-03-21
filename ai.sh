#!/bin/bash

OLLAMA_URL="http://localhost:11434"
CONFIG_DIR="$HOME/.config/opencode"

MODELS=(
  "llama3.2:3b|Llama 3.2 3B|2GB|General chat"
  "deepseek-coder:6.7b|DeepSeek Coder 6.7B|4GB|Code generation"
  "qwen2.5-coder:14b|Qwen 2.5 Coder 14B|10GB|Code generation"
  "qwq:32b|QwQ 32B|24GB|Reasoning"
)

list_installed() {
  curl -s "$OLLAMA_URL/api/tags" | grep -o '"name":"[^"]*"' | sed 's/"name":"//;s/"//'
}

pull_model() {
  local model="$1"
  echo "Pulling $model (this may take a while)..."
  curl -s -X POST "$OLLAMA_URL/api/pull" -d "{\"name\":\"$model\"}" &
  echo "Download started in background. Use 'docker logs ai-models' to monitor progress."
}

echo "=== AI Local Ollama ==="
echo ""
for i in "${!MODELS[@]}"; do
  IFS='|' read -r model name size use <<< "${MODELS[$i]}"
  echo "[$((i+1))] $name ($size) - $use"
done
echo ""
echo "[a] Pull all"
echo "[q] Quit"
echo ""

read -p "Select option: " choice

if [[ "$choice" == "q" ]]; then
  exit 0
fi

if [[ "$choice" == "a" ]]; then
  for m in "${MODELS[@]}"; do
    IFS='|' read -r model _ _ _ <<< "$m"
    pull_model "$model"
  done
else
  index=$((choice-1))
  if [[ -n "${MODELS[$index]}" ]]; then
    IFS='|' read -r model _ _ _ <<< "${MODELS[$index]}"
    pull_model "$model"
  else
    echo "Invalid option"
    exit 1
  fi
fi

echo ""
echo "Configuring opencode..."

INSTALLED=$(list_installed)
PULLED_MODELS=""
for m in "${MODELS[@]}"; do
  IFS='|' read -r model name _ _ <<< "$m"
  if echo "$INSTALLED" | grep -q "^$model$"; then
    if [[ -n "$PULLED_MODELS" ]]; then
      PULLED_MODELS="$PULLED_MODELS,\"$model\":{\"name\":\"$name (local)\"}"
    else
      PULLED_MODELS="\"$model\":{\"name\":\"$name (local)\"}"
    fi
  fi
done

mkdir -p "$CONFIG_DIR"

if [[ -f "$CONFIG_DIR/opencode.json" ]]; then
  cp "$CONFIG_DIR/opencode.json" "$CONFIG_DIR/opencode.json.bak"
fi

cat > "$CONFIG_DIR/opencode.json" << EOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        $PULLED_MODELS
      }
    }
  }
}
EOF

echo "opencode.json updated"
echo ""
if [[ -z "$INSTALLED" ]]; then
  echo "No models installed yet. Check 'docker logs ai-models' for download progress."
else
  echo "Installed models: $INSTALLED"
fi
echo "Restart opencode and run /models to see local models."
