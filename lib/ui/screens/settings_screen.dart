import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/drink.dart';
import '../../domain/models.dart';
import '../../state/controllers.dart';
import '../formatters.dart';
import '../theme.dart';
import '../widgets/profile_form.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  static const _sounds = <String, String>{
    'lluvia': 'Lluvia', 'grifo': 'Grifo', 'chorro': 'Chorro de agua',
    'gotas': 'Gotas', 'burbujas': 'Burbujas', 'arroyo': 'Arroyo',
    'ola': 'Ola', 'campanita': 'Campanita', 'marimba': 'Marimba',
    'ninguno': 'Ninguno',
  };

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<ProfileController>();
    final reminders = context.watch<ReminderController>();
    final current = profile.profile;
    if (current == null) return const Center(child: CircularProgressIndicator());
    final customGoal = current.customGoalMl;
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Ajustes', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      _section(context, 'Perfil', [
        ListTile(
          leading: const Icon(Icons.person_outline),
          title: Text(current.name.isEmpty ? 'Tu perfil' : current.name),
          subtitle: Text('Meta calculada: ${formatVolume(current.goalMl(), profile.unit)}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _editProfile(context, profile, reminders),
        ),
        ListTile(title: const Text('¿Cómo se calcula?'), trailing: const Icon(Icons.info_outline), onTap: () => _formula(context)),
      ]),
      _section(context, 'Meta personalizada', [
        SwitchListTile(
          title: const Text('Usar una meta personalizada'),
          subtitle: Text(customGoal == null ? 'Usando la meta calculada' : formatVolume(customGoal, profile.unit)),
          value: customGoal != null,
          onChanged: (enabled) async => profile.setCustomGoal(enabled ? current.goalMl() : null),
        ),
        if (customGoal != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextFormField(
              initialValue: '$customGoal',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Meta diaria', suffixText: 'ml'),
              onFieldSubmitted: (value) {
                final goal = int.tryParse(value);
                if (goal != null && goal >= 500) profile.setCustomGoal(goal);
              },
            ),
          ),
      ]),
      _section(context, 'Recordatorios', [
        SwitchListTile(
          title: const Text('Recordatorios suaves'),
          value: reminders.settings.enabled,
          onChanged: (value) => reminders.update(reminders.settings.copyWith(enabled: value)),
        ),
        ListTile(
          leading: const Icon(Icons.wb_sunny_outlined),
          title: const Text('Hora de despertar'),
          trailing: Text(_time(reminders.settings.wakeHour, reminders.settings.wakeMinute)),
          onTap: () => _pickTime(context, reminders, true),
        ),
        ListTile(
          leading: const Icon(Icons.nightlight_outlined),
          title: const Text('Hora de dormir'),
          trailing: Text(_time(reminders.settings.sleepHour, reminders.settings.sleepMinute)),
          onTap: () => _pickTime(context, reminders, false),
        ),
        const ListTile(title: Text('Intervalo'), subtitle: Text('Elige cada cuánto recibir avisos')),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [15, 30, 45, 60, 90, 120, 180].map((minutes) => ChoiceChip(
              label: Text(_interval(minutes)),
              selected: reminders.settings.intervalMinutes == minutes,
              onSelected: (_) => reminders.update(reminders.settings.copyWith(intervalMinutes: minutes)),
            )).toList(),
          ),
        ),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: reminders.settings.sound,
          onChanged: (value) {
            if (value != null) reminders.update(reminders.settings.copyWith(sound: value));
          },
          child: Column(
            children: _sounds.entries.map((entry) => RadioListTile<String>(
              value: entry.key,
              title: Text(entry.value),
              secondary: entry.key == 'ninguno' ? null : IconButton(
                tooltip: 'Reproducir',
                icon: const Icon(Icons.play_arrow),
                onPressed: () => context.read<IntakeController>().sound.play(entry.key),
              ),
            )).toList(),
          ),
        ),
        SwitchListTile(
          title: const Text('Sonido al anotar'),
          subtitle: const Text('Reproduce un chapoteo al registrar una bebida'),
          value: reminders.settings.splashEnabled,
          onChanged: (value) => reminders.update(reminders.settings.copyWith(splashEnabled: value)),
        ),
        SwitchListTile(
          title: const Text('Pausar al cumplir la meta'),
          value: reminders.settings.pauseWhenGoalReached,
          onChanged: (value) => reminders.update(reminders.settings.copyWith(pauseWhenGoalReached: value)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Enviar notificación de prueba'),
            onPressed: () => reminders.service.sendTest(reminders.settings.sound),
          ),
        ),
      ]),
      _section(context, 'Bebidas', [
        if (profile.customDrinks.isEmpty)
          const ListTile(title: Text('Bebidas personalizadas'), subtitle: Text('Añade una bebida con tu propio coeficiente.'))
        else
          ...profile.customDrinks.map((drink) => ListTile(
            leading: CircleAvatar(
              backgroundColor: Color(drink.color).withValues(alpha: .16),
              child: Icon(customIcon(drink.icon), color: Color(drink.color)),
            ),
            title: Text(drink.name),
            subtitle: Text(
              '${(drink.coefficient * 100).round()}% · '
              '${formatVolume(drink.defaultSizeMl, profile.unit)}',
            ),
            trailing: IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => profile.removeCustom(drink.id)),
          )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: FilledButton.tonalIcon(
            icon: const Icon(Icons.add),
            label: const Text('Añadir bebida'),
            onPressed: () => _addCustomDrink(context, profile),
          ),
        ),
      ]),
      _section(context, 'Unidades', [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SegmentedButton<UnitPreference>(
            segments: const [
              ButtonSegment(value: UnitPreference.ml, label: Text('ml')),
              ButtonSegment(value: UnitPreference.oz, label: Text('oz')),
            ],
            selected: {profile.unit},
            onSelectionChanged: (value) => profile.setUnit(value.first),
          ),
        ),
      ]),
      _section(context, 'Tema', [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: SegmentedButton<ThemePreference>(
            segments: const [
              ButtonSegment(value: ThemePreference.system, label: Text('Sistema')),
              ButtonSegment(value: ThemePreference.light, label: Text('Claro')),
              ButtonSegment(value: ThemePreference.dark, label: Text('Oscuro')),
            ],
            selected: {profile.theme},
            onSelectionChanged: (value) => profile.setTheme(value.first),
          ),
        ),
      ]),
      _section(context, 'Acerca de', [
        ListTile(
          title: const Text('¿Cuánto hidrata cada bebida?'),
          trailing: const Icon(Icons.table_chart_outlined),
          onTap: () => _coefficients(context),
        ),
        const ListTile(title: Text('HydraFlow'), subtitle: Text('Datos locales · EFSA · Maughan et al. 2016')),
      ]),
    ]);
  }

  Widget _section(BuildContext context, String title, List<Widget> children) => Card(
    margin: const EdgeInsets.only(bottom: 14),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
        ),
        ...children,
      ]),
    ),
  );

  String _interval(int value) => value == 90 ? '1,5 h' : value >= 60 ? '${value ~/ 60} h' : '$value min';
  String _time(int hour, int minute) => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(BuildContext context, ReminderController reminders, bool wake) async {
    final current = TimeOfDay(
      hour: wake ? reminders.settings.wakeHour : reminders.settings.sleepHour,
      minute: wake ? reminders.settings.wakeMinute : reminders.settings.sleepMinute,
    );
    final selected = await showTimePicker(context: context, initialTime: current);
    if (selected == null) return;
    await reminders.update(wake
        ? reminders.settings.copyWith(wakeHour: selected.hour, wakeMinute: selected.minute)
        : reminders.settings.copyWith(sleepHour: selected.hour, sleepMinute: selected.minute));
  }

  Future<void> _editProfile(BuildContext context, ProfileController profile, ReminderController reminders) async {
    await Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => _ProfileEditPage(initial: profile.profile!, onSave: (value) async {
        final preserved = value.copyWith(customGoalMl: profile.profile!.customGoalMl);
        await profile.save(preserved);
        await reminders.service.schedule(reminders.settings);
      }),
    ));
  }

  void _formula(BuildContext context) => showDialog(
    context: context,
    builder: (_) => const AlertDialog(
      title: Text('¿Cómo se calcula?'),
      content: Text('Partimos del peso: 35 ml/kg para hombres, 31 ml/kg para mujeres y 33 ml/kg para otras identidades. Sumamos actividad, clima y las necesidades de embarazo o lactancia. La meta queda entre 1.500 y 6.000 ml, redondeada a decenas. Es una guía, no una indicación médica.'),
    ),
  );

  Future<void> _addCustomDrink(BuildContext context, ProfileController profile) async {
    final result = await showDialog<CustomDrink>(context: context, builder: (_) => const _CustomDrinkDialog());
    if (result != null) await profile.addCustom(result);
  }

  void _coefficients(BuildContext context) => showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('¿Cuánto hidrata cada bebida?'),
      content: SizedBox(
        width: 420,
        child: ListView(
          shrinkWrap: true,
          children: drinks.where((drink) => drink.id != 'custom').map((drink) => ListTile(
            dense: true,
            title: Text(drink.name),
            trailing: Text('${(drink.coefficient * 100).round()}%'),
          )).toList(),
        ),
      ),
    ),
  );
}

class _ProfileEditPage extends StatelessWidget {
  const _ProfileEditPage({required this.initial, required this.onSave});
  final UserProfile initial;
  final Future<void> Function(UserProfile) onSave;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Editar perfil')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: ProfileForm(
        initialProfile: initial,
        onChanged: (_) {},
        showSaveButton: true,
        onSave: (value) async {
          await onSave(value);
          if (context.mounted) Navigator.pop(context);
        },
      ),
    ),
  );
}

class _CustomDrinkDialog extends StatefulWidget {
  const _CustomDrinkDialog();
  @override State<_CustomDrinkDialog> createState() => _CustomDrinkDialogState();
}

class _CustomDrinkDialogState extends State<_CustomDrinkDialog> {
  final name = TextEditingController();
  final size = TextEditingController(text: '250');
  double coefficient = 1;
  int color = 0xFF1FB6C9;
  String icon = 'star';
  static const colors = [0xFF1FB6C9, 0xFFFF7A59, 0xFF3DD598, 0xFF7C83FD, 0xFFFFC857];
  static const icons = ['star', 'drop', 'cup', 'leaf', 'bolt', 'heart'];
  @override void dispose() { name.dispose(); size.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Añadir bebida'),
    content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Nombre')),
      const SizedBox(height: 12),
      Text('Hidratación: ${(coefficient * 100).round()}%'),
      Slider(value: coefficient, onChanged: (value) => setState(() => coefficient = value)),
      TextField(controller: size, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Tamaño predeterminado', suffixText: 'ml')),
      const SizedBox(height: 12),
      const Text('Color'),
      Wrap(spacing: 8, children: colors.map((value) => IconButton(
        onPressed: () => setState(() => color = value),
        icon: Icon(color == value ? Icons.radio_button_checked : Icons.circle, color: Color(value)),
      )).toList()),
      const Text('Icono'),
      Wrap(spacing: 8, children: icons.map((value) => IconButton(
        onPressed: () => setState(() => icon = value),
        icon: Icon(customIcon(value), color: icon == value ? HydraTheme.aqua : Theme.of(context).colorScheme.onSurface),
      )).toList()),
    ])),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
      FilledButton(
        onPressed: () {
          final drinkName = name.text.trim();
          final defaultSize = int.tryParse(size.text);
          if (drinkName.isEmpty || defaultSize == null || defaultSize <= 0) return;
          Navigator.pop(context, CustomDrink(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            name: drinkName, coefficient: coefficient, defaultSizeMl: defaultSize, color: color, icon: icon,
          ));
        },
        child: const Text('Guardar'),
      ),
    ],
  );
}
