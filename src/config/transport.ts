import { TransportConfig, TransportFactory } from '../client/transports/TransportFactory.js';

export function getTransportConfig(): TransportConfig[] {
  const env = TransportFactory.getEnvironmentInfo();
  
  console.log('🔍 Environment detection:', {
    isVercel: env.isVercel,
    isProduction: env.isProduction,
    defaultTransport: env.defaultTransport,
    vercelUrl: env.vercelUrl
  });
  
  if (env.isVercel) {
    return getVercelConfig(env.vercelUrl);
  } else if (env.isProduction) {
    return getProductionConfig();
  } else {
    return getDevelopmentConfig();
  }
}

function getDevelopmentConfig(): TransportConfig[] {
  console.log('📡 Using stdio transport for development');
  
  return [
    {
      name: 'filesystem',
      type: 'stdio',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-filesystem', './data'],
      env: {}
    },
    {
      name: 'sqlite',
      type: 'stdio',
      command: 'npx',
      args: ['-y', '@modelcontextprotocol/server-sqlite', '--db-path', './data/workflow.db'],
      env: {}
    }
  ];
}

function getVercelConfig(vercelUrl?: string): TransportConfig[] {
  const baseUrl = vercelUrl ? `https://${vercelUrl}` : process.env.VERCEL_URL || 'http://localhost:3000';
  
  console.log('📡 Using SSE transport for Vercel deployment:', baseUrl);
  
  return [
    {
      name: 'filesystem',
      type: 'sse',
      url: `${baseUrl}/api/sse/stream`,
      command: '',
      args: [],
      env: {}
    },
    {
      name: 'sqlite',
      type: 'sse',
      url: `${baseUrl}/api/sse/stream`,
      command: '',
      args: [],
      env: {}
    }
  ];
}

function getProductionConfig(): TransportConfig[] {
  const apiBaseUrl = process.env.API_BASE_URL || 'http://localhost:3000';
  
  console.log('📡 Using HTTP transport for production:', apiBaseUrl);
  
  return [
    {
      name: 'filesystem',
      type: 'http',
      url: `${apiBaseUrl}/api/mcp/filesystem`,
      command: '',
      args: [],
      env: {}
    }
  ];
}
