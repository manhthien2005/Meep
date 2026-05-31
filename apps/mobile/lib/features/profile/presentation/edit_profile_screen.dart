import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/profile/presentation/avatar_picker_sheet.dart';

// ─── Bio tooltip — từ Figma frame 719:4240 ───────────────────────────────────
const _kBioTooltip = 'Tiểu sử của bạn sẽ hiển thị với bạn bè của bạn. '
    'Phần giới thiệu bản thân được giới hạn tối đa 150 chữ.';

// ─── MOCK DATA — xoá khi wire ProfileController ───────────────────────────────
// Figma: "Jana Kim" / "@janakimmm"
const _kDisplayName = 'Jana Kim';
const _kUsername = '@janakimmm';
const _kDateOfBirth = '01/01/2000';
const _kPhone = '0101200000';
const _kEmail = 'nguyenvana@gmail.com';
const _kGender = 'Nữ';
const _kBio = 'nhìn cái choá zì ???';

// ─── Missing design tokens — ping leader để add vào core/theme/ ───────────────
// #73706E → backButtonFill
const _cBackBtn = Color(0xFF73706E);
const _cSectionLabel = Color(0xFFDDDDDD);

// ─── SVG icon paths ───────────────────────────────────────────────────────────
const _iCaseSensitive = 'assets/icons/ic_case_sensitive.svg';
const _iAtSign = 'assets/icons/ic_at_sign.svg';
const _iCake = 'assets/icons/ic_cake.svg';
const _iPhone = 'assets/icons/ic_phone.svg';
const _iMail = 'assets/icons/ic_mail.svg';
const _iPerson = 'assets/icons/ic_person.svg';
const _iPencilLine = 'assets/icons/ic_pencil_line.svg';
const _iBell = 'assets/icons/ic_bell.svg';
const _iChevronLeft = 'assets/icons/ic_chevron_left.svg';
const _iInfo = 'assets/icons/ic_info.svg';

// ─── Helper ───────────────────────────────────────────────────────────────────
Widget _svgIcon(
  String path, {
  double size = 24,
  Color color = AppColors.bw100,
}) =>
    SvgPicture.asset(
      path,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bw900,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Topbar(onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: SingleChildScrollView(
                // Fix #5: padding horizontal 28 — divider tidak perlu indent tambahan
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _AvatarSection(
                      onEditTap: () => _showAvatarPicker(context),
                    ),
                    const SizedBox(height: 20),
                    _SettingsSection(
                      notificationsEnabled: _notificationsEnabled,
                      onNotificationToggle: (v) =>
                          setState(() => _notificationsEnabled = v),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAvatarPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const AvatarPickerSheet(),
    );
  }
}

// ─── Topbar ───────────────────────────────────────────────────────────────────

class _Topbar extends StatelessWidget {
  const _Topbar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(27, 9, 27, 9),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Quay lại',
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _cBackBtn,
                  shape: BoxShape.circle,
                ),
                // Fix #8: SVG chevron-left từ Figma
                child: Center(
                  child: _svgIcon(
                    _iChevronLeft,
                    size: 24,
                    color: AppColors.bw300,
                  ),
                ),
              ),
            ),
          ),
          // Fix #1: gap = 37px để title đúng vị trí (x=77 trong Figma)
          const SizedBox(width: 37),
          const Expanded(
            child: Text(
              'Chỉnh sửa trang cá nhân',
              // Fix #1: Figma = 18px Bold → TextStyle trực tiếp (không có baseBold)
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 24 / 18,
                color: AppColors.bw100,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Avatar section ───────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({required this.onEditTap});

  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fix #2: avatar offset = 53px (main-info x=43 + ava padding-left=10)
            const SizedBox(width: 53),
            // Figma: active-stories stroke #d9d9d9 (80×80) + 3.54px gap + persona (72.91×72.91)
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD9D9D9), width: 1.5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.bw700,
                  ),
                  child: const Center(
                    child: Text(
                      'J',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.bw100,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Fix #2: gap avatar → text = 25px
            const SizedBox(width: 25),
            Semantics(
              button: true,
              label: 'Chỉnh sửa ảnh đại diện',
              child: GestureDetector(
                onTap: onEditTap,
                child: Text(
                  'Chỉnh sửa ảnh đại diện',
                  style: AppTextStyles.smSemiBold.copyWith(
                    color: AppColors.turquoise600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Fix #5: Divider không có indent — đã trong padding 28px của parent
        Divider(
          color: AppColors.bw100.withValues(alpha: 0.5),
          thickness: 1,
        ),
      ],
    );
  }
}

// ─── Settings section ─────────────────────────────────────────────────────────

class _SettingsSection extends StatefulWidget {
  const _SettingsSection({
    required this.notificationsEnabled,
    required this.onNotificationToggle,
  });

  final bool notificationsEnabled;
  final ValueChanged<bool> onNotificationToggle;

  @override
  State<_SettingsSection> createState() => _SettingsSectionState();
}

class _SettingsSectionState extends State<_SettingsSection> {
  bool _showBioTooltip = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông tin cá nhân',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 24 / 18,
            color: _cSectionLabel,
          ),
        ),
        const SizedBox(height: 20),
        _SettingsRow(
          iconPath: _iCaseSensitive,
          label: 'Chỉnh sửa họ tên',
          value: _kDisplayName,
          onTap: () {
            // TODO(T5): open displayName input sheet
          },
        ),
        _SettingsRow(
          iconPath: _iAtSign,
          label: 'Chỉnh sửa tên người dùng',
          value: _kUsername,
          onTap: () {
            // TODO(T5): open username input sheet + uniqueness check
          },
        ),
        _SettingsRow(
          iconPath: _iCake,
          label: 'Chỉnh sửa ngày sinh',
          value: _kDateOfBirth,
          onTap: () {
            // TODO(T5): open date picker sheet
          },
        ),
        _SettingsRow(
          iconPath: _iPhone,
          label: 'Cập nhật số điện thoại',
          value: _kPhone,
          onTap: () {
            // TODO(T5): open phone input sheet
          },
        ),
        _SettingsRow(
          iconPath: _iMail,
          label: 'Cập nhật địa chỉ email',
          value: _kEmail,
          onTap: () {
            // TODO(T5): open email input + re-auth flow
          },
        ),
        _SettingsRow(
          iconPath: _iPerson,
          label: 'Chỉnh sửa giới tính',
          value: _kGender,
          onTap: () {
            // TODO(T5): open gender picker sheet
          },
        ),
        // Figma: Tiểu sử row — info icon 719:4035 toggles tooltip (frame 719:4240)
        _SettingsRow(
          iconPath: _iPencilLine,
          label: 'Tiểu sử',
          value: _kBio,
          onInfoTap: () => setState(() => _showBioTooltip = !_showBioTooltip),
          expandedContent: _showBioTooltip
              ? const Text(
                  _kBioTooltip,
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    height: 16 / 12,
                    color: AppColors.bw600,
                  ),
                )
              : null,
          onTap: () {
            // TODO(T5): open bio input sheet (max 150 chars)
          },
        ),
        const SizedBox(height: 13),
        _NotificationRow(
          enabled: widget.notificationsEnabled,
          onToggle: widget.onNotificationToggle,
        ),
      ],
    );
  }
}

// ─── Settings row ─────────────────────────────────────────────────────────────

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.iconPath,
    required this.label,
    required this.value,
    required this.onTap,
    this.onInfoTap,
    this.expandedContent,
  });

  final String iconPath;
  final String label;
  final String value;
  final VoidCallback onTap;
  // When set, shows ic_info.svg next to the label; tapping it calls this callback.
  final VoidCallback? onInfoTap;
  // Shown below the row (with 10px gap) when non-null — used for bio tooltip.
  final Widget? expandedContent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: _svgIcon(iconPath, size: 24),
                  ),
                  const SizedBox(width: 23),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              label,
                              style: AppTextStyles.mdRegular.copyWith(
                                color: AppColors.bw100,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (onInfoTap != null) ...[
                              const SizedBox(width: 8),
                              // Figma: info icon 12×12, stroke bw500, id 719:4035
                              GestureDetector(
                                onTap: onInfoTap,
                                behavior: HitTestBehavior.opaque,
                                child: SvgPicture.asset(
                                  _iInfo,
                                  width: 12,
                                  height: 12,
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.bw500,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          value,
                          style: AppTextStyles.smRegular
                              .copyWith(color: AppColors.bw400),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (expandedContent != null) ...[
                const SizedBox(height: 10),
                expandedContent!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Notification toggle row ──────────────────────────────────────────────────

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.enabled, required this.onToggle});

  final bool enabled;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            // Fix #8: SVG bell icon 20×20
            SizedBox(
              width: 20,
              height: 20,
              child: _svgIcon(_iBell, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Thông báo',
                style: AppTextStyles.mdRegular.copyWith(
                  color: AppColors.bw100,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: enabled,
              onChanged: onToggle,
              // TODO(T5): lưu vào SharedPreferences key: notification_enabled
              activeThumbColor: AppColors.turquoise500,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: const Color(0xFFE5E5E5),
            ),
          ],
        ),
      ),
    );
  }
}
