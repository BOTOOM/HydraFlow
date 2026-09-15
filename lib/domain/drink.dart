import 'package:flutter/material.dart';
import 'models.dart';

class Drink {
  const Drink({
    required this.id, required this.name, required this.coefficient,
    required this.sizes, required this.icon, this.color,
  });
  final String id;
  final String name;
  final double coefficient;
  final List<int> sizes;
  final IconData icon;
  final Color? color;
  int effectiveMl(int volumeMl) => (volumeMl * coefficient).round();
}

const drinks = <Drink>[
  Drink(id: 'water', name: 'Agua', coefficient: 1, sizes: [150, 250, 350, 500], icon: Icons.water_drop_outlined),
  Drink(id: 'sparkling', name: 'Agua con gas', coefficient: 1, sizes: [250, 330, 500], icon: Icons.bubble_chart_outlined),
  Drink(id: 'coconut', name: 'Agua de coco', coefficient: .95, sizes: [250, 330], icon: Icons.spa_outlined),
  Drink(id: 'tea', name: 'Té / infusión', coefficient: .98, sizes: [200, 250, 350], icon: Icons.emoji_food_beverage_outlined),
  Drink(id: 'coffee', name: 'Café', coefficient: .95, sizes: [60, 150, 250, 350], icon: Icons.coffee_outlined),
  Drink(id: 'milk', name: 'Leche', coefficient: .9, sizes: [200, 250, 350], icon: Icons.local_drink_outlined),
  Drink(id: 'plantmilk', name: 'Leche vegetal', coefficient: .9, sizes: [200, 250, 350], icon: Icons.eco_outlined),
  Drink(id: 'yogurt', name: 'Yogur bebible', coefficient: .85, sizes: [200, 250], icon: Icons.local_drink),
  Drink(id: 'juice', name: 'Jugo natural', coefficient: .88, sizes: [200, 250, 350], icon: Icons.local_bar_outlined),
  Drink(id: 'smoothie', name: 'Batido / smoothie', coefficient: .8, sizes: [300, 400], icon: Icons.blender_outlined),
  Drink(id: 'sports', name: 'Bebida deportiva', coefficient: .95, sizes: [350, 500, 600], icon: Icons.sports_bar_outlined),
  Drink(id: 'ors', name: 'Suero oral', coefficient: 1, sizes: [250, 500], icon: Icons.medical_services_outlined),
  Drink(id: 'soda', name: 'Refresco', coefficient: .9, sizes: [250, 355, 500], icon: Icons.local_drink),
  Drink(id: 'diet_soda', name: 'Refresco light', coefficient: .95, sizes: [250, 355, 500], icon: Icons.local_drink_outlined),
  Drink(id: 'energy', name: 'Bebida energética', coefficient: .8, sizes: [250, 473], icon: Icons.bolt_outlined),
  Drink(id: 'soup', name: 'Sopa / caldo', coefficient: .9, sizes: [250, 350], icon: Icons.ramen_dining_outlined),
  Drink(id: 'kombucha', name: 'Kombucha', coefficient: .9, sizes: [250, 330], icon: Icons.local_drink_outlined),
  Drink(id: 'beer', name: 'Cerveza', coefficient: .6, sizes: [330, 473], icon: Icons.sports_bar),
  Drink(id: 'wine', name: 'Vino', coefficient: .3, sizes: [125, 175], icon: Icons.wine_bar_outlined),
  Drink(id: 'spirits', name: 'Licor / cóctel', coefficient: 0, sizes: [45, 200], icon: Icons.local_bar),
  Drink(id: 'custom', name: 'Personalizada', coefficient: 1, sizes: [250], icon: Icons.star_outline),
];

Drink drinkById(String id, [List<CustomDrink> custom = const []]) {
  if (id.startsWith('custom_') && custom.isNotEmpty) {
    final item = custom.firstWhere((d) => d.id == id, orElse: () => custom.first);
    return Drink(
      id: item.id,
      name: item.name,
      coefficient: item.coefficient,
      sizes: [item.defaultSizeMl],
      icon: customIcon(item.icon),
      color: Color(item.color),
    );
  }
  return drinks.firstWhere((drink) => drink.id == id, orElse: () => drinks.first);
}

IconData customIcon(String name) => {
      'star': Icons.star_outline,
      'drop': Icons.water_drop_outlined,
      'cup': Icons.local_drink_outlined,
      'leaf': Icons.eco_outlined,
      'bolt': Icons.bolt_outlined,
      'heart': Icons.favorite_border,
    }[name] ?? Icons.star_outline;
