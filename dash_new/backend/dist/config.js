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
function parseAllowlist(raw) {
    if (!raw)
        return defaultCorsAllowlist;
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
};
export const isProd = config.env === 'prod' || config.env === 'production';
