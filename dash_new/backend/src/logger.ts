type Level = 'info' | 'warn' | 'error';

type LogPayload = {
  event: string;
  uid?: string;
  route?: string;
  ip?: string;
  status?: string;
  latencyMs?: number;
  details?: Record<string, unknown>;
};

export function log(level: Level, payload: LogPayload): void {
  const safePayload = {
    timestamp: new Date().toISOString(),
    level,
    ...payload,
  };

  const line = JSON.stringify(safePayload);
  if (level === 'error') {
    console.error(line);
    return;
  }
  if (level === 'warn') {
    console.warn(line);
    return;
  }
  console.log(line);
}
