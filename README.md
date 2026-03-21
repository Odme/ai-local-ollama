# AI Local Ollama

## Quickstart
```bash
docker compose up -d
./ai.sh
```

## Usage
```bash
./ai.sh              # Select and pull models
opencode -m ollama/<model>  # Use with opencode
```

## Workflow
1. Start Docker: `docker compose up -d`
2. Run `./ai.sh` to select and pull models
3. Use `opencode -m ollama/llama3.2:3b` to chat with a model

## API
Ollama runs on `http://localhost:11434`.
