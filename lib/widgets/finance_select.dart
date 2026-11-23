import 'package:material_ui/material_ui.dart';

import 'arta_icon.dart';

/// A form selector with the same data contract as a dropdown, presented as a
/// bottom sheet. Form validation and keyboard focus remain standard Flutter.
class FinanceSelect<T> extends FormField<T> {
  @override
  FormFieldState<T> createState() => _FinanceSelectState<T>();
  FinanceSelect({
    super.key,
    super.initialValue,
    required List<DropdownMenuItem<T>>? items,
    required ValueChanged<T?>? onChanged,
    InputDecoration decoration = const InputDecoration(),
    bool isExpanded = false,
    super.validator,
    super.autovalidateMode,
  }) : super(
         enabled: onChanged != null,
         builder: (field) {
           final rows = items ?? <DropdownMenuItem<T>>[];
           final selected = rows
               .where((row) => row.value == field.value)
               .firstOrNull;
           Future<void> choose() async {
             final value = await showModalBottomSheet<T>(
               context: field.context,
               isScrollControlled: true,
               useSafeArea: true,
               builder: (context) => _SelectionSheet<T>(
                 title: decoration.labelText ?? 'Pilih',
                 rows: rows,
                 selected: field.value,
               ),
             );
             if (value != null && field.mounted) {
               field.didChange(value);
               onChanged?.call(value);
             }
           }

           return Semantics(
             button: true,
             enabled: onChanged != null,
             child: InkWell(
               borderRadius: BorderRadius.circular(8),
               onTap: onChanged == null ? null : choose,
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.stretch,
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   if (decoration.labelText != null) ...[
                     Text(
                       decoration.labelText!,
                       style: Theme.of(field.context).textTheme.bodySmall
                           ?.copyWith(fontWeight: FontWeight.w700),
                     ),
                     const SizedBox(height: 8),
                   ],
                   InputDecorator(
                     isEmpty: selected == null,
                     decoration: decoration.copyWith(
                       labelText: '',
                       floatingLabelBehavior: FloatingLabelBehavior.never,
                       enabled: onChanged != null,
                       errorText: field.errorText,
                       suffixIcon: const Padding(
                         padding: EdgeInsets.all(16),
                         child: DesignGlyph('chevron-down', size: 18),
                       ),
                     ),
                     child: selected?.child ?? const SizedBox(height: 20),
                   ),
                 ],
               ),
             ),
           );
         },
       );
}

class _FinanceSelectState<T> extends FormFieldState<T> {
  @override
  void didUpdateWidget(covariant FinanceSelect<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      setValue(widget.initialValue);
    }
  }
}

class _SelectionSheet<T> extends StatefulWidget {
  const _SelectionSheet({
    required this.title,
    required this.rows,
    this.selected,
  });
  final String title;
  final List<DropdownMenuItem<T>> rows;
  final T? selected;
  @override
  State<_SelectionSheet<T>> createState() => _SelectionSheetState<T>();
}

class _SelectionSheetState<T> extends State<_SelectionSheet<T>> {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .78,
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(context),
                  icon: const DesignGlyph('close'),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.rows.length,
              separatorBuilder: (_, _) =>
                  const Divider(indent: 20, endIndent: 20),
              itemBuilder: (context, index) {
                final row = widget.rows[index],
                    active = row.value == widget.selected;
                final colors = Theme.of(context).colorScheme;
                return ListTile(
                  enabled: row.enabled,
                  title: row.child,
                  trailing: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: active ? colors.primary : colors.outline,
                        width: active ? 6 : 1.5,
                      ),
                    ),
                  ),
                  onTap: row.enabled
                      ? () => Navigator.pop(context, row.value)
                      : null,
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}
