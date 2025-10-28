# Dropdowns Dinámicos con API

Este sistema permite crear dropdowns que cargan sus opciones dinámicamente desde una API, con manejo automático de estados de carga, errores y reintentos.

## Archivos creados/modificados

### Modelos

- `lib/models/dropdown_option.dart` - Modelo para las opciones del dropdown

### Widgets

- `lib/widgets/api_dropdown_field.dart` - Widget principal del dropdown dinámico

### Servicios

- `lib/services/api_service.dart` - Métodos agregados para obtener opciones

### Ejemplos

- `lib/screens/dropdown_example_screen.dart` - Pantalla de ejemplo
- `lib/screens/informes/agregar_informe_screen.dart` - Implementación en pantalla existente

## Uso básico

### 1. Dropdown específico (recomendado para casos comunes)

```dart
CategoriasDropdown(
  value: _categoriaSeleccionada,
  onChanged: (categoria) {
    setState(() {
      _categoriaSeleccionada = categoria;
    });
  },
  label: 'Categoría',
)
```

### 2. Dropdown genérico simple

```dart
SimpleApiDropdown(
  endpoint: 'usuarios',
  value: _usuarioSeleccionado,
  onChanged: (usuario) {
    setState(() {
      _usuarioSeleccionado = usuario;
    });
  },
  hint: 'Seleccionar usuario...',
  label: 'Usuario',
)
```

### 3. Dropdown personalizado avanzado

```dart
ApiDropdownField(
  fetchOptions: () => ApiService().getTiposDocumento(),
  value: _selectedOption,
  onChanged: (option) => setState(() => _selectedOption = option),
  hint: 'Seleccionar...',
  label: 'Etiqueta',
  icon: Icons.category,
  decoration: InputDecoration(
    border: OutlineInputBorder(),
    filled: true,
  ),
  displayText: (option) => '${option.value} (${option.description})',
)
```

## Configuración de la API

### Formato esperado de respuesta

La API debe devolver las opciones en uno de estos formatos:

#### Opción 1: Lista directa

```json
[
  {
    "id": "1",
    "value": "Alimentación",
    "description": "Gastos de comida",
    "isActive": true
  },
  {
    "id": "2",
    "value": "Transporte",
    "isActive": true
  }
]
```

#### Opción 2: Objeto con estructura

```json
{
  "success": true,
  "message": "Opciones cargadas correctamente",
  "data": [
    {
      "id": "1",
      "name": "Hospedaje",
      "active": true
    }
  ]
}
```

### Campos del modelo DropdownOption

- `id` (requerido): Identificador único
- `value` (requerido): Texto que se muestra al usuario
- `description` (opcional): Descripción adicional
- `isActive` (opcional): Si la opción está activa (por defecto true)
- `metadata` (opcional): Datos adicionales

## Agregar nuevos endpoints

1. Agregar método específico en `ApiService`:

```dart
Future<List<DropdownOption>> getMiNuevoEndpoint() async {
  return await getDropdownOptions('mi-nuevo-endpoint');
}
```

2. Crear widget específico (opcional):

```dart
class MiNuevoDropdown extends StatelessWidget {
  final ValueChanged<DropdownOption?> onChanged;
  final DropdownOption? value;

  const MiNuevoDropdown({
    super.key,
    required this.onChanged,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();

    return ApiDropdownField(
      fetchOptions: apiService.getMiNuevoEndpoint,
      onChanged: onChanged,
      value: value,
      hint: 'Seleccionar...',
      label: 'Mi Nuevo Campo',
      icon: Icons.new_releases,
    );
  }
}
```

## Características principales

### ✅ Estados automáticos

- **Carga**: Muestra indicador de progreso
- **Error**: Muestra mensaje de error con botón de reintento
- **Vacío**: Muestra mensaje cuando no hay opciones
- **Éxito**: Muestra dropdown normal con opciones

### ✅ Manejo de errores

- Reintentos automáticos con botón
- Mensajes de error descriptivos
- Fallbacks para conexión perdida

### ✅ Optimización

- Evita cargas múltiples
- Filtrado automático de opciones inactivas
- Caching de respuestas

### ✅ Personalización

- Iconos personalizados
- Decoración del campo
- Texto de display personalizable
- Labels y hints configurables

## Ejemplo de integración completa

Ver `lib/screens/dropdown_example_screen.dart` para un ejemplo completo que muestra:

- Diferentes tipos de dropdowns
- Manejo de estados
- Validación y limpieza
- Retroalimentación al usuario

## Endpoints específicos para Rendición

Tu aplicación tiene endpoints específicos implementados:

### APIs de Rendición

- **Políticas**: `http://190.119.200.124:45490/maestros/rendicion_politica`
- **Categorías**: `http://190.119.200.124:45490/maestros/rendicion_categoria?politica=NOMBRE_POLITICA`

### Formato real de respuesta de las APIs

#### API de Políticas:

```json
[
  { "id": "1", "politica": "GENERAL", "estado": "S" },
  { "id": "2", "politica": "GASTOS DE MOVILIDAD", "estado": "S" }
]
```

#### API de Categorías:

```json
[
  {
    "id": "1",
    "politica": "GASTOS DE MOVILIDAD",
    "categoria": "MOVILIDAD",
    "estado": "S"
  },
  {
    "id": "2",
    "politica": "GENERAL",
    "categoria": "COMBUSTIBLE",
    "estado": "S"
  },
  {
    "id": "3",
    "politica": "GENERAL",
    "categoria": "ALIMENTACION",
    "estado": "S"
  }
]
```

### Métodos en ApiService

```dart
// Obtener todas las políticas de rendición
Future<List<DropdownOption>> getRendicionPoliticas()

// Obtener categorías filtradas por política (usar NOMBRE, no ID)
Future<List<DropdownOption>> getRendicionCategorias({String politica = 'todos'})
```

### Características importantes:

1. **El filtro de categorías usa el NOMBRE de la política**, no el ID
2. **El campo `estado: "S"` indica que la opción está activa**
3. **Los datos originales se guardan en `metadata` para acceso posterior**
4. **Para obtener todas las categorías, usar `politica=todos`**

### Widgets específicos de rendición

#### 1. Dropdown de políticas de rendición

```dart
RendicionPoliticasDropdown(
  value: _politicaSeleccionada,
  onChanged: (politica) {
    setState(() => _politicaSeleccionada = politica);
  },
)
```

#### 2. Dropdown de categorías de rendición (con filtro de política)

```dart
RendicionCategoriasDropdown(
  value: _categoriaSeleccionada,
  onChanged: (categoria) {
    setState(() => _categoriaSeleccionada = categoria);
  },
  politicaNombre: _politicaSeleccionada?.value, // Usar .value, no .id
)
```

#### 3. Dropdowns combinados (maneja dependencia automáticamente)

```dart
RendicionDropdownsCombinados(
  politicaSeleccionada: _politicaSeleccionada,
  categoriaSeleccionada: _categoriaSeleccionada,
  onPoliticaChanged: (politica) {
    setState(() => _politicaSeleccionada = politica);
    // La categoría se limpia automáticamente
  },
  onCategoriaChanged: (categoria) {
    setState(() => _categoriaSeleccionada = categoria);
  },
)
```

## Ejemplos implementados

### Pantallas de ejemplo creadas:

- `lib/screens/test_rendicion_screen.dart` - Pantalla de prueba técnica
- `lib/screens/rendicion_example_screen.dart` - Ejemplo completo con tus APIs específicas
- `lib/screens/informes/agregar_informe_screen.dart` - Implementación en pantalla existente

### Funcionalidad de dependencia

- Cuando seleccionas una política, las categorías se recargan automáticamente
- El dropdown de categorías se limpia cuando cambias de política
- Soporte para obtener "todas" las categorías con `politica=todos`
- El filtro usa el nombre de la política (`politica.value`) no el ID

### Datos disponibles después de selección:

```dart
// Después de seleccionar una política:
print('ID: ${politica.id}');           // "1"
print('Nombre: ${politica.value}');     // "GENERAL"
print('Estado: ${politica.metadata?['estado']}'); // "S"

// Después de seleccionar una categoría:
print('ID: ${categoria.id}');          // "2"
print('Nombre: ${categoria.value}');    // "COMBUSTIBLE"
print('Política: ${categoria.metadata?['politica']}'); // "GENERAL"
print('Estado: ${categoria.metadata?['estado']}');     // "S"
```
