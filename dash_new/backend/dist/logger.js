export function log(level, payload) {
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
