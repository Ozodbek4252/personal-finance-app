import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/icons/app_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_icon.dart';
import '../../core/widgets/option_sheet.dart';
import '../../data/receipts/receipt_store.dart';

/// Asks "Take photo" or "Choose from library", opens the picker and
/// saves the photo. Returns the stored file name, or null if cancelled.
Future<String?> pickReceipt(BuildContext context, WidgetRef ref) async {
  final source = await showOptionSheet<ReceiptSource>(
    context,
    title: 'Receipt photo',
    options: const [
      SheetOption(
        value: ReceiptSource.camera,
        label: 'Take photo',
        leading: AppIcon(AppIcons.receipt),
      ),
      SheetOption(
        value: ReceiptSource.gallery,
        label: 'Choose from library',
        leading: AppIcon(AppIcons.inbox),
      ),
    ],
  );
  if (source == null) return null;
  final path = await ref.read(receiptPickerProvider)(source);
  if (path == null) return null;
  return ref.read(receiptStoreProvider).save(path);
}

/// Small preview of a receipt photo. Shows a receipt icon while loading
/// or when the file is missing.
class ReceiptThumb extends ConsumerWidget {
  const ReceiptThumb({
    super.key,
    required this.name,
    this.width = 56,
    this.height = 72,
  });

  final String name;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colors;
    final file = ref.watch(receiptFileProvider(name)).value;
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(width < 56 ? 8 : 10),
        border: Border.all(color: c.divider),
      ),
      child: file == null
          ? Center(
              child: AppIcon(
                AppIcons.receipt,
                size: width < 56 ? 20 : 24,
                strokeWidth: 1.5,
                color: c.textTertiary,
              ),
            )
          : Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: (width * 3).round(),
              semanticLabel: 'Receipt photo',
            ),
    );
  }
}

/// Opens the receipt photo full screen. Pinch to zoom.
Future<void> showReceiptViewer(
  BuildContext context,
  WidgetRef ref,
  String name,
) async {
  final file = await ref.read(receiptStoreProvider).file(name);
  if (file == null || !context.mounted) return;
  await showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierColor: Colors.black87,
    builder: (context) => GestureDetector(
      onTap: () => Navigator.pop(context),
      child: InteractiveViewer(
        maxScale: 5,
        child: Center(child: Image.file(file)),
      ),
    ),
  );
}
