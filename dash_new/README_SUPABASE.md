# ✅ Migración Completa a Supabase Storage (Gratuito)

## 🎯 Qué se ha hecho

He migrado tu módulo de Notas de **Firebase Storage (de pago)** a **Supabase Storage (100% gratuito)** sin cambiar la UI ni el flujo de usuario.

### Cambios Realizados

1. **Dependencias** (`pubspec.yaml`)
   - ✅ Agregado `supabase_flutter: ^2.8.1`
   - ✅ Removido `firebase_storage` (ya no es necesario)

2. **Nuevo Servicio** (`lib/services/supabase_media_service.dart`)
   - ✅ Misma API que `MediaService`
   - ✅ Métodos: `pickAndUpload()`, `uploadBytes()`, `uploadFile()`
   - ✅ Logs detallados para debugging
   - ✅ Manejo robusto de errores

3. **Configuración** (`lib/supabase_config.dart`)
   - ✅ Archivo creado para credenciales
   - ⚠️ **PENDIENTE**: Debes completar con tus credenciales de Supabase

4. **Inicialización** (`lib/main.dart`)
   - ✅ Supabase se inicializa antes de Firebase
   - ✅ Prefijo `fb_auth` para evitar conflictos con Supabase User class

5. **Editor de Notas** (`lib/screens/notes/note_editor_screen.dart`)
   - ✅ Usa `SupabaseMediaService` en lugar de `MediaService`
   - ✅ Mismo flujo para imágenes y dibujos
   - ✅ Sin cambios visuales ni de UX

6. **Lista de Notas** (`lib/screens/notes/notes_list_screen.dart`)
   - ✅ Corregido layout de grid (eliminado `Expanded` problemático)
   - ✅ Sin cambios funcionales

## 🚀 Configuración (5 minutos)

### Paso 1: Crear Proyecto Supabase (2 min)
1. Ve a: **https://supabase.com**
2. Clic en **"Start your project"** (NO pide tarjeta)
3. Inicia sesión con GitHub o Google
4. Clic en **"New Project"**
5. Configuración:
   - **Name**: `focuslane` (o cualquier nombre)
   - **Database Password**: Genera uno fuerte (guárdalo)
   - **Region**: `South America (São Paulo)` (más cercano a ti)
   - **Plan**: **Free** ✅ (1GB storage + 2GB bandwidth/mes gratis)
6. Clic en **"Create new project"**
7. Espera 1-2 minutos mientras se crea

### Paso 2: Obtener Credenciales (30 seg)
1. En tu proyecto, ve a **⚙️ Settings** → **API**
2. Copia estos dos valores:
   - **Project URL**: `https://xxxxxxxxxx.supabase.co`
   - **anon public**: `eyJh...` (el token largo de la tabla "Project API keys")

### Paso 3: Configurar en tu App (30 seg)
1. Abre `lib/supabase_config.dart`
2. Reemplaza los valores:
```dart
class SupabaseConfig {
  static const String url = 'https://xxxxxxxxxx.supabase.co';  // ← TU URL AQUÍ
  static const String anonKey = 'eyJh...';  // ← TU TOKEN AQUÍ
}
```
3. Guarda el archivo

### Paso 4: Crear Bucket de Storage (1 min)
1. En Supabase Dashboard, ve a **📁 Storage** (sidebar izquierdo)
2. Clic en **"New bucket"**
3. Configuración:
   - **Name**: `notes-media` ← **EXACTAMENTE este nombre**
   - **Public bucket**: ✅ **MARCAR COMO PÚBLICO** (importante para ver imágenes)
   - **File size limit**: 50 MB (default está bien)
4. Clic en **"Create bucket"**

### Paso 5: Configurar Permisos (1 min)
Con el bucket `notes-media` seleccionado:

#### Opción A: SQL Editor (más rápido)
1. Ve a **🔧 SQL Editor** (sidebar)
2. Clic en **"New query"**
3. Pega esto:
```sql
-- Permitir subir a usuarios autenticados
CREATE POLICY "Allow authenticated uploads"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'notes-media');

-- Permitir lectura pública
CREATE POLICY "Allow public reads"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'notes-media');
```
4. Clic en **"Run"** (▶️)

#### Opción B: UI (paso a paso)
1. Bucket `notes-media` → tab **Policies**
2. Clic en **"New Policy"** (sección INSERT)
   - **Policy name**: `Allow authenticated uploads`
   - **Target roles**: `authenticated`
   - **WITH CHECK**: `true`
   - **Save**
3. Clic en **"New Policy"** (sección SELECT)
   - **Policy name**: `Allow public reads`
   - **Target roles**: `public`
   - **USING**: `true`
   - **Save**

### Paso 6: Probar (1 min)
```powershell
cd c:\Users\bakal\visualCode\master\dash_new
flutter run -d chrome
```

## 🧪 Testing

### 1. Verificar Logs
Abre DevTools (F12) → Console. Deberías ver:
```
[SupabaseMediaService] Archivo seleccionado: imagen.png (123456 bytes)
[SupabaseMediaService] Subiendo desde bytes...
[SupabaseMediaService] Iniciando upload a: notes/xxxxx.png
[SupabaseMediaService] Upload completado: https://...supabase.co/storage/v1/object/public/notes-media/notes/xxxxx.png
[NoteEditor] Imagen insertada url=https://...
```

### 2. Crear Nota con Imagen
1. Nueva nota → Título "Test imagen"
2. Clic en icono **📷 Imagen**
3. Selecciona una imagen
4. Debería subir y mostrarse en el editor
5. Guarda la nota
6. Vuelve a la lista → la imagen debe verse en la portada

### 3. Crear Dibujo
1. Nueva nota → Título "Test dibujo"
2. Clic en icono **🖌️ Dibujar**
3. Dibuja algo
4. Clic en **💾 Guardar**
5. El dibujo debe insertarse en la nota
6. Guarda → debe verse en la lista

### 4. Verificar en Supabase
1. Supabase Dashboard → **Storage** → bucket `notes-media`
2. Verás carpetas:
   - `notes/` (imágenes subidas)
   - `notes/drawings/` (dibujos exportados)
3. Puedes ver/descargar/eliminar archivos desde ahí

## ✅ Ventajas de Supabase

| Feature | Supabase (Free) | Firebase Storage |
|---------|-----------------|------------------|
| Costo | **Gratis** | De pago desde 2024 |
| Storage | 1 GB | Ahora cuesta |
| Bandwidth | 2 GB/mes | Ahora cuesta |
| CORS | Auto-configurado | Requiere gsutil |
| Dashboard | Moderno y rápido | Firebase Console |
| Escalabilidad | Upgrade cuando quieras | Requiere billing |

## 🔐 Seguridad

- ✅ Los uploads requieren usuario autenticado (Firebase Auth sigue funcionando)
- ✅ Las imágenes son públicamente legibles (necesario para `Image.network`)
- ✅ Solo los archivos en `notes-media` son públicos, el resto de Supabase es privado
- ✅ RLS (Row Level Security) aplicado vía políticas

## 📊 Monitoreo

### Ver uso de Storage
1. Supabase Dashboard → **Settings** → **Usage**
2. Verás:
   - Storage usado (de 1GB)
   - Bandwidth usado (de 2GB/mes)
   - Requests (de 50,000/mes)

### Limpiar espacio
1. **Storage** → `notes-media`
2. Selecciona archivos antiguos/no usados
3. Clic en **"Delete"**

O via SQL:
```sql
-- Eliminar archivos más viejos de 30 días
DELETE FROM storage.objects
WHERE bucket_id = 'notes-media'
AND created_at < NOW() - INTERVAL '30 days';
```

## ⚠️ Troubleshooting

### Error: "Invalid API key"
- ✅ Verifica que copiaste correctamente el `anonKey` en `supabase_config.dart`
- ✅ Asegúrate de copiar el **anon public** key, NO el service_role

### Error: "new row violates row-level security policy"
- ✅ Crea las políticas RLS (Paso 5)
- ✅ Verifica que el usuario esté autenticado en Firebase Auth

### Error: "The bucket notes-media does not exist"
- ✅ Crea el bucket con **exactamente** el nombre `notes-media`
- ✅ Márcalo como **público**

### Las imágenes no cargan (404 o CORS)
- ✅ Verifica que el bucket sea **público**
- ✅ Las URLs deben contener `/storage/v1/object/public/notes-media/...`
- ✅ Si ves `/private/`, el bucket NO es público

### Error de compilación con "User"
- ✅ Ya lo arreglé: Firebase Auth usa `fb_auth.User`, Supabase usa `User`
- ✅ Si ves errores, busca `import 'package:firebase_auth/firebase_auth.dart' as fb_auth;`

## 🔄 Rollback (si algo falla)

Si quieres volver a Firebase Storage:
```powershell
# 1. Revertir pubspec.yaml
# Quita: supabase_flutter: ^2.8.1
# Agrega: firebase_storage: ^12.4.10

# 2. Revertir note_editor_screen.dart
# Cambia: import '../../services/supabase_media_service.dart';
# Por:    import '../../services/media_service.dart';
# Cambia: SupabaseMediaService()
# Por:    MediaService()

# 3. Remover init de Supabase en main.dart
# Borra las 4 líneas de Supabase.initialize(...)

flutter pub get
flutter run -d chrome
```

## 📚 Recursos

- **Supabase Docs**: https://supabase.com/docs/guides/storage
- **Flutter Client**: https://supabase.com/docs/reference/dart
- **RLS Policies**: https://supabase.com/docs/guides/auth/row-level-security
- **Dashboard**: https://supabase.com/dashboard

## ✨ Próximos Pasos (Opcional)

### Optimizar imágenes antes de subir
```dart
// En SupabaseMediaService.uploadBytes():
final compressed = await FlutterImageCompress.compressWithList(
  data,
  minWidth: 1200,
  quality: 85,
);
await _storage.from(_bucketName).uploadBinary(path, compressed, ...);
```

### Agregar progress bar
```dart
final uploadTask = _storage.from(_bucketName).uploadBinary(
  path,
  bytes,
  fileOptions: FileOptions(
    cacheControl: '3600',
    upsert: false,
  ),
);
// Escuchar progreso si Supabase lo soporta en versiones futuras
```

### Migrar imágenes existentes de Firebase
```dart
// Script para migrar (ejecutar una vez)
final firebaseUrls = await getFirebaseImageUrls();
for (final url in firebaseUrls) {
  final bytes = await http.get(Uri.parse(url)).then((r) => r.bodyBytes);
  final newUrl = await SupabaseMediaService().uploadBytes(bytes, fileName: '...');
  await updateNoteImageUrl(oldUrl: url, newUrl: newUrl);
}
```

---

**¡Listo!** Ahora tienes almacenamiento **100% gratuito** para tus notas sin depender de Firebase Storage de pago. 🎉
