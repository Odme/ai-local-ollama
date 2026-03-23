# AI Local

Run local LLMs with Ollama and use them in opencode.

## Prerequisites

1. **Install Ollama** from https://ollama.com

2. **Start Ollama:**
   ```bash
   ollama serve
   ```

## Installation

```bash
git clone https://github.com/your-repo/ai-local-ollama.git
cd ai-local-ollama
npm install
```

## Usage

```bash
# Load specific models
npx tsx src/index.ts --chat-fast     # Llama 3.2 3B
npx tsx src/index.ts --chat-deep      # Llama 3.1 70B
npx tsx src/index.ts --code-general   # Qwen 2.5 Coder 32B
npx tsx src/index.ts --think          # DeepSeek R1
npx tsx src/index.ts --all            # All models

# Interactive menu
npx tsx src/index.ts
```

## OpenCode Integration

After loading models, the CLI will prompt to configure opencode. Then:
- Restart opencode
- Run `/models`
- Select your local model from "Ollama (local)"

## Alternative: Docker

If you prefer Docker over local installation:

```bash
docker compose up -d
```

Then run the CLI with Docker:
```bash
OLLAMA_CMD="docker exec ai-models ollama" npx tsx src/index.ts --chat-fast
```

## Available Models

| Model | Size | Description |
|-------|------|-------------|
| llama3.2:3b | 2GB | Fast chat |
| llama3.1:70b | 42GB | Complex conversations |
| phi4 | 16GB | Quick code tasks |
| qwen2.5-coder:32b | 20GB | Code generation |
| deepseek-r1:32b | 20GB | Reasoning |
