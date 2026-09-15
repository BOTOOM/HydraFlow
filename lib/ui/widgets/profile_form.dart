import 'package:flutter/material.dart';
import '../../domain/models.dart';

class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    this.initialProfile,
    required this.onChanged,
    this.showSaveButton = false,
    this.onSave,
  });

  final UserProfile? initialProfile;
  final ValueChanged<UserProfile> onChanged;
  final bool showSaveButton;
  final Future<void> Function(UserProfile)? onSave;

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  late Sex sex;
  late ActivityLevel activity;
  late Climate climate;
  late int age;
  late double weight;
  late double height;
  late bool pregnant;
  late bool breastfeeding;
  late TextEditingController ageController;
  late TextEditingController weightController;
  late TextEditingController heightController;

  UserProfile get value => UserProfile(
        sex: sex,
        age: age,
        weightKg: weight,
        heightCm: height,
        activityLevel: activity,
        climate: climate,
        pregnant: sex == Sex.female && pregnant,
        breastfeeding: sex == Sex.female && breastfeeding,
      );

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    sex = profile?.sex ?? Sex.other;
    activity = profile?.activityLevel ?? ActivityLevel.moderate;
    climate = profile?.climate ?? Climate.temperate;
    age = profile?.age ?? 30;
    weight = profile?.weightKg ?? 70;
    height = profile?.heightCm ?? 170;
    pregnant = profile?.pregnant ?? false;
    breastfeeding = profile?.breastfeeding ?? false;
    ageController = TextEditingController(text: '$age');
    weightController = TextEditingController(text: '$weight');
    heightController = TextEditingController(text: '$height');
  }

  @override
  void dispose() {
    ageController.dispose();
    weightController.dispose();
    heightController.dispose();
    super.dispose();
  }

  void changed() => widget.onChanged(value);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<Sex>(
            isExpanded: true,
            initialValue: sex,
            decoration: const InputDecoration(labelText: 'Sexo'),
            items: Sex.values
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text({
                        'male': 'Hombre',
                        'female': 'Mujer',
                        'other': 'Prefiero no decirlo',
                      }[item.name]!),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              sex = value!;
              changed();
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Edad'),
                  onChanged: (text) {
                    age = int.tryParse(text) ?? age;
                    changed();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Peso (kg)'),
                  onChanged: (text) {
                    weight = double.tryParse(text) ?? weight;
                    changed();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Altura (cm)'),
            onChanged: (text) {
              height = double.tryParse(text) ?? height;
              changed();
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ActivityLevel>(
            isExpanded: true,
            initialValue: activity,
            decoration: const InputDecoration(labelText: 'Actividad'),
            items: ActivityLevel.values
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text({
                        'sedentary': 'Sedentaria',
                        'light': 'Ligera',
                        'moderate': 'Moderada',
                        'active': 'Activa',
                        'veryActive': 'Muy activa',
                      }[item.name]!),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              activity = value!;
              changed();
            }),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Climate>(
            isExpanded: true,
            initialValue: climate,
            decoration: const InputDecoration(labelText: 'Clima'),
            items: Climate.values
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text({
                        'cold': 'Frío',
                        'temperate': 'Templado',
                        'hot': 'Caluroso',
                      }[item.name]!),
                    ))
                .toList(),
            onChanged: (value) => setState(() {
              climate = value!;
              changed();
            }),
          ),
          if (sex == Sex.female) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Estoy embarazada'),
              value: pregnant,
              onChanged: (value) => setState(() {
                pregnant = value;
                changed();
              }),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Estoy amamantando'),
              value: breastfeeding,
              onChanged: (value) => setState(() {
                breastfeeding = value;
                changed();
              }),
            ),
          ],
          if (widget.showSaveButton) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: widget.onSave == null ? null : () => widget.onSave!(value),
              child: const Text('Guardar cambios'),
            ),
          ],
        ],
      );
}
