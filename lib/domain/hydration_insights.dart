import 'models.dart';

/// How pressing an insight is. Drives colour/icon in the UI.
enum InsightLevel { info, caution, urgent }

enum InsightKind { fastIntake, overGoal, lowStreak }

class HydrationInsight {
  const HydrationInsight({
    required this.kind,
    required this.level,
    required this.title,
    required this.body,
  });
  final InsightKind kind;
  final InsightLevel level;
  final String title;
  final String body;
}

/// Effective ml logged in the last hour above which the kidneys struggle to
/// keep up. NIOSH recommends never exceeding ~1.4 L/h even in heat, so we warn
/// well before that.
const fastIntakeCautionMlPerHour = 1000;
const fastIntakeUrgentMlPerHour = 1400;

/// Fraction of the daily goal above which we point out the excess.
const overGoalRatio = 1.5;

/// Consecutive completed days under [lowDayRatio] of the goal before we
/// mention possible under-hydration.
const lowDayRatio = 0.5;
const lowStreakInfoDays = 3;
const lowStreakCautionDays = 5;

const insightDisclaimer =
    'HydraFlow orienta, no diagnostica. Si tienes síntomas persistentes o '
    'una condición médica, consulta a un profesional de salud.';

/// Non-diagnostic hydration guidance derived from the log.
///
/// Sources: NIOSH heat-stress hydration guidance (max ~1.4 L/h), Mayo Clinic on
/// hyponatremia from excess water, NHS on dehydration signs.
List<HydrationInsight> hydrationInsightsFor({
  required List<IntakeEntry> entries,
  required int goalMl,
  required DateTime now,
}) {
  final goal = goalMl <= 0 ? 1 : goalMl;
  final insights = <HydrationInsight>[];

  final lastHour = entries
      .where(
        (e) =>
            !e.timestamp.isAfter(now) &&
            now.difference(e.timestamp) < const Duration(hours: 1),
      )
      .fold(0, (sum, e) => sum + e.effectiveMl);
  if (lastHour >= fastIntakeUrgentMlPerHour) {
    insights.add(
      const HydrationInsight(
        kind: InsightKind.fastIntake,
        level: InsightLevel.urgent,
        title: 'Estás bebiendo demasiado rápido',
        body:
            'Llevas más de 1,4 L en la última hora. Beber tanto y tan seguido '
            'puede diluir el sodio en sangre (hiponatremia). Haz una pausa; si '
            'notas náuseas, dolor de cabeza fuerte o confusión, busca atención '
            'médica.',
      ),
    );
  } else if (lastHour >= fastIntakeCautionMlPerHour) {
    insights.add(
      const HydrationInsight(
        kind: InsightKind.fastIntake,
        level: InsightLevel.caution,
        title: 'Ritmo muy alto en la última hora',
        body:
            'Ya superaste 1 L en una hora. Los riñones eliminan alrededor de '
            '1 L por hora, así que es mejor repartir los sorbos a lo largo del '
            'día que beber mucho de golpe.',
      ),
    );
  }

  final today = entries
      .where((e) => _sameDay(e.timestamp, now))
      .fold(0, (sum, e) => sum + e.effectiveMl);
  if (today >= goal * overGoalRatio) {
    insights.add(
      HydrationInsight(
        kind: InsightKind.overGoal,
        level: InsightLevel.caution,
        title: 'Vas muy por encima de tu meta',
        body:
            'Hoy llevas ${(today / goal * 100).round()} % de tu meta. Salvo '
            'que hagas ejercicio intenso o haga mucho calor, no necesitas más. '
            'El exceso de agua puede bajar el sodio: cansancio, náuseas, dolor '
            'de cabeza o calambres son señales para frenar.',
      ),
    );
  }

  // Only days since the first log count: no data is not the same as no water.
  final firstLog = entries.isEmpty
      ? null
      : entries.map((e) => e.timestamp).reduce((a, b) => a.isBefore(b) ? a : b);
  var lowDays = 0;
  var day = DateTime(now.year, now.month, now.day - 1);
  while (firstLog != null &&
      !day.isBefore(DateTime(firstLog.year, firstLog.month, firstLog.day)) &&
      lowDays < 30) {
    final total = entries
        .where((e) => _sameDay(e.timestamp, day))
        .fold(0, (sum, e) => sum + e.effectiveMl);
    if (total >= goal * lowDayRatio) break;
    lowDays++;
    day = day.subtract(const Duration(days: 1));
  }
  if (lowDays >= lowStreakCautionDays) {
    insights.add(
      HydrationInsight(
        kind: InsightKind.lowStreak,
        level: InsightLevel.caution,
        title: 'Llevas $lowDays días con poca hidratación',
        body:
            'Varios días por debajo de la mitad de tu meta. Presta atención a '
            'orina amarilla oscura y con olor fuerte, orinar poco, sed, dolor de '
            'cabeza, mareo al levantarte, boca seca o cansancio. Si estos '
            'síntomas persisten, consulta a un profesional de salud.',
      ),
    );
  } else if (lowDays >= lowStreakInfoDays) {
    insights.add(
      HydrationInsight(
        kind: InsightKind.lowStreak,
        level: InsightLevel.info,
        title: 'Días flojos de hidratación',
        body:
            'Los últimos $lowDays días quedaste por debajo de la mitad de tu '
            'meta. Una señal fácil: si tu orina es amarilla oscura o sientes la '
            'boca seca, tu cuerpo pide agua. Reparte pequeños sorbos durante el '
            'día.',
      ),
    );
  }

  return insights;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
