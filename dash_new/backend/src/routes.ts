import type { Request, Response } from 'express';
import { Router } from 'express';

import type { ZodSchema } from 'zod';

import type { AuthenticatedRequest } from './middleware/auth.js';
import { verifyFirebaseAuth, verifyAppCheckIfPresent } from './middleware/auth.js';
import { aiRateLimiter } from './middleware/rate_limit.js';
import {
  caloriesFromPhotoOutputSchema,
  caloriesFromPhotoSchema,
  explainOrDebugSchema,
  financeClassifyOutputSchema,
  financeClassifySchema,
  receiptScanOutputSchema,
  receiptScanSchema,
} from './schemas.js';
import { log } from './logger.js';
import { buildImageInputHash, persistAiLog } from './persistence.js';
import { callOpenAiJson } from './openai.js';

const router = Router();

router.use('/v1/ai', verifyFirebaseAuth, verifyAppCheckIfPresent, aiRateLimiter);

function parseBody<T>(schema: ZodSchema<T>, req: Request, res: Response): T | null {
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({
      error: 'invalid_payload',
      details: parsed.error.flatten(),
    });
    return null;
  }
  return parsed.data;
}

function elapsedMs(start: bigint): number {
  return Number((process.hrtime.bigint() - start) / 1000000n);
}

async function safePersistAiLog(input: Parameters<typeof persistAiLog>[0], route: string): Promise<void> {
  try {
    await persistAiLog(input);
    console.log('[AI_LOG] persisted OK');
  } catch (error) {
    console.error(`[AI_LOG] persist failed: ${error instanceof Error ? error.message : 'unknown_error'}`);
    log('warn', {
      event: 'ai.persist_failed',
      uid: input.uid,
      route,
      details: {
        reason: error instanceof Error ? error.message : 'unknown',
      },
    });
  }
}

const jsonOnlyRule =
  'Return ONLY valid JSON. No markdown, no prose, no code fences, no comments. Keep keys exactly as requested.';

router.post('/v1/ai/finance/classify', async (req: AuthenticatedRequest, res: Response) => {
  const payload = parseBody(financeClassifySchema, req, res);
  if (!payload) return;

  const uid = req.auth!.uid;
  const requestId = payload.meta?.requestId;
  const start = process.hrtime.bigint();

  try {
    console.log('Calling OpenAI model: gpt-5-mini');
    const ai = await callOpenAiJson({
      model: 'gpt-5-mini',
      schema: financeClassifyOutputSchema,
      systemPrompt: `${jsonOnlyRule}\nSchema: {"category":string,"subCategory":string|null,"tags":string[],"confidence":number[0..1],"reasoning_short":string}`,
      userPrompt:
        `Classify this personal finance text for locale ${payload.locale}. ` +
        `Use short taxonomy labels suitable for app categories. Text: ${payload.text}`,
    });

    const latencyMs = elapsedMs(start);
  console.log(`OpenAI response received (latencyMs=${latencyMs})`);
    await safePersistAiLog({
      uid,
      type: 'finance_classify',
      input: payload,
      status: 'ok',
      latencyMs,
      model: ai.model,
      tokens: ai.tokens,
      requestId,
      resultSummary: `${ai.data.category}/${ai.data.subCategory ?? 'null'} c=${ai.data.confidence.toFixed(2)}`,
    }, req.path);

    log('info', {
      event: 'ai.response',
      uid,
      route: req.path,
      ip: req.ip,
      status: 'ok',
      latencyMs,
      details: {
        requestId,
        appCheckVerified: req.auth?.appCheckVerified ?? false,
        type: 'finance_classify',
        model: ai.model,
      },
    });

    res.status(200).json({
      ...ai.data,
      model: ai.model,
    });
  } catch (error) {
    const latencyMs = elapsedMs(start);
    const message = error instanceof Error ? error.message : 'unknown_error';
    const status = message === 'openai_schema_parse_failed' || message === 'openai_non_json_output' ? 502 : 500;
    const logStatus = status === 502 ? 'parse_error' : 'error';

    await safePersistAiLog({
      uid,
      type: 'finance_classify',
      input: payload,
      status: logStatus,
      latencyMs,
      model: 'gpt-5-mini',
      requestId,
      resultSummary: `error:${message}`,
    }, req.path);

    res.status(status).json({ error: status === 502 ? 'ai_parse_error' : 'ai_backend_error' });
  }
});

router.post('/v1/ai/food/calories_from_photo', async (req: AuthenticatedRequest, res: Response) => {
  const payload = parseBody(caloriesFromPhotoSchema, req, res);
  if (!payload) return;

  const uid = req.auth!.uid;
  const requestId = payload.meta?.requestId;
  const mimeType = payload.mimeType ?? 'image/jpeg';
  const start = process.hrtime.bigint();
  const inputHash = buildImageInputHash({
    type: 'food_calories_from_photo',
    mimeType,
    imageBase64: payload.imageBase64,
  });

  try {
    console.log('Calling OpenAI model: gpt-5-mini');
    let ai = await callOpenAiJson({
      model: 'gpt-5-mini',
      schema: caloriesFromPhotoOutputSchema,
      systemPrompt:
        `${jsonOnlyRule}\n` +
        'Schema: {"estimatedCalories":number|null,"macros":{"protein":number|null,"carbs":number|null,"fat":number|null},"items":[{"name":string,"portion":string,"calories":number}],"confidence":number[0..1]}',
      userPrompt:
        `Estimate calories and macros from this food photo for locale ${payload.locale}. ` +
        'Be conservative, do not hallucinate brands, and keep confidence realistic.',
      image: {
        mimeType,
        imageBase64: payload.imageBase64,
      },
    });

    if (ai.data.confidence < 0.55) {
      console.log('Calling OpenAI model: gpt-5');
      ai = await callOpenAiJson({
        model: 'gpt-5',
        schema: caloriesFromPhotoOutputSchema,
        systemPrompt:
          `${jsonOnlyRule}\n` +
          'Schema: {"estimatedCalories":number|null,"macros":{"protein":number|null,"carbs":number|null,"fat":number|null},"items":[{"name":string,"portion":string,"calories":number}],"confidence":number[0..1]}',
        userPrompt:
          `Re-evaluate this food photo for locale ${payload.locale}. ` +
          'Prefer robust estimates over precision and include portions.',
        image: {
          mimeType,
          imageBase64: payload.imageBase64,
        },
      });
    }

    const latencyMs = elapsedMs(start);
  console.log(`OpenAI response received (latencyMs=${latencyMs})`);
    await safePersistAiLog({
      uid,
      type: 'food_calories_from_photo',
      input: {
        inputHash,
        mimeType,
        bytesLength: payload.imageBase64.length,
      },
      status: 'ok',
      latencyMs,
      model: ai.model,
      tokens: ai.tokens,
      requestId,
      resultSummary: `kcal=${ai.data.estimatedCalories ?? 'null'} c=${ai.data.confidence.toFixed(2)}`,
    }, req.path);

    res.status(200).json({
      ...ai.data,
      model: ai.model,
    });
  } catch (error) {
    const latencyMs = elapsedMs(start);
    const message = error instanceof Error ? error.message : 'unknown_error';
    const status = message === 'openai_schema_parse_failed' || message === 'openai_non_json_output' ? 502 : 500;
    const logStatus = status === 502 ? 'parse_error' : 'error';

    await safePersistAiLog({
      uid,
      type: 'food_calories_from_photo',
      input: {
        inputHash,
        mimeType,
        bytesLength: payload.imageBase64.length,
      },
      status: logStatus,
      latencyMs,
      model: 'gpt-5-mini',
      requestId,
      resultSummary: `error:${message}`,
    }, req.path);

    res.status(status).json({ error: status === 502 ? 'ai_parse_error' : 'ai_backend_error' });
  }
});

router.post('/v1/ai/finance/receipt_scan', async (req: AuthenticatedRequest, res: Response) => {
  const payload = parseBody(receiptScanSchema, req, res);
  if (!payload) return;

  const uid = req.auth!.uid;
  const requestId = payload.meta?.requestId;
  const mimeType = payload.mimeType ?? 'image/jpeg';
  const start = process.hrtime.bigint();
  const inputHash = buildImageInputHash({
    type: 'finance_receipt_scan',
    mimeType,
    imageBase64: payload.imageBase64,
  });

  try {
    console.log('Calling OpenAI model: gpt-5-mini');
    const ai = await callOpenAiJson({
      model: 'gpt-5-mini',
      schema: receiptScanOutputSchema,
      systemPrompt:
        `${jsonOnlyRule}\n` +
        'Schema: {"merchant":string|null,"total":number|null,"currency":string|null,"dateISO":string|null,"items":[{"name":string,"qty":number,"price":number}]?,"confidence":number[0..1]}\n' +
        'merchant, total and dateISO keys must always exist; if unknown use null and lower confidence.',
      userPrompt:
        `Extract a structured receipt for locale ${payload.locale}. ` +
        'Use ISO date when possible (YYYY-MM-DD).',
      image: {
        mimeType,
        imageBase64: payload.imageBase64,
      },
    });

    const latencyMs = elapsedMs(start);
  console.log(`OpenAI response received (latencyMs=${latencyMs})`);
    await safePersistAiLog({
      uid,
      type: 'finance_receipt_scan',
      input: {
        inputHash,
        mimeType,
        bytesLength: payload.imageBase64.length,
      },
      status: 'ok',
      latencyMs,
      model: ai.model,
      tokens: ai.tokens,
      requestId,
      resultSummary: `${ai.data.merchant ?? 'null'} total=${ai.data.total ?? 'null'} c=${ai.data.confidence.toFixed(2)}`,
    }, req.path);

    res.status(200).json(ai.data);
  } catch (error) {
    const latencyMs = elapsedMs(start);
    const message = error instanceof Error ? error.message : 'unknown_error';
    const status = message === 'openai_schema_parse_failed' || message === 'openai_non_json_output' ? 502 : 500;
    const logStatus = status === 502 ? 'parse_error' : 'error';

    await safePersistAiLog({
      uid,
      type: 'finance_receipt_scan',
      input: {
        inputHash,
        mimeType,
        bytesLength: payload.imageBase64.length,
      },
      status: logStatus,
      latencyMs,
      model: 'gpt-5-mini',
      requestId,
      resultSummary: `error:${message}`,
    }, req.path);

    res.status(status).json({ error: status === 502 ? 'ai_parse_error' : 'ai_backend_error' });
  }
});

router.post('/v1/ai/sync/explain_or_debug', async (req: AuthenticatedRequest, res: Response) => {
  const payload = parseBody(explainOrDebugSchema, req, res);
  if (!payload) return;

  const uid = req.auth!.uid;
  const requestId = payload.meta?.requestId;
  const start = process.hrtime.bigint();
  const responsePayload = {
    explanation: 'Stub response: explicación de sincronización disponible en implementación 1.',
    nextStep: 'Integrar motor IA en Cloud Run y enrutar desde API Gateway.',
  };

  await safePersistAiLog({
    uid,
    type: 'sync_explain_or_debug',
    input: payload,
    status: 'ok',
    latencyMs: elapsedMs(start),
    model: 'stub-debug-v1',
    requestId,
    resultSummary: 'sync explain stub',
  }, req.path);

  res.status(200).json(responsePayload);
});

export { router as aiRouter };
