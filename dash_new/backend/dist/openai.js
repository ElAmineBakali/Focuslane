import { config } from './config.js';
function extractOutputText(payload) {
    if (typeof payload?.output_text === 'string' && payload.output_text.trim().length > 0) {
        return payload.output_text;
    }
    const outputs = Array.isArray(payload?.output) ? payload.output : [];
    const textParts = [];
    for (const output of outputs) {
        const content = Array.isArray(output?.content) ? output.content : [];
        for (const piece of content) {
            if (piece?.type === 'output_text' && typeof piece?.text === 'string') {
                textParts.push(piece.text);
            }
        }
    }
    return textParts.join('\n').trim();
}
function maybeExtractTokens(payload) {
    const usage = payload?.usage;
    if (!usage || typeof usage !== 'object')
        return undefined;
    const totalTokens = usage.total_tokens;
    if (typeof totalTokens === 'number' && Number.isFinite(totalTokens)) {
        return totalTokens;
    }
    const inputTokens = typeof usage.input_tokens === 'number' ? usage.input_tokens : 0;
    const outputTokens = typeof usage.output_tokens === 'number' ? usage.output_tokens : 0;
    const combined = inputTokens + outputTokens;
    return combined > 0 ? combined : undefined;
}
export async function callOpenAiJson(options) {
    if (!config.openAiApiKey) {
        throw new Error('openai_api_key_missing');
    }
    const userContent = [
        { type: 'input_text', text: options.userPrompt },
    ];
    if (options.image) {
        userContent.push({
            type: 'input_image',
            image_url: `data:${options.image.mimeType};base64,${options.image.imageBase64}`,
        });
    }
    const response = await fetch('https://api.openai.com/v1/responses', {
        method: 'POST',
        headers: {
            Authorization: `Bearer ${config.openAiApiKey}`,
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            model: options.model,
            temperature: 0,
            input: [
                {
                    role: 'system',
                    content: [
                        {
                            type: 'input_text',
                            text: options.systemPrompt,
                        },
                    ],
                },
                {
                    role: 'user',
                    content: userContent,
                },
            ],
        }),
    });
    const payload = await response.json();
    if (!response.ok) {
        const reason = typeof payload?.error?.message === 'string'
            ? payload.error.message
            : 'openai_request_failed';
        throw new Error(reason);
    }
    const outputText = extractOutputText(payload);
    if (!outputText) {
        throw new Error('openai_empty_output');
    }
    let parsedJson;
    try {
        parsedJson = JSON.parse(outputText);
    }
    catch {
        throw new Error('openai_non_json_output');
    }
    const parsed = options.schema.safeParse(parsedJson);
    if (!parsed.success) {
        throw new Error('openai_schema_parse_failed');
    }
    return {
        data: parsed.data,
        model: typeof payload?.model === 'string' ? payload.model : options.model,
        tokens: maybeExtractTokens(payload),
    };
}
