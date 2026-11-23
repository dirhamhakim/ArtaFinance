import 'package:material_ui/material_ui.dart';

import 'arta_icon.dart';

String financeDateLabel(String value) {
  final date = DateTime.parse(value);
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class FinanceDateField extends StatelessWidget {
  const FinanceDateField({
    super.key,
    required this.value,
    this.label = 'Tanggal',
    required this.onTap,
    this.glyph = 'calendar',
  });
  final String value, label, glyph;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: InputDecorator(
          decoration: InputDecoration(
            enabled: onTap != null,
            suffixIcon: Padding(
              padding: const EdgeInsets.all(16),
              child: DesignGlyph(glyph, size: 20),
            ),
          ),
          child: Text(value),
        ),
      ),
    ],
  );
}
