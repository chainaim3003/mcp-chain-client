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
