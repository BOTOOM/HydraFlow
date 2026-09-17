# HydraFlow — design brief

Flutter app (Android + iOS) to track daily hydration. All data local. UI in **Spanish**.
Original visual style — do NOT copy any existing water-app UI.

## Visual identity ("Ocean glass")
- Palette: deep navy background `#0B1D33` (dark) / soft mist `#F2F7FB` (light); primary aqua `#1FB6C9`;
  accent coral `#FF7A59` (used for warnings / streak); success mint `#3DD598`. Material 3, `useMaterial3: true`,
  ColorScheme.fromSeed(seedColor: 0xFF1FB6C9). Follow system light/dark, with override in Ajustes.
- Main gauge: a **circular ring with an animated wave fill inside** (CustomPainter, sine wave that moves; fill
  level = today's progress). Center shows `X %` large and `Y / Z ml` below. NOT a bottle/cup shape.
- Drink picker: **bottom sheet with a wrap grid of rounded-square "tiles"** (not circles). Each tile shows a
  CustomPainter-drawn icon (simple flat glyph) + name + hydration % badge (e.g. "90%").
- Rounded corners 20, cards with subtle 1px border, no heavy shadows.
- Every drink icon is drawn in code (CustomPainter) or with Material Icons — no copied assets.

## Responsive
- Use `LayoutBuilder`. Breakpoint `>= 720` px width = tablet:
  - Home becomes two columns: gauge + quick-add on the left, today's log + stats on the right.
  - Use `NavigationRail` instead of `NavigationBar` on tablet.
- Phone: bottom `NavigationBar` with 3 destinations: Hoy, Historial, Ajustes.

## Data (all local)
- `shared_preferences` for `UserProfile` + `ReminderSettings` + custom drinks (json).
- `sqflite` for `IntakeEntry` (id, drinkId, volumeMl, effectiveMl, timestamp) and `DailyGoal` history not needed —
  compute goal from profile; store `goal_ml` snapshot on each entry day is overkill; instead store `goalMl`
  with each entry so history stays consistent if profile changes.
- State: `provider` (ChangeNotifier): `ProfileController`, `IntakeController`, `ReminderController`.

## Hydration goal model (research-based, implement in `lib/domain/hydration_calculator.dart`)
Inputs: sex (male/female/other), weightKg, heightCm (optional, display only), age, activityLevel
(sedentary, light, moderate, active, veryActive), climate (cold, temperate, hot), pregnant, breastfeeding.
Rationale: EFSA adequate intake 2.5 L/day men, 2.0 L/day women (total water, ~80 % from beverages);
common per-kg heuristics 30–35 ml/kg; ACSM adds fluid for exercise; extra for hot climate; EFSA +300 ml pregnancy,
+700 ml lactation; older adults have blunted thirst but no lower requirement.

```
base = weightKg * (male ? 35 : female ? 31 : 33)      // ml
if age >= 65: base *= 0.95   // slightly lower lean mass, still round up in UI copy "recuerda beber aunque no tengas sed"
if age < 18: base = weightKg * 40 clamped to <= 2500   // (app targets adults; keep simple)
activity: sedentary +0, light +250, moderate +500, active +750, veryActive +1000
climate:  cold +0, temperate +0, hot +500
pregnant +300, breastfeeding +700
goal = clamp(round to nearest 10, min 1500, max 6000)
```
Example: male 80 kg, moderate, temperate → 2800 + 500 = 3300 ml. Show a "¿Cómo se calcula?" info dialog with the
above explanation in plain Spanish. Allow manual override of the goal (toggle "Meta personalizada").

## Beverages and hydration coefficient (`lib/domain/drink.dart`)
`effectiveMl = volumeMl * coefficient`. Coefficients are based on water content and the Beverage Hydration Index
(Maughan et al. 2016, AJCN): milk / ORS retain more than water (BHI ~1.5), coffee/tea/cola/lager ≈ water (BHI ~1.0),
alcohol >4 % is diuretic. We stay conservative and never credit > 100 % so the UI is intuitive, except we document it.

| id | Nombre | coef | default sizes (ml) | icon idea |
|---|---|---|---|---|
| water | Agua | 1.00 | 150, 250, 350, 500 | drop |
| sparkling | Agua con gas | 1.00 | 250, 330, 500 | drop + bubbles |
| coconut | Agua de coco | 0.95 | 250, 330 | coconut half |
| tea | Té / infusión | 0.98 | 200, 250, 350 | mug with steam |
| coffee | Café | 0.95 | 60, 150, 250, 350 | cup with lid |
| milk | Leche | 0.90 | 200, 250, 350 | carton |
| plantmilk | Leche vegetal | 0.90 | 200, 250, 350 | carton with leaf |
| yogurt | Yogur bebible | 0.85 | 200, 250 | bottle short |
| juice | Jugo natural | 0.88 | 200, 250, 350 | glass with straw |
| smoothie | Batido / smoothie | 0.80 | 300, 400 | tall glass |
| sports | Bebida deportiva | 0.95 | 350, 500, 600 | sport bottle |
| ors | Suero oral | 1.00 | 250, 500 | medical bottle |
| soda | Refresco | 0.90 | 250, 355, 500 | can |
| diet_soda | Refresco light | 0.95 | 250, 355, 500 | can outline |
| energy | Bebida energética | 0.80 | 250, 473 | slim can with bolt |
| soup | Sopa / caldo | 0.90 | 250, 350 | bowl |
| kombucha | Kombucha | 0.90 | 250, 330 | bottle |
| beer | Cerveza | 0.60 | 330, 473 | pint |
| wine | Vino | 0.30 | 125, 175 | wine glass |
| spirits | Licor / cóctel | 0.00 | 45, 200 | cocktail glass |
| custom | (user-defined) | user | user | star |

Users can add custom drinks (name, coefficient 0–100 %, default size, color, one of the available icons).
Adding an entry: choose drink → choose size chip or type custom ml → "Añadir". Show snackbar "Anotado +X ml
(equivale a Y ml de agua)". Entries can be deleted (swipe) from today's list.

## Screens
1. **Onboarding** (first launch, 3 short pages): welcome → profile form (sex, age, weight kg, height cm, activity,
   climate, pregnancy/lactation only when sex = female) → reminders (enable, wake/sleep, interval) → "Empezar".
   Request notification permission here.
2. **Hoy**: greeting + date, wave gauge, "Añadir bebida" FAB / big button, quick-add row with last 4 used drinks,
   today's entries list (time, drink, ml, effective ml), streak count (consecutive days goal reached).
3. **Historial**: last 7 / 30 days bar chart (custom painted, no chart package) with goal line, per-day list with
   percentage; tap a day to see entries.
4. **Ajustes**: Perfil (edit, shows computed goal + "¿Cómo se calcula?"), Meta personalizada, Recordatorios
   (toggle, hora de despertar, hora de dormir, intervalo chips 15 / 30 / 45 min / 1 h / 1,5 h / 2 h / 3 h,
   sonido list with preview play button, pausar cuando la meta esté cumplida toggle), Bebidas (manage custom),
   Tema (sistema/claro/oscuro), Unidades (ml / oz), Acerca de (data sources: EFSA, Maughan 2016).

### Avisos de salud

HydraFlow muestra orientación no diagnóstica basada en los registros:

- ≥1 L en una hora: aviso de cautela sobre repartir los sorbos.
- ≥1,4 L en una hora: aviso urgente para hacer una pausa y vigilar señales de
  hiponatremia.
- ≥150 % de la meta diaria: aviso de posible exceso de agua.
- ≥3 días consecutivos por debajo del 50 % de la meta: aviso informativo; a
  partir de ≥5 días, aviso de cautela. Solo se cuentan días desde el primer
  registro y se excluye el día actual.

Las referencias orientativas son NIOSH 2017-126, *Heat Stress* (no más de
~1,4 L/h), Mayo Clinic sobre hiponatremia y NHS sobre deshidratación. Estos
avisos no sustituyen un diagnóstico ni la atención de un profesional de salud.

## Notifications
- `flutter_local_notifications` + `timezone` + `flutter_timezone`. Schedule `zonedSchedule` for each reminder slot
  between wake and sleep time at the chosen interval, for today and tomorrow (re-schedule on app open, on any
  settings change, and after each intake if "pausar al cumplir meta" is enabled). Cap at 64 scheduled (iOS limit).
- Android channel per sound (channel id includes sound name, since sound is immutable per channel), importance
  high. Sounds as `android/app/src/main/res/raw/*.ogg`; iOS as `ios/Runner/*.caf` (<30 s) added to Runner target
  via project.pbxproj (or document the manual Xcode step in README if pbxproj edit is too fragile — prefer doing it).
- `permission_handler` not needed: use `requestNotificationsPermission()` / `requestExactAlarmsPermission()` from
  the plugin; use `AndroidScheduleMode.inexactAllowWhileIdle` to avoid exact-alarm permission problems, fall back
  gracefully.
- Message copy rotates through ~8 friendly Spanish lines ("Un sorbo ahora, gracias después.", etc.).
- Preview sound in settings via `audioplayers` playing the same file from `assets/sounds/`.

## Sounds (generate with python numpy + ffmpeg -> ogg + caf; script in `tool/gen_sounds.py`)
- `gota` (single water drop: short sine sweep 1200→400 Hz with exponential decay + tiny reverb),
- `burbujas` (3–4 rising bubble pops),
- `vertido` (filtered noise swell 0.8 s + pitch rising),
- `campanita` (two-note bell, 880 & 1320 Hz, decaying),
- `marimba` (three-note ascending marimba-ish tones).
- Also a short `splash` UI sound played on add (toggle in settings, default on).

## Icon (generate with python Pillow in `tool/gen_icon.py`, 1024x1024 PNG at `assets/icon/icon.png`
and `assets/icon/icon_adaptive_fg.png` foreground with transparent bg)
- Rounded-square navy→aqua diagonal gradient background, a white stylised **drop whose lower half is a wave**
  (the drop outline, inside a horizontal wavy fill), small highlight ellipse. Use `flutter_launcher_icons`
  (dev dep) with adaptive icon (background color #0B1D33) and iOS icon.

## Package name / ids
- Dart package `hydraflow`, org `com.botoom`, app label "HydraFlow".

## Quality gates
- `flutter analyze` clean; `flutter test` passing with unit tests for `HydrationCalculator` (cases: male 80 kg
  moderate temperate → 3300; female 60 kg sedentary hot → 2360; pregnancy adds 300; clamps) and for
  effectiveMl computation + daily aggregation (`IntakeController.todayTotal`).
- `flutter build apk --debug` succeeds.
