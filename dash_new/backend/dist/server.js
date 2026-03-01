import express from 'express';
import helmet from 'helmet';
import { aiRouter } from './routes.js';
import { config, isProd } from './config.js';
import { log } from './logger.js';
if (!config.openAiApiKey) {
    console.error('[BOOT] OPENAI_API_KEY missing');
    process.exit(1);
}
console.log('[BOOT] OPENAI_API_KEY loaded');
const app = express();
const json2Mb = express.json({ limit: '2mb' });
const json8Mb = express.json({ limit: '8mb' });
const imageRoutes = new Set([
    '/v1/ai/food/calories_from_photo',
    '/v1/ai/finance/receipt_scan',
]);
app.set('trust proxy', 1);
app.use(helmet());
app.use((req, res, next) => {
    const origin = req.header('Origin');
    if (!origin) {
        next();
        return;
    }
    const allowed = config.corsAllowlist.includes(origin);
    if (!allowed) {
        if (isProd) {
            res.status(403).json({ error: 'cors_origin_not_allowed' });
            return;
        }
        next();
        return;
    }
    res.setHeader('Vary', 'Origin');
    res.setHeader('Access-Control-Allow-Origin', origin);
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type,Authorization,X-Firebase-AppCheck');
    if (req.method === 'OPTIONS') {
        res.status(204).send();
        return;
    }
    next();
});
app.use((req, res, next) => {
    if (imageRoutes.has(req.path)) {
        json8Mb(req, res, next);
        return;
    }
    json2Mb(req, res, next);
});
app.get('/healthz', (_req, res) => {
    res.status(200).json({ ok: true, env: config.env });
});
app.use(aiRouter);
app.use((err, _req, res, _next) => {
    log('error', { event: 'unhandled_error' });
    res.status(500).json({ error: 'internal_error' });
});
app.listen(config.port, () => {
    log('info', {
        event: 'server.started',
        details: {
            port: config.port,
            env: config.env,
        },
    });
});
