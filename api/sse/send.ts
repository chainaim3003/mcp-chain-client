import { NextRequest, NextResponse } from 'next/server';

export default async function handler(req: NextRequest) {
  if (req.method !== 'POST') {
    return NextResponse.json({ error: 'Method not allowed' }, { status: 405 });
  }
  
  try {
    const body = await req.json();
    const { server, message } = body;
    
    if (!server || !message) {
      return NextResponse.json({ error: 'Server and message are required' }, { status: 400 });
    }
    
    console.log(`📤 Processing message for ${server}:`, message.method);
    
    // Mock response for demonstration
    const response = {
      jsonrpc: '2.0',
      id: message.id,
      result: {
        success: true,
        message: `Mock response from ${server}`,
        timestamp: new Date().toISOString()
      }
    };
    
    return NextResponse.json({ success: true, response });
    
  } catch (error) {
    console.error('Error handling SSE send:', error);
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 });
  }
}
