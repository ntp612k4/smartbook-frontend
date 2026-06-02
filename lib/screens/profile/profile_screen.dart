import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Lấy version app
import 'package:smart_reader/repositories/user_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:smart_reader/screens/auth/bloc/auth_bloc.dart';
import 'package:smart_reader/screens/auth/bloc/auth_event.dart';
import 'package:smart_reader/screens/auth/bloc/auth_state.dart';
import 'package:smart_reader/screens/home/home_screen.dart';
import 'package:smart_reader/screens/profile/bloc/profile_bloc.dart';
import 'package:smart_reader/screens/profile/bloc/profile_event.dart';
import 'package:smart_reader/screens/profile/bloc/profile_state.dart';
import 'package:smart_reader/theme/app_colors.dart';
import 'package:smart_reader/widgets/footer/footer.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        userRepository: context.read<UserRepository>(),
      )..add(LoadUserProfileEvent()),
      child: const _ProfileScreenContent(),
    );
  }
}

class _ProfileScreenContent extends StatelessWidget {
  const _ProfileScreenContent();

  // --- HÀM HỖ TRỢ (HELPER METHODS) ---

  // 1. Gửi email hỗ trợ
  Future<void> _sendSupportEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hotro.smartbook@gmail.com', // Thay email của bạn
      query: 'subject=Hỗ trợ người dùng SmartBook',
    );
    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Không thể mở ứng dụng email');
    }
  }

  // 2. Hiển thị Dialog Giới thiệu (About)
  Future<void> _showAboutDialog(BuildContext context) async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (context.mounted) {
      showAboutDialog(
        context: context,
        applicationName: "Smart Book",
        applicationVersion: "Phiên bản ${packageInfo.version}",
        applicationIcon: const Icon(
          Icons.menu_book_rounded,
          size: 50,
          color: AppColors.primary,
        ),
        children: [
          const SizedBox(height: 20),
          const Text(
            "Ứng dụng đọc sách thông minh giúp bạn xây dựng thói quen đọc sách mỗi ngày.",
          ),
          const SizedBox(height: 10),
          const Text("Phát triển bởi Team SmartBook."),
        ],
      );
    }
  }

  // Hàm xử lý chọn ảnh và upload
  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    // Mở thư viện ảnh
    final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50 // Nén ảnh lại cho nhẹ (quan trọng)
        );

    if (pickedFile == null) return; // User hủy chọn

    // Hiện loading
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Đang cập nhật ảnh...")),
    );

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Bạn cần đăng nhập để đổi ảnh")),
        );
      }
      return;
    }

    final repo = context.read<UserRepository>();

    try {
      // 1. Upload lên Storage
      final String downloadUrl =
          await repo.uploadAvatar(File(pickedFile.path), user.uid);

      // 2. Cập nhật Profile
      await repo.updateUserProfile(userId: user.uid, photoUrl: downloadUrl);

      // 3. Reload Bloc để UI hiển thị ảnh mới ngay lập tức
      if (context.mounted) {
        context.read<ProfileBloc>().add(LoadUserProfileEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đổi ảnh thành công!")),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    }
  }

  // 3. Dialog xác nhận đăng xuất
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Đóng dialog
                // Gọi AuthBloc để xử lý logic đăng xuất
                context.read<AuthBloc>().add(LogoutEvent());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Đăng xuất'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          ),
        ),
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {
              // Menu mở rộng (nếu cần)
            },
          ),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          // Lắng nghe sự kiện đăng xuất thành công để chuyển màn hình
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthUnauthenticated) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login', // Đảm bảo route này đúng với main.dart
                  (route) => false,
                );
              }
            },
          ),
          BlocListener<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileError) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(state.message)));
              }
            },
          ),
        ],
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProfileLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // --- HEADER: AVATAR & TÊN ---
                    Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => _pickAndUploadImage(context),
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 40,
                                  backgroundColor:
                                      AppColors.primary.withOpacity(0.1),
                                  backgroundImage: state.user.photoURL != null
                                      ? NetworkImage(state.user.photoURL!)
                                      : null,
                                  child: state.user.photoURL == null
                                      ? const Icon(Icons.person,
                                          size: 40, color: AppColors.primary)
                                      : null,
                                ),

                                // --- ICON MÁY ẢNH (Thêm vào góc dưới) ---
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                        boxShadow: [
                                          BoxShadow(
                                              color: Colors.black12,
                                              blurRadius: 4)
                                        ]),
                                    child: const Icon(Icons.camera_alt,
                                        size: 14, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            state.user.displayName ?? 'Người dùng',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            state.userTitle, // Ví dụ: "Thành viên tích cực"
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- THỐNG KÊ ĐỌC SÁCH ---
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Thống kê đọc sách',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  '${state.stats.booksRead}',
                                  'Sách\nđã đọc',
                                  Colors.teal[50]!,
                                  Colors.teal[700]!,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  '${state.stats.dayStreak}',
                                  'Chuỗi\nngày',
                                  Colors.pink[50]!,
                                  Colors.pink[700]!,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  '${(state.stats.totalMinutes / 60).toStringAsFixed(0)}h',
                                  'Thời gian\nđọc',
                                  Colors.orange[50]!,
                                  Colors.orange[700]!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- MENU TÙY CHỌN ---
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            Icons.settings,
                            'Cài đặt',
                            'Tùy chọn & thông báo',
                            Colors.grey[600]!,
                            () {
                              // Điều hướng đến trang Settings
                              // Navigator.pushNamed(context, '/settings');
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            Icons.help,
                            'Trợ giúp & Hỗ trợ',
                            'Liên hệ để được giải đáp',
                            Colors.blue[600]!,
                            _sendSupportEmail, // Gọi hàm mở email
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            Icons.info,
                            'Giới thiệu',
                            'Thông tin ứng dụng & chính sách',
                            Colors.purple[600]!,
                            () => _showAboutDialog(
                              context,
                            ), // Gọi dialog giới thiệu
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            Icons.logout,
                            'Đăng xuất',
                            'Thoát khỏi tài khoản',
                            Colors.red[600]!,
                            () => _showLogoutDialog(
                              context,
                            ), // Gọi dialog đăng xuất
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              );
            }

            return const Center(child: Text('Không thể tải hồ sơ'));
          },
        ),
      ),
      bottomNavigationBar: CustomFooter(
        selectedIndex: 3, // Profile là index 3
        onItemSelected: (index) {
          // Footer đã tự xử lý việc điều hướng (thường là dùng Navigator)
          // Code ở đây chỉ xử lý logic phụ nếu cần
        },
      ),
    );
  }

  // Widget thẻ thống kê
  Widget _buildStatCard(
    String value,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: textColor.withOpacity(0.8),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // Widget dòng menu
  Widget _buildMenuItem(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, color: Colors.grey[200], indent: 60);
  }
}
