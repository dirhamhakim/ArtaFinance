import 'package:material_ui/material_ui.dart';

Future<T?> showFinanceDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) async {
  final navigator = Navigator.of(context);
  final route = ModalBottomSheetRoute<T>(
    builder: builder,
    capturedThemes: InheritedTheme.capture(
      from: context,
      to: navigator.context,
    ),
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    modalBarrierColor:
        Theme.of(context).bottomSheetTheme.modalBarrierColor ??
        const Color(0x99000000),
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: barrierDismissible,
    enableDrag: barrierDismissible,
  );
  final result = await navigator.push<T>(route);
  // A pop result precedes the exit animation. Callers may safely release
  // controllers only after the route has actually removed its overlay.
  await route.completed;
  return result;
}

/// Financial confirmations, password forms and previews use one bottom-sheet
/// surface. The entire sheet can scroll on short screens or with large text.
class FinanceDialog extends StatelessWidget {
  const FinanceDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.scrollable = false,
  });
  final Widget? title, content;
  final List<Widget>? actions;
  final bool scrollable;
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(
      maxHeight: MediaQuery.sizeOf(context).height * .86,
    ),
    child: SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              DefaultTextStyle(
                style: Theme.of(context).textTheme.titleLarge!,
                child: title!,
              ),
            if (content != null) ...[const SizedBox(height: 16), content!],
            if (actions?.isNotEmpty == true) ...[
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: actions!,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}
