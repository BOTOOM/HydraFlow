# hydraflow_watch

Companion app de HydraFlow para Apple Watch, construida con
[flutterwatch.dev](https://flutterwatch.dev/).

Muestra el progreso de hidratación del día con la gotita animada de HydraFlow,
permite registrar agua y otras bebidas con sus coeficientes de hidratación,
deshacer el último registro y guarda las entradas del día en el propio reloj.

- Reutiliza la lógica de dominio del paquete raíz (`avatar_mood`, `drinks`,
  `hydration_calculator`, `IntakeEntry`) vía dependencia `path: ../`.
- `flutter_watchos`: haptics, scroll con la Digital Crown, safe area de watchOS.
- `shared_preferences_watchos`: persistencia local de las entradas del día.

## Correr en el simulador

Requiere macOS con Xcode y la toolchain de flutter-watchos instalada:

```sh
git clone https://github.com/FlutterWatchOrg/flutter-watchos ~/flutter-watchos
export PATH="$HOME/flutter-watchos/bin:$PATH"

cd watch
flutter-watchos pub get
flutter-watchos run -d <udid-del-simulador-watch>
```

`flutter-watchos doctor` verifica el entorno (Flutter 3.47.x, runtime de
watchOS en Xcode). En simulador corre en modo debug con hot reload; en watch
físico solo AOT (requiere `flutter-watchos login`).
