// TransportFactory.ts - Fixed Version
// Updated: 2025-05-28 15:56:30 EDT
// Fixes: Environment variable type compatibility with StdioClientTransport
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { SSEClientTransport } from "./SSETransport.js";
export class TransportFactory {
    static create(config) {
        const transportType = config.type || TransportFactory.getDefaultType();
        switch (transportType) {
            case 'stdio':
                // Fix: Properly handle environment variables with undefined values
                const env = {};
                // Add config env vars first
                if (config.env) {
                    Object.assign(env, config.env);
                }
                // Add process env vars, filtering out undefined values
                if (process.env) {
                    for (const [key, value] of Object.entries(process.env)) {
                        if (value !== undefined) {
                            env[key] = value;
                        }
                    }
                }
                return new StdioClientTransport({
                    command: config.command,
                    args: config.args,
                    env: env, // Now properly typed as Record<string, string>
                });
            case 'sse':
                if (!config.url) {
                    throw new Error(`SSE transport requires URL for server ${config.name}`);
                }
                return new SSEClientTransport({
                    url: config.url,
                    serverName: config.name,
                });
            case 'http':
                throw new Error('HTTP transport not yet implemented');
            default:
                throw new Error(`Unsupported transport type: ${transportType}`);
        }
    }
    static getDefaultType() {
        // Auto-detect environment
        if (process.env.VERCEL || process.env.VERCEL_ENV) {
            return 'sse';
        }
        if (process.env.NODE_ENV === 'production' && !process.env.VERCEL) {
            return 'http';
        }
        return 'stdio'; // Default for development
    }
    static getEnvironmentInfo() {
        return {
            isVercel: !!(process.env.VERCEL || process.env.VERCEL_ENV),
            isProduction: process.env.NODE_ENV === 'production',
            isDevelopment: process.env.NODE_ENV === 'development',
            defaultTransport: TransportFactory.getDefaultType(),
            vercelUrl: process.env.VERCEL_URL,
        };
    }
    /**
     * Force a specific transport type (useful for testing)
     */
    static forceTransportType(configs, type) {
        return configs.map(config => ({ ...config, type }));
    }
    /**
     * Validate transport configuration
     */
    static validateConfig(config) {
        if (!config.name) {
            console.error('Transport config missing name');
            return false;
        }
        const type = config.type || TransportFactory.getDefaultType();
        switch (type) {
            case 'stdio':
                if (!config.command || !config.args) {
                    console.error(`Stdio transport requires command and args for ${config.name}`);
                    return false;
                }
                break;
            case 'sse':
                if (!config.url) {
                    console.error(`SSE transport requires URL for ${config.name}`);
                    return false;
                }
                break;
        }
        return true;
    }
}
//# sourceMappingURL=TransportFactory.js.map