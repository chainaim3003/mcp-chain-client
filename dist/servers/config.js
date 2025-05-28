import { readFile } from 'fs/promises';
import { existsSync } from 'fs';
import dotenv from 'dotenv';
// Load environment variables
dotenv.config();
export async function loadServerConfig(configPath = './config/servers.json') {
    try {
        if (!existsSync(configPath)) {
            console.warn(`⚠️  Config file ${configPath} not found, using defaults`);
            return getDefaultConfig();
        }
        const configContent = await readFile(configPath, 'utf-8');
        const config = JSON.parse(configContent);
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
    }
    catch (error) {
        console.warn('⚠️  Could not load server config, using defaults:', error);
        return getDefaultConfig();
    }
}
function getDefaultConfig() {
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
export function checkApiKeyAvailability() {
    const apiKeys = [
        { name: 'BRAVE_API_KEY', service: 'Brave Search', optional: true },
        { name: 'OPENAI_API_KEY', service: 'OpenAI', optional: true },
        { name: 'GOOGLE_API_KEY', service: 'Google Services', optional: true }
    ];
    const available = [];
    const missing = [];
    const optional = [];
    apiKeys.forEach(({ name, service, optional: isOptional }) => {
        const value = process.env[name];
        if (value && !value.startsWith('your-') && value !== '') {
            available.push(service);
        }
        else if (isOptional) {
            optional.push(service);
        }
        else {
            missing.push(service);
        }
    });
    return { available, missing, optional };
}
//# sourceMappingURL=config.js.map