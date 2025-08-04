# Scripts Temporales - Lista de Errores Pendientes

## Errores principales a resolver:

1. **HackingScript constructors**: Falta manejar los parámetros `difficulty`, `command`, `tags`, `requiresSudo`, `estimatedTime` en:
   - lib/providers/script_provider.dart (línea 94)
   - lib/services/storage_service.dart (múltiples líneas)
   - lib/services/massive_script_repository.dart (múltiples constructores)

2. **CommandResult properties**: Necesita `output`, `error`, `executionTime` como getters/propiedades

3. **main.dart**: Problemas con variables indefinidas `_showLinuxOnboarding` y `_checkingLinuxSetup`

4. **Permisos**: `Permission.accessWifiState` no existe

## Estrategia:
1. Simplificar temporalmente los scripts para que compile
2. Una vez que compile, mejorar gradualmente
3. Mantener la funcionalidad básica primero
