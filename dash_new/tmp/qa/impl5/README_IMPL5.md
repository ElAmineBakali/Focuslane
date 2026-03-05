# Implementación 5 — Ticket Scanner (Fase 1)

## Feature

Desde el formulario de nueva transacción en Finance, el usuario puede pulsar **"Escanear ticket (IA)"**, seleccionar una foto de un ticket/recibo y el sistema envía la imagen al backend (`POST /v1/ai/finance/receipt_scan`). El backend usa OpenAI Vision para extraer merchant, total, currency, fecha e items. El resultado se muestra en un **preview dialog** con merchant, importe, confianza y modelo. El usuario puede **confirmar** (campos del form se rellenan automáticamente) o **cancelar**. Al guardar, se crea **1 transacción** en Firestore (`finance_transactions`) con `aiMeta.source = "receipt_scan"` y **sin base64 persistido**.

---

## Checklist QA — PASS/FAIL

| Check | Descripción | Resultado | Script / Evidencia |
|-------|-------------|-----------|--------------------|
| **A** | Botón "Escanear ticket (IA)" visible en form, cerca de campo Importe | **PASS** | `check_impl5_A_E_final.js` → `evidence_A_scan_button.png` |
| **B** | Al pulsar, se abre file-picker y se puede seleccionar imagen | **PASS** | `check_impl5_A_E_final.js` (filechooser event) |
| **C** | Cancel durante análisis → no se aplica resultado | **PASS** | `check_impl5_A_E_final.js` → log `analysis cancelled by user` |
| **D** | Preview muestra merchant, total, currency, date, model, confidence | **PASS** | `check_impl5_A_E_final.js` → `evidence_D_preview.png` |
| **E** | Confirmar + Guardar → transacción creada en Firestore | **PASS** | `check_impl5_A_E_final.js` → `evidence_E_after_save.png` |
| **F₁** | Payload inválido de IA → error graceful, form sigue funcional, guardado manual OK | **PASS** | `check_impl5_F_invalid_payload.js` |
| **F₂** | Backend caído → error graceful, form sigue funcional, guardado manual OK | **PASS** | `check_impl5_F_backend_down.js` |
| **G** | Persistencia: `aiMeta.source="receipt_scan"`, NO base64 en documento | **PASS** | Verificación directa Firestore Admin SDK |

---

## DocIDs reales en Firestore

| Escenario | DocID |
|-----------|-------|
| A-E (flujo completo) | `cnyoyuF2yGbZYeHGH4A8` |
| F₁ (payload inválido) | `kAii8ipSj3SaHhZn3L8m` |
| F₂ (backend caído) | `11kdhitsjMRWknYuLFpv` |

**NO base64 persisted: confirmado** — Se verificó con regex `/[A-Za-z0-9+/]{120,}={0,2}/` sobre el JSON completo del documento `e9zbxiiqUHHyWtLJe7kg` (run anterior). Resultado: `hasBase64Like = false`.

DocIDs de runs anteriores (también verificados): `e9zbxiiqUHHyWtLJe7kg`, `Q2mwMJiLkiGnJ96zjREp`, `gkOUfZjq3MDyTvp50Wp6`.

---

## Cómo ejecutar

### Prerrequisitos

1. **Flutter web** corriendo en `http://localhost:5173` con dart-defines de auth:
   ```bash
   cd dash_new
   flutter run -d chrome --web-port 5173 --dart-define-from-file=.tmp_flutter_defines.json
   ```

2. **Backend** corriendo en `http://localhost:8080`:
   ```bash
   cd dash_new/backend
   npm run dev
   ```

3. **Instalar dependencias del test**:
   ```bash
   cd dash_new/tmp/qa/impl5
   npm install
   npx playwright install chromium
   ```

### Ejecución

```bash
cd dash_new/tmp/qa/impl5

# A-E: flujo completo (scan → preview → confirm → save)
node check_impl5_A_E_final.js

# F1: payload inválido de IA → fallback manual
node check_impl5_F_invalid_payload.js

# F2: backend caído → fallback manual
node check_impl5_F_backend_down.js
```

Cada script imprime un bloque JSON con `pass: true/false` y `evidence` entre marcadores (`RESULT_IMPL5_*_START` / `RESULT_IMPL5_*_END`).

---

## Dependencias

| Paquete | Versión | Uso |
|---------|---------|-----|
| `playwright` | ^1.40.0 | Automatización headless Chromium |

Instalación completa:
```bash
npm install
npx playwright install chromium
```

---

## Nota: Flutter Web Semantics

Los scripts usan una **estrategia híbrida**: selectores semánticos (ARIA roles) para navegación general y **coordenadas de mouse** para las interacciones del flujo de escaneo. Esto se debe a un bug conocido de Flutter Web donde activar el árbol de semánticas durante el flow del file-picker + análisis puede provocar assertions del tipo `"Child #N is missing in the tree"` y `"Bad state: Semantics node map was inconsistent after update"`. La estrategia por coordenadas produce resultados estables y reproducibles.

---

## Capturas de evidencia

| Archivo | Descripción |
|---------|-------------|
| `evidence_A_scan_button.png` | Botón "Escanear ticket (IA)" visible en formulario |
| `evidence_B_analyzing.png` | Estado "Analizando ticket…" tras seleccionar imagen |
| `evidence_D_preview.png` | Preview dialog con datos extraídos por IA |
| `evidence_E_after_save.png` | Formulario tras guardar transacción exitosamente |
| `evidence_F_invalid_error.png` | Error graceful con payload IA inválido (generado por `check_impl5_F_invalid_payload.js`) |
| `evidence_F_backend_down_error.png` | Error graceful con backend caído (generado por `check_impl5_F_backend_down.js`) |
