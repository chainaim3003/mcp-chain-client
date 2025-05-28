import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { SSEClientTransport } from "./SSETransport.js";
import { MCPServerConfig } from "../types.js";
export type TransportType = 'stdio' | 'sse' | 'http';
export interface TransportConfig extends MCPServerConfig {
    type?: TransportType;
    url?: string;
    endpoint?: string;
}
export declare class TransportFactory {
    static create(config: TransportConfig): SSEClientTransport | StdioClientTransport;
    static getDefaultType(): TransportType;
    static getEnvironmentInfo(): {
        isVercel: boolean;
        isProduction: boolean;
        isDevelopment: boolean;
        defaultTransport: TransportType;
        vercelUrl: string | undefined;
    };
    /**
     * Force a specific transport type (useful for testing)
     */
    static forceTransportType(configs: TransportConfig[], type: TransportType): TransportConfig[];
    /**
     * Validate transport configuration
     */
    static validateConfig(config: TransportConfig): boolean;
}
//# sourceMappingURL=TransportFactory.d.ts.map