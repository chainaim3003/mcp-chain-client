export interface MCPServerConfig {
  name: string;
  command: string;
  args: string[];
  env?: Record<string, string>;
}

export interface ToolCall {
  serverName: string;
  toolName: string;
  arguments: Record<string, any>;
}

export interface WorkflowStep {
  id: string;
  serverName: string;
  toolName: string;
  argumentMapping: (context: WorkflowContext) => Record<string, any>;
  condition?: (context: WorkflowContext) => boolean;
  onSuccess?: string | string[];
  onError?: string;
  retries?: number;
  delay?: number;
  type?: string;
}

export interface LoopStep extends Omit<WorkflowStep, 'condition'> {
  type: 'loop';
  iterations?: number;
  condition: (context: WorkflowContext, iteration: number) => boolean;
  loopBody: string[];
}

export interface ConditionalStep extends WorkflowStep {
  type: 'conditional';
  condition: (context: WorkflowContext) => boolean;
  trueBranch: string[];
  falseBranch?: string[];
}

export interface WorkflowContext {
  results: Map<string, any>;
  iteration: number;
  variables: Map<string, any>;
  errors: Map<string, Error>;
}

export interface Workflow {
  name: string;
  startStep: string;
  steps: Map<string, WorkflowStep | LoopStep | ConditionalStep>;
  globalTimeout?: number;
  maxRetries?: number;
}