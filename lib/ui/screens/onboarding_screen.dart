import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models.dart';
import '../../state/controllers.dart';
import '../theme.dart';
import '../widgets/profile_form.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override State<OnboardingScreen> createState() => _OnboardingScreenState();
}
class _OnboardingScreenState extends State<OnboardingScreen> {
  final page = PageController();
  int step = 0;
  Sex sex = Sex.other; ActivityLevel activity = ActivityLevel.moderate; Climate climate = Climate.temperate;
  int age = 30; double weight = 70; double height = 170; bool pregnant = false; bool breastfeeding = false;
  ReminderSettings reminderSettings = const ReminderSettings();
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: PageView(controller: page, physics: const NeverScrollableScrollPhysics(), children: [
      _welcome(), _profile(), _reminders(),
    ])),
  );
  Widget _shell({required String eyebrow, required String title, required Widget child, required String action, required VoidCallback onAction}) => Padding(
    padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Expanded(child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24), Text(eyebrow.toUpperCase(), style: const TextStyle(color: HydraTheme.aqua, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
        const SizedBox(height: 14), Text(title, style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 24), child,
      ]))),
      const SizedBox(height: 16),
      SizedBox(width: double.infinity, child: FilledButton(onPressed: onAction, child: Padding(padding: const EdgeInsets.all(16), child: Text(action)))),
    ]),
  );
  Widget _welcome() => _shell(eyebrow: 'HydraFlow', title: 'Tu hidratación, en tu propio ritmo.', action: 'Continuar', onAction: () { setState(() => step = 1); page.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut); }, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Una guía amable para escuchar a tu cuerpo, registrar lo que tomas y dejar que la ola crezca.', style: TextStyle(fontSize: 18, height: 1.5)),
    const SizedBox(height: 24), Container(width: 160, height: 160, decoration: BoxDecoration(shape: BoxShape.circle, color: HydraTheme.aqua.withValues(alpha: .13)), child: const Icon(Icons.water_drop_outlined, color: HydraTheme.aqua, size: 84)),
  ]));
  Widget _profile() => _shell(eyebrow: 'Paso 1 de 2', title: 'Cuéntanos de ti', action: 'Siguiente', onAction: () { setState(() => step = 2); page.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOut); }, child: ProfileForm(
    onChanged: (value) => setState(() {
      sex = value.sex; age = value.age; weight = value.weightKg; height = value.heightCm ?? height;
      activity = value.activityLevel; climate = value.climate; pregnant = value.pregnant; breastfeeding = value.breastfeeding;
    }),
  ));
  Widget _reminders() => _shell(eyebrow: 'Paso 2 de 2', title: 'Pequeños recordatorios', action: 'Empezar', onAction: () async {
    final profileController = context.read<ProfileController>();
    final reminderController = context.read<ReminderController>();
    final profile = UserProfile(sex: sex, age: age, weightKg: weight, heightCm: height, activityLevel: activity, climate: climate, pregnant: pregnant, breastfeeding: breastfeeding);
    await profileController.save(profile);
    await profileController.repository.setOnboardingDone();
    if (reminderSettings.enabled) await reminderController.requestPermissions();
    await reminderController.update(reminderSettings);
  }, child: StatefulBuilder(builder: (context, setState) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Puedes activar avisos suaves para no perder el hilo. Todo queda guardado en tu dispositivo y podrás cambiarlo desde Ajustes.', style: TextStyle(fontSize: 18, height: 1.5)),
    const SizedBox(height: 16),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Activar recordatorios'),
      value: reminderSettings.enabled,
      onChanged: (value) => setState(() => reminderSettings = reminderSettings.copyWith(enabled: value)),
    ),
    ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.wb_sunny_outlined),
        title: const Text('Hora de despertar'),
        subtitle: Text(_formatTime(reminderSettings.wakeHour, reminderSettings.wakeMinute)),
        onTap: () async {
          final selected = await showTimePicker(context: context, initialTime: TimeOfDay(hour: reminderSettings.wakeHour, minute: reminderSettings.wakeMinute));
          if (selected != null) setState(() => reminderSettings = reminderSettings.copyWith(wakeHour: selected.hour, wakeMinute: selected.minute));
        },
      ),
    ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.dark_mode_outlined),
        title: const Text('Hora de dormir'),
        subtitle: Text(_formatTime(reminderSettings.sleepHour, reminderSettings.sleepMinute)),
        onTap: () async {
          final selected = await showTimePicker(context: context, initialTime: TimeOfDay(hour: reminderSettings.sleepHour, minute: reminderSettings.sleepMinute));
          if (selected != null) setState(() => reminderSettings = reminderSettings.copyWith(sleepHour: selected.hour, sleepMinute: selected.minute));
        },
      ),
    DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: reminderSettings.intervalMinutes,
      decoration: const InputDecoration(labelText: 'Intervalo'),
      items: [15, 30, 45, 60, 90, 120, 180].map((value) => DropdownMenuItem(value: value, child: Text(value == 90 ? '1,5 h' : value >= 60 ? '${value ~/ 60} h' : '$value min'))).toList(),
      onChanged: (value) => setState(() => reminderSettings = reminderSettings.copyWith(intervalMinutes: value)),
    ),
    DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: reminderSettings.sound,
      decoration: const InputDecoration(labelText: 'Sonido'),
      items: const [
        DropdownMenuItem(value: 'ninguno', child: Text('Ninguno')),
        DropdownMenuItem(value: 'gota', child: Text('Gota')),
        DropdownMenuItem(value: 'burbujas', child: Text('Burbujas')),
        DropdownMenuItem(value: 'vertido', child: Text('Vertido')),
        DropdownMenuItem(value: 'campanita', child: Text('Campanita')),
        DropdownMenuItem(value: 'marimba', child: Text('Marimba')),
      ],
      onChanged: (value) => setState(() => reminderSettings = reminderSettings.copyWith(sound: value)),
    ),
  ])));
}

String _formatTime(int hour, int minute) => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
