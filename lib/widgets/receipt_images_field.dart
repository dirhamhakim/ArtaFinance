import 'arta_icon.dart';

import 'package:feather_icons/feather_icons.dart';
import 'package:material_ui/material_ui.dart';

import '../models/receipt_image.dart';
import '../services/photo_picker_service.dart';
import 'finance_empty_state.dart';

class ReceiptImagesField extends StatefulWidget {
  const ReceiptImagesField({
    super.key,
    required this.images,
    required this.onChanged,
  });
  final List<ReceiptImage> images;
  final ValueChanged<List<ReceiptImage>>? onChanged;
  @override
  State<ReceiptImagesField> createState() => _ReceiptImagesFieldState();
}

class _ReceiptImagesFieldState extends State<ReceiptImagesField> {
  bool picking = false;
  Future<void> add() async {
    if (picking ||
        widget.onChanged == null ||
        widget.images.length >= ReceiptImage.maxCount) {
      return;
    }
    final choose = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lampirkan foto struk',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const ArtaIcon(FeatherIcons.image),
                title: const Text('Pilih foto'),
                subtitle: const Text(
                  'Hanya foto yang Anda pilih dapat diakses',
                ),
                onTap: () => Navigator.pop(context, true),
              ),
            ],
          ),
        ),
      ),
    );
    if (choose != true || !mounted) return;
    setState(() => picking = true);
    try {
      final image = await PhotoPickerService().pick();
      if (image != null && mounted) {
        widget.onChanged?.call([...widget.images, image]);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto belum dapat dibuka. Pilih gambar lain.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Foto struk (opsional)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (widget.images.isEmpty)
        const FinanceEmptyState(
          message: 'Struknya belum ada. Simpan fotonya di sini.',
          kind: EmptyKind.receipt,
          compact: true,
        ),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          for (final image in widget.images)
            SizedBox(
              width: 100,
              child: Column(
                children: [
                  InkWell(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (context) => Dialog(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                tooltip: 'Tutup foto',
                                icon: const ArtaIcon(FeatherIcons.x),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            Flexible(
                              child: InteractiveViewer(
                                child: Image.memory(
                                  image.bytes,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) =>
                                      const ArtaIcon(FeatherIcons.image),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        image.bytes,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        cacheWidth: 200,
                        errorBuilder: (_, _, _) => const SizedBox(
                          height: 100,
                          child: ArtaIcon(FeatherIcons.image),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Hapus foto struk',
                    onPressed: picking || widget.onChanged == null
                        ? null
                        : () => widget.onChanged!([
                            ...widget.images.where((v) => v.id != image.id),
                          ]),
                    icon: const ArtaIcon(FeatherIcons.trash2),
                  ),
                ],
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(
        key: const Key('add-receipt'),
        onPressed:
            picking ||
                widget.onChanged == null ||
                widget.images.length >= ReceiptImage.maxCount
            ? null
            : add,
        icon: const ArtaIcon(FeatherIcons.image),
        label: Text(
          picking
              ? 'Menyiapkan foto…'
              : 'Tambah foto (${widget.images.length}/${ReceiptImage.maxCount})',
        ),
      ),
      const Text(
        'Disimpan offline bersama transaksi dan ikut backup. Maksimal 3 foto; foto diperkecil otomatis.',
      ),
    ],
  );
}
