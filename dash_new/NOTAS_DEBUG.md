# 🔧 Solución de Bugs del Módulo de Notas

## ✅ Problemas Corregidos

### 1. **Notas que desaparecen tras crearlas**
- **Causa**: `ref.set()` sobrescribía el documento completo en lugar de actualizar solo el campo `id`
- **Solución**: Cambiado a `ref.update({'id': ref.id})` para preservar los datos

### 2. **Error al cargar notas en Firestore**
- **Causa**: Query con múltiples `orderBy` sin índice compuesto
- **Solución**: 
  - Removido `orderBy('isPinned')` del query (el ordenamiento se hace en cliente)
  - Creado `firestore.indexes.json` para futuras queries compuestas
  - El ordenamiento pinned-first ahora se hace en `_applyFilters()`

### 3. **No se pueden subir imágenes ni dibujos**
- **Causa Principal**: Firebase Storage **NO ESTÁ HABILITADO** en tu proyecto
- **Causa Secundaria**: Las reglas de Storage no permiten writes a `/notes/`
- **Solución Aplicada**: Actualizado `storage.rules` para permitir uploads
- **⚠️ ACCIÓN REQUERIDA**: Ver sección "Pasos Obligatorios" abajo

### 4. **Falta de feedback visual y logs**
- **Solución**: 
  - Agregados logs detallados en console para cada operación
  - Agregados SnackBars de error
  - Agregados indicadores de progreso para uploads y guardado

## 🚨 Pasos Obligatorios para Habilitar Storage

### Opción 1: Firebase Console (Recomendado - 2 minutos)
1. Ve a: https://console.firebase.google.com/project/maestro-592cd/storage
2. Haz clic en **"Get Started"** o **"Comenzar"**
3. En el diálogo que aparece:
   - Selecciona las reglas de producción (o test mode temporalmente)
   - Elige la ubicación (p.ej. `us-central1` o tu región preferida)
   - Clic en **"Listo"**
4. Una vez creado el bucket, despliega las reglas actualizadas:
   ```powershell
   cd c:\Users\bakal\visualCode\master\dash_new
   firebase deploy --only storage
   ```

### Opción 2: Firebase CLI
```powershell
cd c:\Users\bakal\visualCode\master\dash_new
firebase init storage
# Sigue el wizard, acepta defaults
firebase deploy --only storage
```

### Verificar CORS (Solo para Web)
Si ya configuraste `cors.json`, aplícalo ahora:
```powershell
$bucket = "maestro-592cd.appspot.com"  # O el bucket que aparezca en la consola
gsutil cors set cors.json gs://$bucket
gsutil cors get gs://$bucket
```

## 📝 Cambios en el Código

### `note_firestore_service.dart`
- ✅ Corregido `add()`: usa `update()` en lugar de `set()`
- ✅ Removido `orderBy('isPinned')` del stream
- ✅ Agregados logs de creación/actualización

### `note_editor_screen.dart`
- ✅ Agregado manejo de errores con try/catch
- ✅ Agregados SnackBars para errores de subida
- ✅ Agregados indicadores de progreso `_uploadingMedia` y `_saving`
- ✅ Mejorado manejo de índice del cursor (fallback a `document.length`)
- ✅ Agregados logs detallados en inserción de imágenes y dibujos

### `media_service.dart`
- ✅ Agregado `type: FileType.image` para filtrar solo imágenes
- ✅ Agregado manejo completo de errores con logs
- ✅ Agregados logs de cada paso del proceso de upload

### `notes_list_screen.dart`
- ✅ Agregado manejo de error del StreamBuilder
- ✅ Agregados logs de cantidad de notas recibidas

### `storage.rules`
- ✅ Agregada regla para `/notes/**` (lectura/escritura autenticados)

## 🧪 Cómo Probar

1. **Habilita Storage** (ver arriba)
2. **Despliega las reglas**:
   ```powershell
   cd c:\Users\bakal\visualCode\master\dash_new
   firebase deploy --only storage,firestore
   ```
3. **Ejecuta la app en Chrome**:
   ```powershell
   flutter run -d chrome
   ```
4. **Abre la consola del navegador** (F12) para ver los logs
5. **Crea una nota nueva**:
   - Deberías ver logs: `[NoteFirestoreService] add -> id=...`
   - Luego: `[NotesList] Recibidas X notas`
   - La nota NO debe desaparecer
6. **Inserta una imagen**:
   - Logs esperados:
     ```
     [MediaService] Archivo seleccionado: ...
     [MediaService] Subiendo desde bytes...
     [MediaService] Upload completado: https://...
     [NoteEditor] Imagen insertada url=...
     ```
7. **Prueba el dibujo**:
   - Dibuja algo → Guarda
   - Logs esperados:
     ```
     [DrawingSheet] Capturando imagen...
     [DrawingSheet] Imagen capturada: XXXXX bytes
     [MediaService] Upload completado: ...
     [DrawingSheet] Dibujo guardado: ...
     [NoteEditor] Dibujo insertado url=...
     ```

## 🐛 Si Siguen los Errores

### Error: "Not allowed to write to /notes/..."
- **Solución**: Despliega las reglas actualizadas (ver arriba)

### Error: "Storage has not been set up"
- **Solución**: Habilita Storage en Firebase Console (ver "Pasos Obligatorios")

### Error: "CORS policy blocked"
- **Solución**: Aplica el CORS config con `gsutil` (ver arriba)

### Las notas siguen desapareciendo
- **Revisa console**: ¿Hay errores de Firestore?
- **Verifica auth**: ¿El usuario está autenticado? (`FirebaseAuth.instance.currentUser`)
- **Verifica filtros**: ¿Hay tags activos que oculten la nota?

## 📊 Logs de Depuración

Ahora verás estos logs en console:
- `[NoteFirestoreService] add -> id=XXX title=YYY`
- `[NoteFirestoreService] update -> id=XXX`
- `[NotesList] Recibidas N notas`
- `[NotesList] Primera nota id=XXX updated=... title="..."`
- `[NoteEditor] Imagen insertada url=...`
- `[NoteEditor] Dibujo insertado url=...`
- `[MediaService] Upload completado: ...`
- `[DrawingSheet] Dibujo guardado: ...`

Si ves un error, copia el mensaje completo y podré ayudarte mejor.
