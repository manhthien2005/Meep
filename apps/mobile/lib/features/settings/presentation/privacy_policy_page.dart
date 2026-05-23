import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';
import 'package:meep/features/settings/presentation/widgets/settings_scaffold.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScaffold(
      title: 'Chính sách quyền riêng tư',
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        child: _PolicyContent(),
      ),
    );
  }
}

class _PolicyContent extends StatelessWidget {
  const _PolicyContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Ngày có hiệu lực: 25 tháng 05 năm 2026',
          style: AppTextStyles.mdRegular.copyWith(color: AppColors.bw500),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        const _SectionHeader('1. Giới thiệu'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Ứng dụng Meep cung cấp các dịch vụ của chúng tôi (được mô tả bên dưới) và nội dung liên quan cho bạn thông qua (các) trang web của chúng tôi đặt tại https://meep.camera/ ("Trang web") và thông qua các ứng dụng di động và các công nghệ liên quan của chúng tôi ("Ứng dụng di động"). Tất cả việc truy cập và sử dụng Dịch vụ đều phải tuân theo các điều khoản và điều kiện có trong Chính sách quyền riêng tư này.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Chúng tôi bảo lưu quyền, theo quyết định riêng của mình, thay đổi hoặc sửa đổi các phần của Chính sách quyền riêng tư này bất cứ lúc nào. Nếu chúng tôi làm điều này, chúng tôi sẽ đăng các thay đổi trên trang này và sẽ cho biết ở đầu trang này ngày Chính sách quyền riêng tư này được sửa đổi lần cuối.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'VUI LÒNG ĐỌC KỸ CHÍNH SÁCH QUYỀN RIÊNG TƯ NÀY, VÌ CHÚNG CHỨA CÁC THÔNG TIN QUAN TRỌNG LIÊN QUAN ĐẾN CÁC QUYỀN VÀ NGHĨA VỤ HỢP PHÁP CỦA BẠN.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader('2. Thông tin chúng tôi thu thập'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Chúng tôi thu thập thông tin bạn cung cấp trực tiếp cho chúng tôi, chẳng hạn như khi bạn tạo tài khoản, tải ảnh lên, kết nối với bạn bè hoặc liên hệ với chúng tôi để được hỗ trợ. Các loại thông tin chúng tôi có thể thu thập bao gồm tên, địa chỉ email, tên người dùng, ảnh đại diện, ảnh bạn chia sẻ và bất kỳ thông tin nào khác bạn chọn cung cấp.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader('3. Cách chúng tôi sử dụng thông tin của bạn'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Chúng tôi sử dụng thông tin chúng tôi thu thập để cung cấp, duy trì và cải thiện Dịch vụ của chúng tôi, xử lý các giao dịch, gửi cho bạn thông báo kỹ thuật và thông điệp hỗ trợ, và trả lời ý kiến và câu hỏi của bạn.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader('4. Chia sẻ thông tin'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Chúng tôi không chia sẻ thông tin cá nhân về bạn với các công ty, tổ chức và cá nhân bên ngoài Meep, ngoại trừ trong các trường hợp sau: Với sự đồng ý của bạn, vì lý do pháp lý, hoặc để bảo vệ quyền và tài sản của Meep.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader('5. Bảo mật'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Chúng tôi thực hiện các biện pháp bảo mật hợp lý để bảo vệ thông tin của bạn khỏi bị mất mát, đánh cắp, lạm dụng và truy cập trái phép, tiết lộ, thay đổi và hủy hoại.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader('6. Liên hệ'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Nếu bạn có bất kỳ câu hỏi nào về Chính sách quyền riêng tư này, vui lòng liên hệ với chúng tôi tại https://meep.camera/privacy hoặc qua ứng dụng Meep.',
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.mdBold.copyWith(color: Colors.white),
      textAlign: TextAlign.left,
    );
  }
}

class _BodyText extends StatelessWidget {
  const _BodyText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.smRegular.copyWith(
        color: Colors.white,
        height: 1.28,
      ),
      textAlign: TextAlign.justify,
    );
  }
}
