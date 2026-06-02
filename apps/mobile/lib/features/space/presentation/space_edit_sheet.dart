import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/core/theme/hex_color.dart';
import 'package:meep/features/auth/application/auth_providers.dart';
import 'package:meep/features/space/application/space_controller.dart';
import 'package:meep/features/space/data/space.dart';
import 'package:meep/features/space/presentation/widgets/space_config_step.dart';
import 'package:meep/shared/widgets/app_bottom_sheet.dart';
import 'package:meep/shared/widgets/app_primary_button.dart';

/// Sheet chỉnh sửa Space — name + iconEmoji + colorHex.
///
/// Permission: chỉ creator có quyền edit. UI guard layer 1: SettingsSheet
/// chỉ mở sheet nếu `space.creatorId == currentUid`. UI guard layer 2:
/// sheet build re-check (deeplink protection). Client guard layer 3:
/// `SpaceController.updateSpace` fail-fast nếu non-creator. Server CF +
/// rules là final boundary.
///
/// Partial update: chỉ send field đã thay đổi (dirty check vs initial)
/// xuống controller — tiết kiệm CF payload + server refine reject empty.
class SpaceEditSheet extends ConsumerStatefulWidget {
  const SpaceEditSheet({super.key, required this.spaceId});

  final String spaceId;

  @override
  ConsumerState<SpaceEditSheet> createState() => _SpaceEditSheetState();
}

class _SpaceEditSheetState extends ConsumerState<SpaceEditSheet> {
  late final TextEditingController _nameController;

  // Initial values loaded from Space data — dùng để dirty check.
  String _initialName = '';
  String _initialIconEmoji = '';
  String _initialColorHex = '';
  bool _initialized = false;

  // Current edit state.
  String _name = '';
  String _iconEmoji = '';
  String _colorHex = '';

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initFromSpace(Space space) {
    if (_initialized) return;
    _initialized = true;
    _initialName = space.name;
    _initialIconEmoji = space.iconEmoji;
    _initialColorHex = space.colorHex;
    _name = space.name;
    _iconEmoji = space.iconEmoji;
    _colorHex = space.colorHex;
    _nameController.text = space.name;
  }

  bool get _isDirty {
    if (!_initialized) return false;
    return _name.trim() != _initialName ||
        _iconEmoji != _initialIconEmoji ||
        _colorHex.toUpperCase() != _initialColorHex.toUpperCase();
  }

  bool get _canSave => _isDirty && _name.trim().isNotEmpty && !_isSaving;

  Future<void> _save() async {
    if (!_canSave) return;
    final uid = ref.read(currentUidProvider).valueOrNull;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa đăng nhập')),
      );
      return;
    }
    setState(() => _isSaving = true);

    // Partial — chỉ truyền field đã đổi.
    final newName = _name.trim();
    final nameChanged = newName != _initialName;
    final iconChanged = _iconEmoji != _initialIconEmoji;
    final colorChanged =
        _colorHex.toUpperCase() != _initialColorHex.toUpperCase();

    try {
      await ref.read(spaceControllerProvider(uid).notifier).updateSpace(
            spaceId: widget.spaceId,
            name: nameChanged ? newName : null,
            iconEmoji: iconChanged ? _iconEmoji : null,
            colorHex: colorChanged ? _colorHex : null,
          );
      if (!mounted) return;
      // Đọc errorMessage từ controller — nếu set sau call thì update fail.
      final errorMessage = ref.read(spaceControllerProvider(uid)).errorMessage;
      if (errorMessage != null) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã cập nhật Space')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không cập nhật được: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final spaceAsync = ref.watch(spaceByIdProvider(widget.spaceId));
    final uid = ref.watch(currentUidProvider).valueOrNull;

    return AppBottomSheet(
      heightFactor: 0.85,
      child: spaceAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.turquoise500),
        ),
        error: (e, _) => _ErrorView(
          message: 'Lỗi tải Space',
          onClose: () => Navigator.of(context).pop(),
        ),
        data: (space) {
          if (space == null) {
            return _ErrorView(
              message: 'Space không tồn tại hoặc đã bị xoá',
              onClose: () => Navigator.of(context).pop(),
            );
          }
          // Permission guard — non-creator → error view với close.
          if (uid == null || space.creatorId != uid) {
            return _ErrorView(
              message: 'Chỉ creator có quyền chỉnh sửa Space',
              onClose: () => Navigator.of(context).pop(),
            );
          }

          _initFromSpace(space);
          return _EditForm(
            nameController: _nameController,
            iconEmoji: _iconEmoji,
            colorHex: _colorHex,
            isSaving: _isSaving,
            canSave: _canSave,
            onNameChanged: (v) => setState(() => _name = v),
            onPresetSelected: (emoji, color) => setState(() {
              _iconEmoji = emoji;
              _colorHex = color;
            }),
            onSave: _save,
            onClose: () => Navigator.of(context).pop(),
          );
        },
      ),
    );
  }
}

class _EditForm extends StatelessWidget {
  const _EditForm({
    required this.nameController,
    required this.iconEmoji,
    required this.colorHex,
    required this.isSaving,
    required this.canSave,
    required this.onNameChanged,
    required this.onPresetSelected,
    required this.onSave,
    required this.onClose,
  });

  final TextEditingController nameController;
  final String iconEmoji;
  final String colorHex;
  final bool isSaving;
  final bool canSave;
  final ValueChanged<String> onNameChanged;
  final void Function(String emoji, String color) onPresetSelected;
  final VoidCallback onSave;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 16),
          // Header: close button + title
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: 'Đóng',
                  child: GestureDetector(
                    onTap: onClose,
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.close,
                        color: AppColors.bw300,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                'Chỉnh sửa Space',
                style: AppTextStyles.xlBold.copyWith(color: AppColors.bw100),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Preview circle — icon + color hiện tại
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: hexToColor(colorHex),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(iconEmoji, style: const TextStyle(fontSize: 44)),
          ),
          const SizedBox(height: 24),
          // Section: Tên Space
          const _SectionHeader(
            icon: Icons.text_fields,
            label: 'Tên Space',
          ),
          const SizedBox(height: 12),
          _NameField(controller: nameController, onChanged: onNameChanged),
          const SizedBox(height: 24),
          // Section: Theme (8 preset chips)
          const _SectionHeader(
            icon: Icons.palette_outlined,
            label: 'Space theme',
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                for (final preset in kSpacePresets)
                  _PresetCircle(
                    preset: preset,
                    isSelected: iconEmoji == preset.emoji &&
                        colorHex.toUpperCase() == preset.colorHex.toUpperCase(),
                    onTap: () =>
                        onPresetSelected(preset.emoji, preset.colorHex),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(
            label: 'Lưu thay đổi',
            showTrailingIcon: false,
            isLoading: isSaving,
            onPressed: canSave ? onSave : null,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFFD5D5D5)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.baseBold.copyWith(
            color: const Color(0xFFDDDDDD),
          ),
        ),
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF363636),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
      child: TextField(
        controller: controller,
        maxLength: 30,
        onChanged: onChanged,
        style: AppTextStyles.mdSemiBold.copyWith(color: AppColors.bw100),
        decoration: InputDecoration(
          hintText: 'Tên Space',
          hintStyle: AppTextStyles.mdSemiBold.copyWith(
            color: const Color(0x80FFFFFF),
          ),
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _PresetCircle extends StatelessWidget {
  const _PresetCircle({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  final SpacePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: hexToColor(preset.colorHex),
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: AppColors.turquoise500, width: 3)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              preset.emoji,
              style: const TextStyle(fontSize: 30),
            ),
          ),
          if (isSelected)
            const Positioned(
              top: -2,
              right: -2,
              child: _SelectedBadge(),
            ),
        ],
      ),
    );
  }
}

class _SelectedBadge extends StatelessWidget {
  const _SelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: AppColors.bw800,
        shape: BoxShape.circle,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.turquoise500,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 12, color: AppColors.bw900),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 48, color: AppColors.bw400),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.mdBold.copyWith(color: AppColors.bw100),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppPrimaryButton(
            label: 'Đóng',
            showTrailingIcon: false,
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
