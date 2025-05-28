import { Transport } from "@modelcontextprotocol/sdk/shared/transport.js";
import { JSONRPCMessage } from "@modelcontextprotocol/sdk/types.js";
export interface SSETransportOptions {
    url: string;
    serverName: string;
    reconnectDelay?: number;
    timeout?: number;
}
export declare class SSEClientTransport implements Transport {
    private options;
    private eventSource;
    private responseHandlers;
    private isConnected;
    private connectionId;
    constructor(options: SSETransportOptions);
    start(): Promise<void>;
    close(): Promise<void>;
    send(message: JSONRPCMessage): Promise<void>;
    /**
     * Safely get message type from JSONRPCMessage
     */
    private getMessageType;
    /**
     * Set up a response handler for a request (doesn't block send method)
     */
    private setupResponseHandler;
    private handleMessage;
    private handleReconnection;
    /**
     * Fallback implementation for Node.js environments without EventSource
     */
    private startWithFetch;
    /**
     * Get connection status
     */
    isConnectionActive(): boolean;
    /**
     * Get server name
     */
    getServerName(): string;
    /**
     * Get connection ID
     */
    getConnectionId(): string | null;
    /**
     * Get pending requests count
     */
    getPendingRequestsCount(): number;
}
//# sourceMappingURL=SSETransport.d.ts.map