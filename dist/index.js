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
    }
    catch (error) {
        logger.error('❌ Failed to start MCP Chain Client:', error);
        process.exit(1);
    }
}
if (import.meta.url === `file://${process.argv[1]}`) {
    main().catch(console.error);
}
//# sourceMappingURL=index.js.map