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
