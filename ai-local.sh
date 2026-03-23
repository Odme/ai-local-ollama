#!/usr/bin/env bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CONTAINER_NAME="ai-models"
OLLAMA_CMD="docker exec -it $CONTAINER_NAME ollama"

# Available models
MODEL_CHAT_FAST="llama3.1:8b-instruct-q8_0"
MODEL_CHAT_DEEP="llama3.1:70b-instruct-q4_K_M"
MODEL_CODE_FAST="phi4"
MODEL_CODE_GENERAL="qwen2.5-coder:32b-q6_K"
MODEL_THINK="deepseek-r1:32b"

# Function to print messages
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to check if container is running
check_container() {
    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        print_error "Container '$CONTAINER_NAME' is not running."
        print_info "Start it with: docker-compose up -d"
        exit 1
    fi
}

# Function to check if a model is already downloaded
is_model_downloaded() {
    local model=$1
    $OLLAMA_CMD list 2>/dev/null | grep -q "$model"
}

# Function to download model if not exists
ensure_model() {
    local model=$1
    local display_name=$2

    if is_model_downloaded "$model"; then
        print_success "$display_name is already downloaded"
    else
        print_warning "Downloading $display_name... (this may take a while)"
        docker exec $CONTAINER_NAME ollama pull "$model"
        print_success "$display_name downloaded successfully"
    fi
}

# Function to load models based on options
load_models() {
    local models_to_load=()
    local display_names=()

    # Parse arguments
    for arg in "$@"; do
        case $arg in
            --chat-fast)
                models_to_load+=("$MODEL_CHAT_FAST")
                display_names+=("Fast Chat (Llama 3.1 8B)")
                ;;
            --chat|--chat-deep)
                models_to_load+=("$MODEL_CHAT_DEEP")
                display_names+=("Deep Chat (Llama 3.1 70B)")
                ;;
            --code-fast|--simple-code)
                models_to_load+=("$MODEL_CODE_FAST")
                display_names+=("Fast Code (Phi-4)")
                ;;
            --code|--general-code)
                models_to_load+=("$MODEL_CODE_GENERAL")
                display_names+=("General Code (Qwen 2.5 Coder 32B)")
                ;;
            --think|--reasoning)
                models_to_load+=("$MODEL_THINK")
                display_names+=("Reasoning (DeepSeek R1)")
                ;;
            --all)
                models_to_load+=("$MODEL_CHAT_FAST" "$MODEL_CHAT_DEEP" "$MODEL_CODE_FAST" "$MODEL_CODE_GENERAL" "$MODEL_THINK")
                display_names+=("Fast Chat (Llama 3.1 8B)" "Deep Chat (Llama 3.1 70B)" "Fast Code (Phi-4)" "General Code (Qwen 2.5 Coder 32B)" "Reasoning (DeepSeek R1)")
                ;;
            *)
                print_error "Unknown option: $arg"
                show_help
                exit 1
                ;;
        esac
    done

    # If no arguments provided, show interactive menu
    if [ ${#models_to_load[@]} -eq 0 ]; then
        show_interactive_menu
        return
    fi

    # Download and load models
    print_info "Preparing requested models..."
    echo ""

    for i in "${!models_to_load[@]}"; do
        ensure_model "${models_to_load[$i]}" "${display_names[$i]}"
    done

    echo ""
    print_success "✅ Models ready to use"
    echo ""
    print_info "You can use them with:"
    echo "   docker exec -it $CONTAINER_NAME ollama run <model-name>"
    echo ""
    print_info "Loaded models:"
    for name in "${display_names[@]}"; do
        echo "   • $name"
    done
}

# Function to show interactive menu
show_interactive_menu() {
    echo ""
    echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║   🤖  Select models to load               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Available options (separate multiple with comma):"
    echo ""
    echo "   1. Fast Chat              (Llama 3.1 8B)      ~9 GB"
    echo "   2. Deep Chat              (Llama 3.1 70B)     ~42 GB"
    echo "   3. Fast Code              (Phi-4)             ~16 GB"
    echo "   4. General Code           (Qwen 2.5 Coder)    ~35 GB"
    echo "   5. Reasoning              (DeepSeek R1)       ~28 GB"
    echo "   6. All of the above"
    echo "   0. Exit"
    echo ""
    echo -n "Select (e.g., 1,3 or 2,4,5 or 6): "
    read -r selection

    case $selection in
        1)
            load_models --chat-fast
            ;;
        2)
            load_models --chat
            ;;
        3)
            load_models --code-fast
            ;;
        4)
            load_models --code
            ;;
        5)
            load_models --think
            ;;
        6)
            load_models --all
            ;;
        1,3|3,1)
            load_models --chat-fast --code-fast
            ;;
        1,4|4,1)
            load_models --chat-fast --code
            ;;
        1,5|5,1)
            load_models --chat-fast --think
            ;;
        2,3|3,2)
            load_models --chat --code-fast
            ;;
        2,4|4,2)
            load_models --chat --code
            ;;
        2,5|5,2)
            load_models --chat --think
            ;;
        3,4|4,3)
            load_models --code-fast --code
            ;;
        3,5|5,3)
            load_models --code-fast --think
            ;;
        4,5|5,4)
            load_models --code --think
            ;;
        1,3,4|1,4,3|3,1,4|3,4,1|4,1,3|4,3,1)
            load_models --chat-fast --code-fast --code
            ;;
        1,3,5|1,5,3|3,1,5|3,5,1|5,1,3|5,3,1)
            load_models --chat-fast --code-fast --think
            ;;
        1,4,5|1,5,4|4,1,5|4,5,1|5,1,4|5,4,1)
            load_models --chat-fast --code --think
            ;;
        2,3,4|2,4,3|3,2,4|3,4,2|4,2,3|4,3,2)
            load_models --chat --code-fast --code
            ;;
        2,3,5|2,5,3|3,2,5|3,5,2|5,2,3|5,3,2)
            load_models --chat --code-fast --think
            ;;
        2,4,5|2,5,4|4,2,5|4,5,2|5,2,4|5,4,2)
            load_models --chat --code --think
            ;;
        1,2,3,4,5|1,2,3,5,4|1,2,4,3,5|1,2,4,5,3|1,2,5,3,4|1,2,5,4,3|1,3,2,4,5|1,3,2,5,4|1,3,4,2,5|1,3,4,5,2|1,3,5,2,4|1,3,5,4,2|1,4,2,3,5|1,4,2,5,3|1,4,3,2,5|1,4,3,5,2|1,4,5,2,3|1,4,5,3,2|1,5,2,3,4|1,5,2,4,3|1,5,3,2,4|1,5,3,4,2|1,5,4,2,3|1,5,4,3,2|2,1,3,4,5|2,1,3,5,4|2,1,4,3,5|2,1,4,5,3|2,1,5,3,4|2,1,5,4,3|2,3,1,4,5|2,3,1,5,4|2,3,4,1,5|2,3,4,5,1|2,3,5,1,4|2,3,5,4,1|2,4,1,3,5|2,4,1,5,3|2,4,3,1,5|2,4,3,5,1|2,4,5,1,3|2,4,5,3,1|2,5,1,3,4|2,5,1,4,3|2,5,3,1,4|2,5,3,4,1|2,5,4,1,3|2,5,4,3,1|3,1,2,4,5|3,1,2,5,4|3,1,4,2,5|3,1,4,5,2|3,1,5,2,4|3,1,5,4,2|3,2,1,4,5|3,2,1,5,4|3,2,4,1,5|3,2,4,5,1|3,2,5,1,4|3,2,5,4,1|3,4,1,2,5|3,4,1,5,2|3,4,2,1,5|3,4,2,5,1|3,4,5,1,2|3,4,5,2,1|3,5,1,2,4|3,5,1,4,2|3,5,2,1,4|3,5,2,4,1|3,5,4,1,2|3,5,4,2,1|4,1,2,3,5|4,1,2,5,3|4,1,3,2,5|4,1,3,5,2|4,1,5,2,3|4,1,5,3,2|4,2,1,3,5|4,2,1,5,3|4,2,3,1,5|4,2,3,5,1|4,2,5,1,3|4,2,5,3,1|4,3,1,2,5|4,3,1,5,2|4,3,2,1,5|4,3,2,5,1|4,3,5,1,2|4,3,5,2,1|4,5,1,2,3|4,5,1,3,2|4,5,2,1,3|4,5,2,3,1|4,5,3,1,2|4,5,3,2,1|5,1,2,3,4|5,1,2,4,3|5,1,3,2,4|5,1,3,4,2|5,1,4,2,3|5,1,4,3,2|5,2,1,3,4|5,2,1,4,3|5,2,3,1,4|5,2,3,4,1|5,2,4,1,3|5,2,4,3,1|5,3,1,2,4|5,3,1,4,2|5,3,2,1,4|5,3,2,4,1|5,3,4,1,2|5,3,4,2,1)
            load_models --all
            ;;
        0)
            print_info "Exiting..."
            exit 0
            ;;
        *)
            print_error "Invalid option: $selection"
            exit 1
            ;;
    esac
}

# Function to show help
show_help() {
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --chat-fast     Load fast chat model (Llama 3.1 8B, ~9 GB)"
    echo "  --chat          Load deep chat model (Llama 3.1 70B, ~42 GB)"
    echo "  --chat-deep     Same as --chat"
    echo "  --code-fast     Load fast code model (Phi-4, ~16 GB)"
    echo "  --code          Load general code model (Qwen 2.5 Coder 32B, ~35 GB)"
    echo "  --think         Load reasoning model (DeepSeek R1, ~28 GB)"
    echo "  --all           Load all models"
    echo "  (no options)    Show interactive menu"
    echo "  --help          Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 --chat-fast              # Quick chat, low memory"
    echo "  $0 --chat                   # Deep chat for complex conversations"
    echo "  $0 --code --think           # Code + reasoning"
    echo "  $0 --chat-fast --code-fast  # Lightweight combo (~25 GB)"
    echo "  $0 --chat --code --think    # Full power combo (~105 GB, may swap)"
    echo "  $0                          # Interactive menu"
    echo ""
}

# Main
main() {
    check_container

    if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
        show_help
        exit 0
    fi

    load_models "$@"
}

main "$@"
