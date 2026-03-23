#!/usr/bin/env tsx

import { Command } from 'commander';
import chalk from 'chalk';
import { input } from '@inquirer/prompts';
import { execSync } from 'child_process';

// Configuration
const CONTAINER_NAME = 'ai-models';
const OLLAMA_CMD = `docker exec ${CONTAINER_NAME} ollama`;

// Model definitions
interface Model {
  id: string;
  name: string;
  ollamaTag: string;
  vramGB: number;
  description: string;
}

const MODELS: Record<string, Model> = {
  'chat-fast': {
    id: 'chat-fast',
    name: 'Fast Chat',
    ollamaTag: 'llama3.1:8b-instruct-q8_0',
    vramGB: 9,
    description: 'Llama 3.1 8B - Quick conversations',
  },
  'chat-deep': {
    id: 'chat-deep',
    name: 'Deep Chat',
    ollamaTag: 'llama3.1:70b-instruct-q4_K_M',
    vramGB: 42,
    description: 'Llama 3.1 70B - Complex conversations',
  },
  'code-fast': {
    id: 'code-fast',
    name: 'Fast Code',
    ollamaTag: 'phi4',
    vramGB: 16,
    description: 'Phi-4 - Quick code tasks',
  },
  'code-general': {
    id: 'code-general',
    name: 'General Code',
    ollamaTag: 'qwen2.5-coder:32b-q6_K',
    vramGB: 35,
    description: 'Qwen 2.5 Coder 32B - Serious development',
  },
  'think': {
    id: 'think',
    name: 'Reasoning',
    ollamaTag: 'deepseek-r1:32b',
    vramGB: 28,
    description: 'DeepSeek R1 - Complex reasoning',
  },
};

// Colors
const info = (msg: string) => console.log(chalk.blue('ℹ️  ') + msg);
const success = (msg: string) => console.log(chalk.green('✅ ') + msg);
const warning = (msg: string) => console.log(chalk.yellow('⚠️  ') + msg);
const error = (msg: string) => console.log(chalk.red('❌ ') + msg);

// Utility functions
function checkContainer(): void {
  try {
    const output = execSync('docker ps --format "{{.Names}}"', { encoding: 'utf-8' });
    const containers = output.trim().split('\n');

    if (!containers.includes(CONTAINER_NAME)) {
      error(`Container '${CONTAINER_NAME}' is not running.`);
      info('Start it with: docker-compose up -d');
      process.exit(1);
    }
  } catch {
    error('Failed to check container status. Is Docker running?');
    process.exit(1);
  }
}

function isModelDownloaded(modelTag: string): boolean {
  try {
    const output = execSync(`${OLLAMA_CMD} list`, { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'ignore'] });
    return output.includes(modelTag);
  } catch {
    return false;
  }
}

async function ensureModel(model: Model): Promise<void> {
  if (isModelDownloaded(model.ollamaTag)) {
    success(`${model.name} (${model.ollamaTag}) is already downloaded`);
  } else {
    warning(`Downloading ${model.name}... (this may take a while)`);
    info(`Model: ${model.ollamaTag}`);

    try {
      execSync(`docker exec ${CONTAINER_NAME} ollama pull ${model.ollamaTag}`, {
        stdio: 'inherit',
        env: { ...process.env, FORCE_COLOR: '1' }
      });
      success(`${model.name} downloaded successfully`);
    } catch {
      error(`Failed to download ${model.name}`);
      process.exit(1);
    }
  }
}

async function loadModels(modelIds: string[]): Promise<void> {
  const modelsToLoad = modelIds.map(id => MODELS[id]).filter(Boolean);

  if (modelsToLoad.length === 0) {
    error('No valid models selected');
    return;
  }

  const totalVRAM = modelsToLoad.reduce((sum, m) => sum + m.vramGB, 0);

  console.log('');
  info('Preparing requested models...');
  console.log('');

  for (const model of modelsToLoad) {
    await ensureModel(model);
  }

  console.log('');
  success('Models ready to use');
  console.log('');
  info('You can use them with:');
  console.log(`   docker exec -it ${CONTAINER_NAME} ollama run <model-name>`);
  console.log('');
  info(`Loaded models (${totalVRAM} GB total):`);
  modelsToLoad.forEach(m => {
    console.log(`   • ${m.name} - ${m.description} (~${m.vramGB} GB)`);
  });

  if (totalVRAM > 64) {
    console.log('');
    warning(`⚠️  Total VRAM (${totalVRAM} GB) exceeds your 64 GB. Models may swap to RAM.`);
  }
}

async function showInteractiveMenu(): Promise<void> {
  console.log('');
  console.log(chalk.blue('╔════════════════════════════════════════════╗'));
  console.log(chalk.blue('║   🤖  Select models to load               ║'));
  console.log(chalk.blue('╚════════════════════════════════════════════╝'));
  console.log('');
  console.log('Available options (select multiple with comma):');
  console.log('');

  const modelList = Object.values(MODELS);
  modelList.forEach((m, i) => {
    console.log(`   ${i + 1}. ${m.name.padEnd(20)} (~${m.vramGB} GB) - ${m.description}`);
  });
  console.log(`   ${modelList.length + 1}. All of the above`);
  console.log('   0. Exit');
  console.log('');

  try {
    const selection = await input({
      message: 'Select (e.g., 1,3 or 2,4,5):',
      validate: (input: string) => {
        if (!input.trim()) return 'Please enter a selection';
        const parts = input.split(',').map(s => s.trim());
        const valid = parts.every(p => /^\d+$/.test(p) && parseInt(p) >= 0 && parseInt(p) <= modelList.length + 1);
        return valid ? true : 'Invalid selection. Use numbers separated by comma.';
      },
    });

    const selections = selection.split(',').map(s => parseInt(s.trim()));

    if (selections.includes(0)) {
      info('Exiting...');
      process.exit(0);
    }

    if (selections.includes(modelList.length + 1)) {
      await loadModels(modelList.map(m => m.id));
      return;
    }

    const selectedModels = selections
      .filter(n => n >= 1 && n <= modelList.length)
      .map(n => modelList[n - 1].id);

    if (selectedModels.length === 0) {
      error('No valid models selected');
      process.exit(1);
    }

    await loadModels(selectedModels);
  } catch (err) {
    error('Selection cancelled');
    process.exit(1);
  }
}

// CLI setup
const program = new Command();

program
  .name('ai-local')
  .description('Load Ollama models based on your workflow')
  .version('1.0.0')
  .option('--chat-fast', 'Load fast chat model (Llama 3.1 8B)')
  .option('--chat, --chat-deep', 'Load deep chat model (Llama 3.1 70B)')
  .option('--code-fast', 'Load fast code model (Phi-4)')
  .option('--code, --code-general', 'Load general code model (Qwen 2.5 Coder 32B)')
  .option('--think, --reasoning', 'Load reasoning model (DeepSeek R1)')
  .option('--all', 'Load all models')
  .action(async (options) => {
    checkContainer();

    const modelIds: string[] = [];

    if (options.chatFast) modelIds.push('chat-fast');
    if (options.chat || options.chatDeep) modelIds.push('chat-deep');
    if (options.codeFast) modelIds.push('code-fast');
    if (options.code || options.codeGeneral) modelIds.push('code-general');
    if (options.think || options.reasoning) modelIds.push('think');
    if (options.all) {
      modelIds.push(...Object.keys(MODELS));
    }

    if (modelIds.length === 0) {
      await showInteractiveMenu();
    } else {
      await loadModels(modelIds);
    }
  });

program.parse();
