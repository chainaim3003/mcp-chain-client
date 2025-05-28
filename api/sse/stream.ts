import { NextRequest } from 'next/server';

export const config = {
  runtime: 'edge',
};

const activeConnections = new Map();

export default async function handler(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const server = searchParams.get('server');
  
  if (!server) {
    return new Response('Server name required', { status: 400 });
  }
  
  console.log(`🔌 New SSE connection for server: ${server}`);
  
  const stream = new ReadableStream({
    start(controller) {
      const encoder = new TextEncoder();
      const connectionId = `${server}-${Date.now()}-${Math.random()}`;
      
      activeConnections.set(connectionId, {
        controller,
        encoder,
        serverName: server,
        lastActivity: Date.now()
      });
      
      controller.enqueue(
        encoder.encode(`data: ${JSON.stringify({ 
          type: 'connected', 
          server,
          connectionId,
          timestamp: new Date().toISOString()
        })}\n\n`)
      );
      
      const keepAliveInterval = setInterval(() => {
        try {
          controller.enqueue(
            encoder.encode(`data: ${JSON.stringify({ 
              type: 'keepalive', 
              timestamp: new Date().toISOString() 
            })}\n\n`)
          );
        } catch (error) {
          clearInterval(keepAliveInterval);
          activeConnections.delete(connectionId);
        }
      }, 30000);
    },
    
    cancel() {
      console.log(`🔌 SSE connection closed for server: ${server}`);
    }
  });
  
  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-store, must-revalidate',
      'Connection': 'keep-alive',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type',
    },
  });
}
