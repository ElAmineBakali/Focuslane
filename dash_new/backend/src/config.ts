import dotenv from 'dotenv';

dotenv.config();

const env = process.env.ENV ?? process.env.NODE_ENV ?? 'dev';
const defaultCorsAllowlist = [
  'http://localhost:3000',
  'http://localhost:5173',
  'http://localhost:8080',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:5173',
  'http://127.0.0.1:8080',
];

function parseAllowlist(raw: string | undefined): string[] {
  if (!raw) return defaultCorsAllowlist;
  const parsed = raw
    .split(',')
    .map((value) => value.trim())
    .filter((value) => value.length > 0);
  return parsed.length > 0 ? parsed : defaultCorsAllowlist;
}

export const config = {
  env,
  port: Number(process.env.PORT ?? 8080),
  openAiApiKey: process.env.OPENAI_API_KEY ?? '',
  firebaseProjectId: process.env.FIREBASE_PROJECT_ID ?? process.env.GOOGLE_CLOUD_PROJECT ?? '',
  corsAllowlist: parseAllowlist(process.env.CORS_ALLOWLIST),
  requireAppCheck: (process.env.REQUIRE_APP_CHECK ?? (env === 'prod' || env === 'production' ? 'true' : 'false')) === 'true',
} as const;

export const isProd = config.env === 'prod' || config.env === 'production';

function matchesLocalhostWildcard(origin: string, allowedOrigin: string): boolean {
  if (allowedOrigin !== 'http://localhost:*' && allowedOrigin !== 'http://127.0.0.1:*') {
    return false;
  }

  try {
    const parsedOrigin = new URL(origin);
    const [allowedProtocol, allowedHostWithWildcard] = allowedOrigin.split('://');
    const allowedHost = allowedHostWithWildcard.replace(':*', '');

    return parsedOrigin.protocol === `${allowedProtocol}:`
      && parsedOrigin.hostname === allowedHost
      && parsedOrigin.port.length > 0;
  } catch {
    return false;
  }
}

export function isCorsOriginAllowed(origin: string): boolean {
  return config.corsAllowlist.some((allowedOrigin) => (
    allowedOrigin === origin || matchesLocalhostWildcard(origin, allowedOrigin)
  )) || (!isProd && /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin));
}
