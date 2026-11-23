import 'arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

/// Visibilitas hanya untuk field ini dan selalu tersembunyi saat dibuka ulang.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool visible = false;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    obscureText: !visible,
    enableSuggestions: false,
    autocorrect: false,
    decoration: InputDecoration(
      labelText: widget.label,
      suffixIcon: IconButton(
        tooltip:
            '${visible ? 'Sembunyikan' : 'Tampilkan'} ${widget.label.toLowerCase()}',
        onPressed: () => setState(() => visible = !visible),
        icon: ArtaIcon(visible ? FeatherIcons.eyeOff : FeatherIcons.eye),
      ),
    ),
    validator: widget.validator,
  );
}
