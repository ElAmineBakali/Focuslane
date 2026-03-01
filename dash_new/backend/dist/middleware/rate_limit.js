import rateLimit from 'express-rate-limit';
export const aiRateLimiter = rateLimit({
    windowMs: 60 * 1000,
    max: 30,
    standardHeaders: true,
    legacyHeaders: false,
    keyGenerator: (req) => {
        const r = req;
        const uid = r.auth?.uid ?? 'anon';
        const forwarded = req.headers['x-forwarded-for'];
        const forwardedIp = Array.isArray(forwarded)
            ? forwarded[0]
            : typeof forwarded === 'string'
                ? forwarded.split(',')[0]?.trim()
                : '';
        const ipGenerator = rateLimit.ipKeyGenerator;
        const normalizedIp = req.ip || 'unknown';
        const ip = forwardedIp || (ipGenerator ? ipGenerator(normalizedIp) : normalizedIp);
        return `${uid}:${ip}`;
    },
    message: {
        error: 'rate_limit_exceeded',
    },
});
