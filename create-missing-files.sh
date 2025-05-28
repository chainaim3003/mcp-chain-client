#!/bin/bash

echo "🔧 Creating Missing Source Files for MCP Chain Client"
echo "===================================================="

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p src/client
mkdir -p src/monitoring
mkdir -p src/servers
mkdir -p src/cli
mkdir -p config
mkdir -p data/{input,output,logs,temp}

# Create src/client/types.ts
echo "📄 Creating src/client/types.ts..."
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

# Create src/monitoring/logger.ts
echo "📄 Creating src/monitoring/logger.ts..."
cat > src/monitoring/logger.ts << 'EOF'
import winston from 'winston';
import path from 'path';
import { existsSync, mkdirSync } from 'fs';

export function setupLogger() {
  const logDir = process.env.LOG_DIR || './data/logs';
  const logLevel = process.env.LOG_LEVEL || 'info';

  // Ensure log directory exists
  if (!existsSync(logDir)) {
    mkdirSync(logDir, { recursive: true });
  }

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

# Create src/servers/config.ts
echo "📄 Creating src/servers/config.ts..."
cat > src/servers/config.ts << 'EOF'
import { readFile } from 'fs/promises';
import { existsSync } from 'fs';
import { MCPServerConfig } from '../client/types.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

export interface ExtendedServerConfig extends MCPServerConfig {
  required?: boolean;
  requiresApiKey?: string;
  description?: string;
}

export interface ServerConfiguration {
  servers: ExtendedServerConfig[];
  workflows: Record<string, any>;
  monitoring: {
    enabled: boolean;
    logLevel: string;
  };
}

export async function loadServerConfig(configPath = './config/servers.json'): Promise<ServerConfiguration> {
  try {
    if (!existsSync(configPath)) {
      console.warn(`⚠️  Config file ${configPath} not found, using defaults`);
      return getDefaultConfig();
    }

    const configContent = await readFile(configPath, 'utf-8');
    const config: ServerConfiguration = JSON.parse(configContent);
    
    // Filter servers based on API key availability
    const availableServers = config.servers.filter(server => {
      // Always include required servers (or servers without required flag)
      if (server.required !== false) {
        return true;
      }
      
      // Check if API key is required and available
      if (server.requiresApiKey) {
        const apiKey = process.env[server.requiresApiKey];
        if (!apiKey || apiKey.startsWith('your-') || apiKey === '') {
          console.warn(`⚠️  Skipping ${server.name}: ${server.requiresApiKey} not configured`);
          return false;
        }
        
        // Add API key to server environment
        server.env = {
          ...server.env,
          [server.requiresApiKey]: apiKey
        };
      }
      
      return true;
    });
    
    console.log(`📡 Loading ${availableServers.length}/${config.servers.length} MCP servers`);
    
    return {
      ...config,
      servers: availableServers
    };
    
  } catch (error) {
    console.warn('⚠️  Could not load server config, using defaults:', error);
    return getDefaultConfig();
  }
}

function getDefaultConfig(): ServerConfiguration {
  return {
    servers: [
      {
        name: 'filesystem',
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-filesystem', './data'],
        env: {},
        required: true
      }
    ],
    workflows: {},
    monitoring: {
      enabled: true,
      logLevel: 'info'
    }
  };
}

export function checkApiKeyAvailability(): {
  available: string[];
  missing: string[];
  optional: string[];
} {
  const apiKeys = [
    { name: 'BRAVE_API_KEY', service: 'Brave Search', optional: true },
    { name: 'OPENAI_API_KEY', service: 'OpenAI', optional: true },
    { name: 'GOOGLE_API_KEY', service: 'Google Services', optional: true }
  ];
  
  const available: string[] = [];
  const missing: string[] = [];
  const optional: string[] = [];
  
  apiKeys.forEach(({ name, service, optional: isOptional }) => {
    const value = process.env[name];
    
    if (value && !value.startsWith('your-') && value !== '') {
      available.push(service);
    } else if (isOptional) {
      optional.push(service);
    } else {
      missing.push(service);
    }
  });
  
  return { available, missing, optional };
}
EOF

# Create src/index.ts
echo "📄 Creating src/index.ts..."
cat > src/index.ts << 'EOF'
#!/usr/bin/env node

import { setupLogger } from './monitoring/logger.js';
import { loadServerConfig, checkApiKeyAvailability } from './servers/config.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const logger = setupLogger();

async function main() {
  try {
    logger.info('🚀 Starting MCP Chain Client...');
    
    // Check API key availability
    const apiStatus = checkApiKeyAvailability();
    
    if (apiStatus.available.length > 0) {
      logger.info(`🔑 Available services: ${apiStatus.available.join(', ')}`);
    }
    
    if (apiStatus.optional.length > 0) {
      logger.info(`📝 Optional services (configure API keys to enable): ${apiStatus.optional.join(', ')}`);
    }
    
    if (apiStatus.missing.length > 0) {
      logger.warn(`⚠️  Missing required API keys: ${apiStatus.missing.join(', ')}`);
    }
    
    // Load server configuration
    const serverConfig = await loadServerConfig();
    
    if (serverConfig.servers.length === 0) {
      logger.error('❌ No MCP servers available. Please check your configuration.');
      process.exit(1);
    }
    
    logger.info('✅ MCP Chain Client initialized successfully');
    logger.info(`📡 Available servers: ${serverConfig.servers.map(s => s.name).join(', ')}`);
    
    // Keep the process running
    process.on('SIGINT', async () => {
      logger.info('🛑 Shutting down...');
      process.exit(0);
    });
    
    process.on('SIGTERM', async () => {
      logger.info('🛑 Shutting down...');
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

# Create config/servers.json
echo "📄 Creating config/servers.json..."
cat > config/servers.json << 'EOF'
{
  "servers": [
    {
      "name": "filesystem",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "./data"],
      "env": {},
      "required": true
    },
    {
      "name": "sqlite",
      "command": "npx", 
      "args": ["-y", "@modelcontextprotocol/server-sqlite", "--db-path", "./data/workflow.db"],
      "env": {},
      "required": false
    },
    {
      "name": "brave-search",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"],
      "env": {},
      "required": false,
      "requiresApiKey": "BRAVE_API_KEY",
      "description": "Web search capabilities"
    }
  ],
  "workflows": {},
  "monitoring": {
    "enabled": true,
    "logLevel": "info"
  }
}
EOF

# Create .env if it doesn't exist
if [ ! -f .env ]; then
echo "🔐 Creating .env file..."
cat > .env << 'EOF'
# MCP Chain Client Configuration

# Server Configuration
MCP_SERVER_TIMEOUT=30000
MCP_MAX_RETRIES=3
MCP_RATE_LIMIT_DELAY=1000

# API Keys (Optional - leave empty if not available)
# BRAVE_API_KEY=your-brave-api-key-here
# OPENAI_API_KEY=your-openai-api-key-here
# GOOGLE_API_KEY=your-google-api-key-here

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
fi

# Create .gitkeep files for empty directories
touch data/input/.gitkeep
touch data/output/.gitkeep
touch data/logs/.gitkeep
touch data/temp/.gitkeep

echo ""
echo "✅ All source files created successfully!"
echo ""
echo "Now you can run:"
echo "  npm run build    # Should work now"
echo "  npm run dev      # Start development mode"
echo "  npm start        # Start the application"
echo ""
echo "📁 Created files:"
echo "  ├── src/index.ts"
echo "  ├── src/client/types.ts"
echo "  ├── src/monitoring/logger.ts"
echo "  ├── src/servers/config.ts"
echo "  ├── config/servers.json"
echo "  └── .env (if not exists)"