import { MCPServerConfig } from '../client/types.js';
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
export declare function loadServerConfig(configPath?: string): Promise<ServerConfiguration>;
export declare function checkApiKeyAvailability(): {
    available: string[];
    missing: string[];
    optional: string[];
};
//# sourceMappingURL=config.d.ts.map