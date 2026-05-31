import 'package:flutter/material.dart';
import 'package:meep/core/theme/app_colors.dart';
import 'package:meep/core/theme/app_spacing.dart';
import 'package:meep/core/theme/app_text_styles.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bw900,
      appBar: AppBar(
        backgroundColor: AppColors.bw900,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Điều khoản dịch vụ',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal,
          top: AppSpacing.sm,
          bottom: AppSpacing.xl,
        ),
        child: _TermsContent(),
      ),
    );
  }
}

class _TermsContent extends StatelessWidget {
  const _TermsContent();

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
        const _SectionHeader('Chấp nhận các Điều khoản Dịch vụ này'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Ứng dụng Meep cung cấp các dịch vụ của chúng tôi (được mô tả bên dưới) và nội dung liên quan cho bạn thông qua (các) trang web của chúng tôi đặt tại https://meep.camera/ ("Trang web") và thông qua các ứng dụng di động và các công nghệ liên quan của chúng tôi ("Ứng dụng di động", và nói chung là các Ứng dụng di động và Trang web đó, bao gồm mọi tính năng, chức năng và công nghệ được cập nhật hoặc mới, "Dịch vụ"). Tất cả việc truy cập và sử dụng Dịch vụ đều phải tuân theo các điều khoản và điều kiện có trong các Điều khoản Dịch vụ này (được sửa đổi theo thời gian, các "Điều khoản Dịch vụ" này). Bằng cách truy cập, duyệt hoặc sử dụng Trang web, Ứng dụng di động hoặc bất kỳ khía cạnh nào khác của Dịch vụ, bạn thừa nhận rằng bạn đã đọc, hiểu và đồng ý bị ràng buộc bởi các Điều khoản Dịch vụ này. Nếu bạn không chấp nhận các điều khoản và điều kiện của các Điều khoản Dịch vụ này, bạn sẽ không truy cập, duyệt hoặc sử dụng Dịch vụ.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Chúng tôi bảo lưu quyền, theo quyết định riêng của mình, thay đổi hoặc sửa đổi các phần của các Điều khoản Dịch vụ này bất cứ lúc nào. Nếu chúng tôi làm điều này, chúng tôi sẽ đăng các thay đổi trên trang này và sẽ cho biết ở đầu trang này ngày các Điều khoản Dịch vụ này được sửa đổi lần cuối. Bạn có thể đọc bản sao hiện tại, có hiệu lực của các Điều khoản Dịch vụ này bằng cách truy cập liên kết "Điều khoản Dịch vụ" trên Trang web và trong phần Điều khoản Dịch vụ của Ứng dụng Di động của chúng tôi. Việc bạn tiếp tục sử dụng Dịch vụ sau ngày bất kỳ thay đổi nào như vậy có hiệu lực đồng nghĩa với việc bạn chấp nhận Điều khoản Dịch vụ mới.',
        ),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'VUI LÒNG ĐỌC KỸ CÁC ĐIỀU KHOẢN DỊCH VỤ NÀY, VÌ CHÚNG CHỨA THỎA THUẬN PHÂN XỬ VÀ CÁC THÔNG TIN QUAN TRỌNG KHÁC LIÊN QUAN ĐẾN CÁC QUYỀN, BIỆN PHÁP KHẮC PHỤC VÀ NGHĨA VỤ HỢP PHÁP CỦA BẠN. THỎA THUẬN PHÂN XỬ YÊU CẦU (VỚI MỘT SỐ NGOẠI LỆ HẠN CHẾ) RẰNG BẠN PHẢI GỬI CÁC KHIẾU NẠI MÀ BẠN CÓ ĐỐI VỚI CHÚNG TÔI ĐỂ ĐƯA RA TRỌNG TÀI RÀNG BUỘC VÀ CUỐI CÙNG.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader('Quyền riêng tư của bạn'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Tại Meep, chúng tôi tôn trọng quyền riêng tư của người dùng. Để biết thêm thông tin, vui lòng xem Chính sách quyền riêng tư của chúng tôi, được đặt tại https://meep.camera/privacy và trong phần Chính sách quyền riêng tư của Ứng dụng di động của chúng tôi. Bằng cách sử dụng Dịch vụ, bạn đồng ý với việc chúng tôi thu thập, sử dụng và tiết lộ dữ liệu cá nhân và các dữ liệu khác như được nêu trong đó.',
        ),
        const SizedBox(height: AppSpacing.xl),
        const _SectionHeader('Điều khoản bổ sung'),
        const SizedBox(height: AppSpacing.md),
        const _BodyText(
          'Ngoài ra khi sử dụng một số tính năng nhất định thông qua Dịch vụ, bạn sẽ phải tuân theo bất kỳ điều khoản bổ sung hiện hành nào áp dụng cho các tính năng đó, các điều khoản này có thể được đăng và sửa đổi theo thời gian. Tất cả các điều khoản bổ sung đó được kết hợp vào Điều khoản Dịch vụ này bằng cách tham chiếu.',
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
      textAlign: TextAlign.center,
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
