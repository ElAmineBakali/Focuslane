# Focuslane AI Backend - Cloud Run

Este backend Express se despliega como contenedor en Google Cloud Run y expone los endpoints de IA usados por Flutter.

## Requisitos

- Google Cloud SDK instalado.
- Cuenta con permisos sobre el proyecto `maestro-592cd`.
- APIs habilitadas: Cloud Run, Cloud Build, Artifact Registry y Secret Manager.
- Secreto `OPENAI_API_KEY` creado en Secret Manager.

## Preparacion

```bash
gcloud auth login
gcloud config set project maestro-592cd
gcloud services enable run.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com
```

Crear el secreto si no existe:

```bash
printf '%s' '<OPENAI_API_KEY>' | gcloud secrets create OPENAI_API_KEY --data-file=- --replication-policy=automatic
```

## Despliegue

Desde `dash_new/backend`:

```bash
PROJECT_ID=maestro-592cd \
REGION=europe-west1 \
SERVICE_NAME=focuslane-ai-backend \
CORS_ALLOWLIST=https://tu-dominio.com \
REQUIRE_APP_CHECK=false \
./deploy-cloud-run.sh
```

El despliegue usa:

- `--source .` para construir el contenedor desde el `Dockerfile`.
- Puerto `8080`, compatible con `process.env.PORT`.
- `OPENAI_API_KEY` inyectada desde Secret Manager.
- `--allow-unauthenticated`, porque el backend valida Firebase Auth a nivel de aplicacion en `/v1/ai/*`.

## Verificacion

```bash
curl https://focuslane-ai-backend-jajf6p3puq-ew.a.run.app/v1/healthz
curl https://focuslane-ai-backend-jajf6p3puq-ew.a.run.app/healthz/
```

En la verificacion del 2026-04-29, `/v1/healthz` y `/healthz/` respondieron 200. El path exacto `/healthz` sin barra devolvio 404 de Google Frontend, por lo que se recomienda usar `/v1/healthz` como health check estable.

Los endpoints IA deben rechazar peticiones sin token con `missing_auth_token`:

```bash
curl -i -X POST https://focuslane-ai-backend-jajf6p3puq-ew.a.run.app/v1/ai/finance/classify \
  -H 'Content-Type: application/json' \
  -d '{}'
```

## Configuracion Flutter

Produccion usa por defecto:

```text
https://focuslane-ai-backend-jajf6p3puq-ew.a.run.app
```

Tambien puede fijarse explicitamente:

```bash
flutter run --dart-define=AI_BACKEND_URL=https://focuslane-ai-backend-jajf6p3puq-ew.a.run.app
```

Desarrollo local:

```bash
flutter run --dart-define=APP_ENV=dev --dart-define=AI_BACKEND_URL=http://localhost:8080
```

El codigo mantiene compatibilidad con `AI_BACKEND_BASE_URL_DEV` y `AI_BACKEND_BASE_URL_PROD`, pero `AI_BACKEND_URL` tiene prioridad para evitar mezclar local y produccion.
