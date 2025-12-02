# Supabase Configuration for Notes Media

## Project Setup (2 minutos - 100% Gratis)

### 1. Crear Proyecto Supabase
1. Ve a: https://supabase.com
2. Clic en "Start your project" (sin tarjeta de crédito)
3. Crea una cuenta con GitHub/Google
4. Clic en "New Project"
5. Nombre: `focuslane-notes` (o el que prefieras)
6. Database Password: (guarda esto, lo necesitarás)
7. Región: Elige la más cercana (ej. `South America (São Paulo)`)
8. Plan: **Free** (incluye 1GB storage gratis)
9. Clic en "Create new project"

### 2. Obtener Credenciales
1. En el panel del proyecto, ve a **Settings** (⚙️) → **API**
2. Copia estos dos valores:
   - `Project URL`: `https://xxxxxxxxxxx.supabase.co`
   - `anon public`: `eyJh...` (el token largo)

### 3. Crear Bucket de Storage
1. En el sidebar, clic en **Storage**
2. Clic en "New bucket"
3. Name: `notes-media`
4. **Public bucket**: ✅ **ACTIVAR ESTO** (para que las imágenes se vean)
5. Clic en "Create bucket"

### 4. Configurar Políticas de Acceso (RLS)
1. Con el bucket `notes-media` seleccionado, clic en **Policies**
2. Clic en "New Policy" para **INSERT**:
   - Policy name: `Allow authenticated uploads`
   - Target roles: `authenticated`
   - WITH CHECK expression: `true`
   - Clic en "Save policy"
3. Clic en "New Policy" para **SELECT**:
   - Policy name: `Allow public reads`
   - Target roles: `public`
   - WITH CHECK expression: `true`
   - Clic en "Save policy"

Alternativamente, ejecuta este SQL en **SQL Editor**:
```sql
-- Permitir subir imágenes a usuarios autenticados
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'notes-media');

-- Permitir lectura pública de imágenes
CREATE POLICY "Allow public reads"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'notes-media');
```

## Integración en Flutter

### 5. Agregar Credenciales
Crea el archivo `lib/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'https://TU_PROYECTO.supabase.co';
  static const String anonKey = 'eyJh... TU ANON KEY AQUÍ';
}
```

⚠️ **IMPORTANTE**: Agrega este archivo a `.gitignore` si subes el código a GitHub.

### 6. Inicializar Supabase
Ya he preparado todo el código. Solo necesitas:

1. Completar `lib/supabase_config.dart` con tus credenciales (paso 5)
2. Correr:
```powershell
flutter pub get
flutter run -d chrome
```

## ✅ Ventajas de Supabase vs Firebase Storage

| Feature | Supabase (Free) | Firebase Storage (Paid) |
|---------|-----------------|-------------------------|
| Storage | 1 GB | 5 GB pero ahora es de pago |
| Bandwidth | 2 GB/mes | 1 GB/día pero de pago |
| Uploads | ✅ Ilimitados | ✅ Pero de pago |
| Public URLs | ✅ Gratis | ✅ Pero de pago |
| CORS | ✅ Auto-configurado | ❌ Requiere gsutil |
| Admin UI | ✅ Excelente | ⭐ Firebase Console |

## 🧪 Testing

Una vez configurado, prueba:
1. Crear nota → Insertar imagen → Debería subir a Supabase
2. Dibujar → Guardar → Debería subir el PNG
3. Ver la imagen en la nota → Debería cargar desde Supabase

Los logs mostrarán:
```
[SupabaseMediaService] Archivo seleccionado: imagen.png
[SupabaseMediaService] Subiendo desde bytes...
[SupabaseMediaService] Upload completado: https://...supabase.co/storage/v1/object/public/notes-media/...
[NoteEditor] Imagen insertada url=https://...
```

## 📊 Dashboard Supabase

Para ver tus archivos subidos:
1. Dashboard Supabase → **Storage** → bucket `notes-media`
2. Verás carpetas `notes/` y `notes/drawings/` con tus archivos

Puedes eliminar archivos manualmente si necesitas limpiar espacio.

## 🔄 Migración desde Firebase

Si ya tienes imágenes en Firebase Storage:
1. Descárgalas manualmente del bucket de Firebase
2. Súbelas a Supabase via Dashboard
3. Actualiza las URLs en Firestore (o déjalas si Firebase sigue activo)

## ⚠️ Troubleshooting

### Error: "Invalid API key"
- Verifica que copiaste correctamente el `anon public` key en `supabase_config.dart`

### Error: "new row violates row-level security policy"
- Asegúrate de crear las políticas RLS (paso 4)
- O desactiva temporalmente RLS para testing (no recomendado en producción)

### Las imágenes no cargan
- Verifica que el bucket `notes-media` sea **público**
- Revisa la URL en DevTools: debe ser `https://.../storage/v1/object/public/...`
