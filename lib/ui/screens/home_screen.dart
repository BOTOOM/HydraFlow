import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/avatar_mood.dart';
import '../../domain/drink.dart';
import '../../domain/models.dart';
import '../../state/controllers.dart';
import '../theme.dart';
import '../widgets/drink_tile.dart';
import '../widgets/droplet_avatar.dart';
import '../widgets/wave_gauge.dart';
import '../formatters.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override Widget build(BuildContext context) {
    final intake = context.watch<IntakeController>();
    final profile = context.watch<ProfileController>();
    final reminders = context.watch<ReminderController>().settings;
    final avatar = avatarStateFor(
      totalMl: intake.todayTotal,
      goalMl: intake.todayGoal,
      now: DateTime.now(),
      wakeHour: reminders.wakeHour,
      wakeMinute: reminders.wakeMinute,
      sleepHour: reminders.sleepHour,
      sleepMinute: reminders.sleepMinute,
      lastDrinkAt: intake.entries.isEmpty
          ? null
          : intake.entries.map((e) => e.timestamp).reduce((a, b) => a.isAfter(b) ? a : b),
    );
    return LayoutBuilder(builder: (context, constraints) {
      final tablet = constraints.maxWidth >= 720;
      final left = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hola${profile.profile?.name.isNotEmpty == true ? ', ${profile.profile!.name}' : ''}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
        Text(DateFormat('EEEE, d MMMM', 'es').format(DateTime.now()), style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 18),
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            DropletAvatar(state: avatar, size: 120, celebrations: intake.celebrations),
            const SizedBox(width: 12),
            Expanded(child: _bubble(context, avatar.message)),
          ]),
          const SizedBox(height: 8),
          WaveGauge(progress: intake.progress, total: intake.todayTotal, goal: intake.todayGoal, unit: profile.unit),
          FilledButton.icon(onPressed: () => _addSheet(context), icon: const Icon(Icons.add), label: const Text('Añadir bebida')),
        ]))),
        if (intake.recentDrinkIds.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Añadir de nuevo', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 92,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: intake.recentDrinkIds.map((id) {
                final drink = drinkById(id, profile.customDrinks);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Icon(drink.icon, color: drink.color ?? HydraTheme.aqua),
                    label: Text(drink.name),
                    onPressed: () => intake.add(id, drink.sizes.first),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(children: [Expanded(child: _stat(context, '${intake.streak()}', 'días de racha', HydraTheme.coral)), Expanded(child: _stat(context, '${intake.todayEntries.length}', 'registros hoy', HydraTheme.aqua))]),
      ]);
      final right = Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Hoy', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12), if (intake.todayEntries.isEmpty) const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Aún no hay sorbos anotados.'))),
        ...intake.todayEntries.map((entry) {
          final drink = drinkById(entry.drinkId, profile.customDrinks);
          return Dismissible(
            key: ValueKey(entry.id),
            onDismissed: (_) => intake.remove(entry),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: HydraTheme.aqua.withValues(alpha: .12), child: Icon(drink.icon, color: HydraTheme.aqua)),
              title: Text(drink.name),
              subtitle: Text(DateFormat('HH:mm').format(entry.timestamp)),
              trailing: Text('+${formatVolume(entry.effectiveMl, profile.unit)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ])));
      return SingleChildScrollView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), child: tablet ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: left), const SizedBox(width: 20), Expanded(child: right)]) : Column(children: [left, const SizedBox(height: 16), right]));
    });
  }
  Widget _bubble(BuildContext context, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: HydraTheme.aqua.withValues(alpha: .12),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(18),
          ),
        ),
        child: Text(text, style: const TextStyle(fontSize: 15, height: 1.35, fontWeight: FontWeight.w600)),
      );
  Widget _stat(BuildContext context, String value, String label, Color color) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))])));
  Future<void> _addSheet(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DrinkPicker(
        customDrinks: context.read<ProfileController>().customDrinks,
        unit: context.read<ProfileController>().unit,
        onAdded: (drink, size) async {
          await context.read<IntakeController>().add(drink.id, size);
          if (context.mounted) {
            Navigator.pop(context);
            final unit = context.read<ProfileController>().unit;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Anotado +${formatVolume(size, unit)} '
                  '(equivale a ${formatVolume(drink.effectiveMl(size), unit)})',
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
class _DrinkPicker extends StatefulWidget {
  const _DrinkPicker({required this.onAdded, required this.customDrinks, required this.unit});
  final Future<void> Function(Drink, int) onAdded;
  final List<CustomDrink> customDrinks;
  final UnitPreference unit;
  @override State<_DrinkPicker> createState() => _DrinkPickerState();
}
class _DrinkPickerState extends State<_DrinkPicker> {
  Drink? selected;
  final customController = TextEditingController();
  late List<Drink> options;

  @override
  void initState() {
    super.initState();
    options = [
      ...drinks.where((drink) => drink.id != 'custom'),
      ...widget.customDrinks.map((item) => drinkById(item.id, widget.customDrinks)),
    ];
  }

  @override
  void dispose() {
    customController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: SizedBox(
          height: height * .8,
          child: Column(
            children: [
              const Text(
                'Elige una bebida',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: GridView.builder(
                  itemCount: options.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: .9,
                  ),
                  itemBuilder: (_, i) => DrinkTile(
                    drink: options[i],
                    onTap: () => setState(() {
                      selected = options[i];
                      customController.clear();
                    }),
                  ),
                ),
              ),
              if (selected != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                      children: [
                        ...selected!.sizes.map(
                          (size) => ActionChip(
                            label: Text(formatVolume(size, widget.unit)),
                            onPressed: () => widget.onAdded(selected!, size),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: customController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Otra cantidad',
                              suffixText: 'ml',
                              isDense: true,
                            ),
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            final value = int.tryParse(customController.text);
                            if (value != null && value > 0) {
                              final drink = selected;
                              if (drink != null) widget.onAdded(drink, value);
                            }
                          },
                          child: const Text('Añadir'),
                        ),
                      ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
