# HydraFlow

App Flutter (Android / iOS, responsive para tablet) para registrar tu hidratación diaria con una meta personalizada, múltiples bebidas, recordatorios con sonidos de agua y una gotita compañera que reacciona a cómo vas en el día. Todos los datos se guardan en el dispositivo.

## Funciones

- **Meta personalizada**: sexo, edad, peso, altura, actividad, clima, embarazo/lactancia (basado en recomendaciones EFSA). Meta manual opcional.
- **20+ bebidas** con coeficiente de hidratación (agua 100 %, té 98 %, café 95 %, leche 90 %, jugo 88 %, cerveza 60 %, vino 30 %…) y bebidas personalizadas.
- **Hoy**: medidor de anillo con ola animada, racha, registros del día, añadir rápido.
- **Gotita**: avatar procedural animado (respira, parpadea, se sacude al tocarlo y celebra cada sorbo). Su color, forma y humor cambian según lo cerca o lejos que estés de la meta a lo largo del día y de la noche.
- **Historial** 7/30 días con gráfica.
- **Recordatorios**: horario despertar/dormir, intervalo, pausa al cumplir meta, notificación de prueba y sonidos de agua sintetizados (lluvia, grifo, chorro, gotas, burbujas, arroyo, ola, campanita, marimba).
- Tema claro/oscuro, unidades ml/oz, icono adaptativo propio.

## Desarrollo

```bash
flutter pub get
flutter analyze && flutter test
flutter run
flutter build apk --release
```

Los sonidos y el icono se generan con `python3 tool/gen_sounds.py` y `python3 tool/gen_icon.py` (numpy, ffmpeg, Pillow).

Ver [DESIGN.md](DESIGN.md) para el modelo de hidratación, la arquitectura y las decisiones de diseño.
