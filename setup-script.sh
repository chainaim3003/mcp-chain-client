#!/bin/bash

# MCP Chain Client Project Generator
# This script creates a complete project structure for the MCP Chain Client

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_NAME="mcp-chain-client"

echo -e "${BLUE}🚀 MCP Chain Client Project Generator${NC}"
echo "================================================"

# Get project name from user
read -p "Enter project name (default: mcp-chain-client): " input_name
PROJECT_NAME=${input_name:-$PROJECT_NAME}

echo -e "${GREEN}Creating project: ${PROJECT_NAME}${NC}"

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+ first.${NC}"
    exit 1
fi

# Check Node.js version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}❌ Node.js version 18+ is required. Current version: $(node -v)${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js $(node -v) detected${NC}"

# Create project directory
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

echo "📁 Creating project structure..."

# Create directory structure
mkdir -p src/{client,workflows/{examples,templates},servers,cli/commands,monitoring,tests/{unit,integration,fixtures/{mock-servers,test-data}}}
mkdir -p config/{workflows/{examples,templates},environments}
mkdir -p data/{input,output,logs,temp}
mkdir -p docs
mkdir -p scripts
mkdir -p examples/{basic-chain,batch-processing,web-scraping,data-pipeline}

# Create package.json
echo "📦 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "mcp-chain-client",
  "version": "1.0.0",
  "description": "Advanced MCP client for chaining tool calls across multiple servers",
  "main": "dist/index.js",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "dev": "tsx watch src/index.ts",
    "start": "node dist/index.js",
    "test": "vitest",
    "test:unit": "vitest run src/tests/unit",
    "test:integration": "vitest run src/tests/integration",
    "test:coverage": "vitest run --coverage",
    "lint": "eslint src/**/*.ts",
    "lint:fix": "eslint src/**/*.ts --fix",
    "format": "prettier --write src/**/*.ts",
    "cli": "tsx src/cli/index.ts",
    "health-check": "bash scripts/health-check.sh",
    "example:basic": "tsx examples/basic-chain/run.ts",
    "example:batch": "tsx examples/batch-processing/run.ts",
    "example:web": "tsx examples/web-scraping/run.ts",
    "example:pipeline": "tsx examples/data-pipeline/run.ts"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "commander": "^11.0.0",
    "dotenv": "^16.0.0",
    "winston": "^3.10.0",
    "inquirer": "^9.0.0",
    "chalk": "^5.0.0",
    "ora": "^7.0.0",
    "table": "^6.8.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "@types/inquirer": "^9.0.0",
    "@typescript-eslint/eslint-plugin": "^6.0.0",
    "@typescript-eslint/parser": "^6.0.0",
    "eslint": "^8.45.0",
    "prettier": "^3.0.0",
    "tsx": "^4.0.0",
    "typescript": "^5.0.0",
    "vitest": "^0.34.0",
    "@vitest/coverage-v8": "^0.34.0"
  },
  "keywords": [
    "mcp",
    "model-context-protocol",
    "ai",
    "automation",
    "workflow",
    "chain"
  ],
  "author": "Your Name",
  "license": "MIT"
}
EOF

# Create tsconfig.json
echo "🔧 Creating TypeScript configuration..."
cat > tsconfig.json << 'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "node",
    "allowSyntheticDefaultImports": true,
    "esModuleInterop": true,
    "allowJs": true,
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedIndexedAccess": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "removeComments": false,
    "resolveJsonModule": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  },
  "include": [
    "src/**/*"
  ],
  "exclude": [
    "node_modules",
    "dist",
    "**/*.test.ts"
  ]
}
EOF

# Create .env.example
echo "🔐 Creating environment template..."
cat > .env.example << 'EOF'
# MCP Chain Client Configuration

# Server Configuration
MCP_SERVER_TIMEOUT=30000
MCP_MAX_RETRIES=3
MCP_RATE_LIMIT_DELAY=1000

# API Keys
BRAVE_API_KEY=your-brave-api-key-here
OPENAI_API_KEY=your-openai-api-key-here

# Logging
LOG_LEVEL=info
LOG_DIR=./data/logs

# Monitoring
MONITORING_ENABLED=true
METRICS_PORT=3001

# Database
DB_PATH=./data/workflow.db

# Workflow Configuration
WORKFLOW_TIMEOUT=300000
MAX_CONCURRENT_WORKFLOWS=5

# Development
NODE_ENV=development
DEBUG=mcp-chain:*
EOF

# Create .gitignore
echo "📝 Creating .gitignore..."
cat > .gitignore << 'EOF'
# Dependencies
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Build outputs
dist/
build/
*.tsbuildinfo

# Environment files
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Data directories
data/logs/*
data/temp/*
data/output/*
!data/logs/.gitkeep
!data/temp/.gitkeep
!data/output/.gitkeep

# OS files
.DS_Store
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo

# Test coverage
coverage/
.nyc_output/

# Runtime
*.pid
*.seed
*.pid.lock
EOF

# Create main TypeScript files
echo "📄 Creating main source files..."

# src/index.ts
cat > src/index.ts << 'EOF'
#!/usr/bin/env node

import { MCPChainClient } from './client/MCPChainClient.js';
import { loadServerConfig } from './servers/config.js';
import { setupLogger } from './monitoring/logger.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const logger = setupLogger();

async function main() {
  try {
    logger.info('🚀 Starting MCP Chain Client...');
    
    // Load server configuration
    const serverConfig = await loadServerConfig();
    
    // Initialize client
    const client = new MCPChainClient(serverConfig.servers);
    await client.initialize();
    
    logger.info('✅ MCP Chain Client initialized successfully');
    
    // Keep the process running
    process.on('SIGINT', async () => {
      logger.info('🛑 Shutting down...');
      await client.close();
      process.exit(0);
    });
    
  } catch (error) {
    logger.error('❌ Failed to start MCP Chain Client:', error);
    process.exit(1);
  }
}

if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch(console.error);
}
EOF

# src/client/types.ts
cat > src/client/types.ts << 'EOF'
export interface MCPServerConfig {
  name: string;
  command: string;
  args: string[];
  env?: Record<string, string>;
}

export interface ToolCall {
  serverName: string;
  toolName: string;
  arguments: Record<string, any>;
}

export interface WorkflowStep {
  id: string;
  serverName: string;
  toolName: string;
  argumentMapping: (context: WorkflowContext) => Record<string, any>;
  condition?: (context: WorkflowContext) => boolean;
  onSuccess?: string | string[];
  onError?: string;
  retries?: number;
  delay?: number;
}

export interface LoopStep extends WorkflowStep {
  type: 'loop';
  iterations?: number;
  condition: (context: WorkflowContext, iteration: number) => boolean;
  loopBody: string[];
}

export interface ConditionalStep extends WorkflowStep {
  type: 'conditional';
  condition: (context: WorkflowContext) => boolean;
  trueBranch: string[];
  falseBranch?: string[];
}

export interface WorkflowContext {
  results: Map<string, any>;
  iteration: number;
  variables: Map<string, any>;
  errors: Map<string, Error>;
}

export interface Workflow {
  name: string;
  startStep: string;
  steps: Map<string, WorkflowStep | LoopStep | ConditionalStep>;
  globalTimeout?: number;
  maxRetries?: number;
}
EOF

# src/servers/config.ts
cat > src/servers/config.ts << 'EOF'
import { readFile } from 'fs/promises';
import { MCPServerConfig } from '../client/types.js';

export interface ServerConfiguration {
  servers: MCPServerConfig[];
  workflows: Record<string, any>;
  monitoring: {
    enabled: boolean;
    logLevel: string;
  };
}

export async function loadServerConfig(configPath = './config/servers.json'): Promise<ServerConfiguration> {
  try {
    const configContent = await readFile(configPath, 'utf-8');
    return JSON.parse(configContent);
  } catch (error) {
    console.warn('⚠️  Could not load server config, using defaults');
    return {
      servers: [
        {
          name: 'filesystem',
          command: 'npx',
          args: ['-y', '@modelcontextprotocol/server-filesystem', './data'],
          env: {}
        }
      ],
      workflows: {},
      monitoring: {
        enabled: true,
        logLevel: 'info'
      }
    };
  }
}
EOF

# src/monitoring/logger.ts
cat > src/monitoring/logger.ts << 'EOF'
import winston from 'winston';
import path from 'path';

export function setupLogger() {
  const logDir = process.env.LOG_DIR || './data/logs';
  const logLevel = process.env.LOG_LEVEL || 'info';

  return winston.createLogger({
    level: logLevel,
    format: winston.format.combine(
      winston.format.timestamp(),
      winston.format.errors({ stack: true }),
      winston.format.json()
    ),
    transports: [
      new winston.transports.Console({
        format: winston.format.combine(
          winston.format.colorize(),
          winston.format.simple()
        )
      }),
      new winston.transports.File({
        filename: path.join(logDir, 'error.log'),
        level: 'error'
      }),
      new winston.transports.File({
        filename: path.join(logDir, 'combined.log')
      })
    ]
  });
}
EOF

# Create example workflow
cat > examples/basic-chain/run.ts << 'EOF'
import { MCPChainClient } from '../../src/client/MCPChainClient.js';
import { MCPServerConfig } from '../../src/client/types.js';

async function runBasicExample() {
  const serverConfigs: MCPServerConfig[] = [
    {
      name: 'filesystem',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-filesystem', './data'],
    }
  ];

  const client = new MCPChainClient(serverConfigs);

  try {
    await client.initialize();
    
    // Simple file operation
    const result = await client.callTool('filesystem', 'write_file', {
      path: './data/output/hello.txt',
      contents: 'Hello from MCP Chain Client!'
    });
    
    console.log('✅ Basic example completed:', result);
    
  } catch (error) {
    console.error('❌ Example failed:', error);
  } finally {
    await client.close();
  }
}

runBasicExample().catch(console.error);
EOF

# Create scripts
echo "📜 Creating utility scripts..."

# scripts/health-check.sh
cat > scripts/health-check.sh << 'EOF'
#!/bin/bash

echo "🩺 Running health check..."

# Check Node.js
echo "Checking Node.js..."
node --version

# Check dependencies
echo "Checking dependencies..."
npm list --depth=0 > /dev/null

# Check TypeScript compilation
echo "Checking TypeScript compilation..."
npx tsc --noEmit

echo "✅ Health check completed!"
EOF

# scripts/start-dev.sh
cat > scripts/start-dev.sh << 'EOF'
#!/bin/bash

echo "🚀 Starting MCP Chain Client in development mode..."

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ .env file not found. Copying from .env.example..."
    cp .env.example .env
    echo "⚠️  Please update .env file with your configuration"
fi

# Start with hot reload
echo "🔥 Starting with hot reload..."
npm run dev
EOF

# Make scripts executable
chmod +x scripts/*.sh

# Create config files
echo "⚙️  Creating configuration files..."

# config/servers.json
cat > config/servers.json << 'EOF'
{
  "servers": [
    {
      "name": "filesystem",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./data"],
      "env": {}
    }
  ],
  "workflows": {},
  "monitoring": {
    "enabled": true,
    "logLevel": "info"
  }
}
EOF

# Create .gitkeep files for empty directories
touch data/input/.gitkeep
touch data/output/.gitkeep
touch data/logs/.gitkeep
touch data/temp/.gitkeep

# Create README.md
cat > README.md << 'EOF'
# MCP Chain Client

Advanced Model Context Protocol (MCP) client for chaining tool calls across multiple servers with workflow automation.

## Features

- 🔗 Chain tool calls across multiple MCP servers
- 🔄 Complex workflow automation with loops and conditionals
- 📊 Batch processing and rate limiting
- 🔍 Comprehensive monitoring and logging
- 🚀 CLI interface for easy management
- 🧪 Full test suite with examples

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment file
cp .env.example .env

# Build the project
npm run build

# Run health check
npm run health-check

# Start development server
npm run dev

# Run basic example
npm run example:basic
```

## Documentation

- [API Documentation](docs/API.md)
- [Workflow Guide](docs/WORKFLOWS.md)
- [Configuration Guide](docs/CONFIGURATION.md)
- [Examples](docs/EXAMPLES.md)

## Scripts

- `npm run build` - Build TypeScript
- `npm run dev` - Start development with hot reload
- `npm run test` - Run all tests
- `npm run cli` - Interactive CLI
- `npm run health-check` - System health check

## License

MIT
EOF

# Install dependencies
echo "📦 Installing dependencies..."
if command -v npm &> /dev/null; then
    npm install
else
    echo -e "${YELLOW}⚠️  npm not found. Please run 'npm install' manually.${NC}"
fi

# Copy .env file
if [ ! -f .env ]; then
    echo "🔐 Creating environment file..."
    cp .env.example .env
fi

echo ""
echo -e "${GREEN}🎉 Project setup completed successfully!${NC}"
echo ""
echo "Project created in: $(pwd)"
echo ""
echo "Next steps:"
echo "1. cd $PROJECT_NAME"
echo "2. Update .env file with your API keys"
echo "3. npm run dev (start development)"
echo "4. npm run example:basic (test basic functionality)"
echo ""
echo "Available commands:"
echo "- npm run build         # Build the project"
echo "- npm run dev           # Development mode"
echo "- npm run test          # Run tests"
echo "- npm run health-check  # System check"
echo "- npm run cli           # Interactive CLI"
echo ""
echo -e "${BLUE}Happy coding! 🚀${NC}"