import { z } from 'zod';

const baseMetaSchema = z
  .object({
    requestId: z.string().min(1).max(128).optional(),
    source: z.string().min(1).max(64).optional(),
  })
  .optional();

export const financeClassifySchema = z.object({
  text: z.string().min(1).max(5000),
  locale: z.string().min(2).max(16).default('es-ES'),
  meta: baseMetaSchema,
});

export const caloriesFromPhotoSchema = z.object({
  imageBase64: z.string().min(16),
  mimeType: z.enum(['image/jpeg', 'image/png', 'image/webp']).default('image/jpeg'),
  locale: z.string().min(2).max(16).default('es-ES'),
  meta: baseMetaSchema,
});

export const receiptScanSchema = z.object({
  imageBase64: z.string().min(16),
  mimeType: z.enum(['image/jpeg', 'image/png', 'image/webp']).default('image/jpeg'),
  locale: z.string().min(2).max(16).default('es-ES'),
  meta: baseMetaSchema,
});

export const explainOrDebugSchema = z.object({
  input: z.string().min(1).max(8000),
  context: z.record(z.any()).optional(),
  meta: baseMetaSchema,
});

export const financeClassifyOutputSchema = z.object({
  category: z.string().min(1),
  subCategory: z.string().nullable(),
  tags: z.array(z.string().min(1)).max(10),
  confidence: z.number().min(0).max(1),
  reasoning_short: z.string().min(1).max(240),
});

export const caloriesFromPhotoOutputSchema = z.object({
  estimatedCalories: z.number().nonnegative().nullable(),
  macros: z.object({
    protein: z.number().nonnegative().nullable(),
    carbs: z.number().nonnegative().nullable(),
    fat: z.number().nonnegative().nullable(),
  }),
  items: z.array(
    z.object({
      name: z.string().min(1),
      portion: z.string().min(1),
      calories: z.number().nonnegative(),
    }),
  ).max(20),
  confidence: z.number().min(0).max(1),
});

export const receiptScanOutputSchema = z.object({
  merchant: z.string().nullable(),
  total: z.number().nonnegative().nullable(),
  currency: z.string().min(3).max(3).nullable(),
  dateISO: z.string().nullable().optional(),
  items: z.array(
    z.object({
      name: z.string().min(1),
      qty: z.number().nonnegative(),
      price: z.number().nonnegative(),
    }),
  ).max(40).optional().default([]),
  confidence: z.number().min(0).max(1),
});

export type FinanceClassifyInput = z.infer<typeof financeClassifySchema>;
export type CaloriesFromPhotoInput = z.infer<typeof caloriesFromPhotoSchema>;
export type ReceiptScanInput = z.infer<typeof receiptScanSchema>;
export type ExplainOrDebugInput = z.infer<typeof explainOrDebugSchema>;
export type FinanceClassifyOutput = z.infer<typeof financeClassifyOutputSchema>;
export type CaloriesFromPhotoOutput = z.infer<typeof caloriesFromPhotoOutputSchema>;
export type ReceiptScanOutput = z.infer<typeof receiptScanOutputSchema>;
