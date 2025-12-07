import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sverd_barbershop/presentation/pages/auth/auth_page.dart';
import 'package:sverd_barbershop/core/services/notification_service.dart';
import 'package:sverd_barbershop/core/theme/colors.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  String _email = 'user@email.com';
  String _displayName = 'Guest';
  bool _isEditing = false;

  String _imagePath = '';

  // Service Notifikasi
  final NotificationService _notificationService = NotificationService();

  // Notification settings
  bool _notificationEnabled = false;
  int _notificationInterval = 30;

  // Default message untuk kesan dan pesan
  static const String _defaultMessage =
      'Aplikasi ini sangat membantu dalam pemesanan layanan barbershop. '
      'Interface-nya user-friendly dan fitur notifikasi pengingatnya sangat berguna. '
      'Terima kasih kepada tim developer yang telah membuat aplikasi ini!';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _loadNotificationSettings();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    final box = Hive.box('sverd_box');
    final currentUser = box.get('currentUser') ?? {};
    final String emailKey = currentUser['email'] ?? '';

    if (emailKey.isNotEmpty) {
      final userData = box.get(emailKey) ?? {};
      _email = emailKey;
      _displayName = userData['username'] ?? 'Guest';
      _fullNameController.text = userData['fullName'] ?? _displayName;
      _phoneController.text = userData['phone'] ?? '';
      _imagePath = userData['imagePath'] ?? '';
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _loadNotificationSettings() {
    setState(() {
      _notificationEnabled = _notificationService.isNotificationEnabled();
      _notificationInterval = _notificationService.getNotificationInterval();
    });
  }

  // UPDATE: Fungsi ini sekarang menerima parameter ImageSource (Camera/Gallery)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      if (kIsWeb) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      } else {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = p.basename(pickedFile.path);
        // Copy file dari cache kamera/galeri ke penyimpanan lokal aplikasi
        final savedImage = await File(
          pickedFile.path,
        ).copy('${appDir.path}/$fileName');
        setState(() {
          _imagePath = savedImage.path;
        });
      }
    }
  }

  // BARU: Menampilkan Bottom Sheet untuk memilih Kamera atau Galeri
  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library, color: kPrimaryColor),
                title: const Text('Ambil dari Galeri',
                    style: TextStyle(color: kTextColor)),
                onTap: () {
                  _pickImage(ImageSource.gallery);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: kPrimaryColor),
                title: const Text('Gunakan Kamera',
                    style: TextStyle(color: kTextColor)),
                onTap: () {
                  _pickImage(ImageSource.camera);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveUpdates() {
    final box = Hive.box('sverd_box');
    final userData = box.get(_email);

    if (userData != null) {
      userData['username'] = _fullNameController.text;
      userData['fullName'] = _fullNameController.text;
      userData['phone'] = _phoneController.text;
      userData['imagePath'] = _imagePath;

      box.put(_email, userData);

      final currentUserData = box.get('currentUser');
      currentUserData['username'] = _fullNameController.text;
      box.put('currentUser', currentUserData);

      setState(() {
        _displayName = _fullNameController.text;
        _isEditing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  void _cancelEdit() {
    _loadProfileData();
    setState(() {
      _isEditing = false;
    });
  }

  void logout() {
    final box = Hive.box('sverd_box');
    box.delete('currentUser');

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
        (route) => false,
      );
    }
  }

  ImageProvider _buildProfileImage() {
    if (_imagePath.isEmpty) {
      return const AssetImage('');
    }
    if (kIsWeb) {
      return NetworkImage(_imagePath);
    }
    return FileImage(File(_imagePath));
  }

  Future<void> _toggleNotification(bool value) async {
    setState(() {
      _notificationEnabled = value;
    });

    try {
      if (value) {
        await _notificationService.scheduleRepeatingNotification(
          intervalDays: _notificationInterval,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifikasi diaktifkan!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await _notificationService.cancelAllNotifications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifikasi dinonaktifkan'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error mengubah notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      _loadNotificationSettings();
    }
  }

  Future<void> _updateNotificationInterval(int days) async {
    setState(() {
      _notificationInterval = days;
    });

    if (_notificationEnabled) {
      await _notificationService.scheduleRepeatingNotification(
          intervalDays: days);
    } else {
      await _notificationService.updateNotificationInterval(days);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Interval notifikasi diubah menjadi $days hari.'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  Future<void> _testNotificationInstant() async {
    try {
      await _notificationService.showTestNotificationInstant();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                '✅ Notifikasi instan terkirim! Cek notification panel Anda'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Gagal mengirim notifikasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testNotificationDelayed() async {
    final delay = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: kBackgroundColor,
        title: const Text(
          '⏰ Pilih Delay Notifikasi',
          style: TextStyle(color: kTextColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih berapa detik lagi notifikasi akan muncul.\nTutup aplikasi untuk mengetes!',
              style: TextStyle(color: kSecondaryTextColor, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildDelayOption(context, 5, '5 detik'),
            _buildDelayOption(context, 10, '10 detik'),
            _buildDelayOption(context, 30, '30 detik'),
            _buildDelayOption(context, 60, '1 menit'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal',
                style: TextStyle(color: kSecondaryTextColor)),
          ),
        ],
      ),
    );

    if (delay != null) {
      try {
        await _notificationService.showTestNotificationDelayed(
            delaySeconds: delay);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '⏰ Notifikasi dijadwalkan $delay detik lagi!\n👉 Tutup aplikasi sekarang untuk mengetes',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Gagal menjadwalkan notifikasi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildDelayOption(BuildContext context, int seconds, String label) {
    return ListTile(
      onTap: () => Navigator.pop(context, seconds),
      leading: const Icon(Icons.alarm, color: kPrimaryColor),
      title: Text(label, style: const TextStyle(color: kTextColor)),
      trailing: const Icon(Icons.chevron_right, color: kSecondaryTextColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color avatarBgColor = kSecondaryTextColor.withAlpha(51);
    final Color avatarIconColor = kSecondaryTextColor.withAlpha(204);
    final Color dividerColor = kSecondaryTextColor.withAlpha(76);

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Avatar
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: avatarBgColor,
                      backgroundImage: _buildProfileImage(),
                      child: _imagePath.isEmpty
                          ? Icon(Icons.person, size: 60, color: avatarIconColor)
                          : null,
                    ),
                    if (_isEditing)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: kPrimaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt, // UPDATE: Icon Kamera
                              color: kLightTextColor,
                              size: 20,
                            ),
                            // UPDATE: Panggil modal sheet pilihan
                            onPressed: () => _showPickerOptions(context),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _displayName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
              const SizedBox(height: 32),

              // Personal Information
              _buildSectionTitle('Informasi Pribadi'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  children: [
                    _buildEditableRow('Username', _fullNameController),
                    const Divider(height: 12),
                    _buildInfoRow('Email', _email),
                    const Divider(height: 12),
                    _buildEditableRow('No HP', _phoneController),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Pengaturan Notifikasi
              _buildSectionTitle('Pengaturan Notifikasi'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          _notificationEnabled
                              ? Icons.notifications_active
                              : Icons.notifications_off_outlined,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Notifikasi Pengingat',
                            style: TextStyle(
                              color: kTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Switch(
                          value: _notificationEnabled,
                          onChanged: _toggleNotification,
                          activeColor: kPrimaryColor,
                        ),
                      ],
                    ),
                    if (_notificationEnabled) ...[
                      const Divider(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ulangi Notifikasi Setiap:',
                            style: TextStyle(
                              color: kSecondaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 4,
                            runSpacing: 8,
                            children: [14, 30, 60].map((days) {
                              final isSelected = _notificationInterval == days;
                              return InkWell(
                                onTap: () => _updateNotificationInterval(days),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kPrimaryColor
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? kPrimaryColor
                                          : kSecondaryTextColor,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '$days hari',
                                    style: TextStyle(
                                      color: isSelected
                                          ? kLightTextColor
                                          : kTextColor,
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Tes Notifikasi
              _buildSectionTitle('Tes Notifikasi'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Gunakan fitur ini untuk tes fitur notifikasi.',
                      style: TextStyle(
                        color: kSecondaryTextColor,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: _testNotificationInstant,
                      icon: const Icon(Icons.flash_on, size: 20),
                      label: const Text('Tes Notifikasi Instan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.green,
                        side: const BorderSide(color: Colors.green),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _testNotificationDelayed,
                      icon: const Icon(Icons.alarm, size: 20),
                      label: const Text('Tes Notifikasi Background'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange,
                        side: const BorderSide(color: Colors.orange),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Kesan dan Pesan
              _buildSectionTitle('Kesan dan Pesan'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: kBackgroundColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.message_outlined,
                          color: kPrimaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _defaultMessage,
                      style: const TextStyle(
                        color: kTextColor,
                        fontSize: 14,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Buttons
              if (_isEditing)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _cancelEdit,
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: kSecondaryTextColor,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveUpdates,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          foregroundColor: kLightTextColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text("Simpan"),
                      ),
                    ),
                  ],
                )
              else
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kDarkComponentColor,
                    foregroundColor: kLightTextColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Edit Profil"),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: kLightTextColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text("Log out"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: kTextColor,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 15, color: kSecondaryTextColor),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: kTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableRow(String label, TextEditingController controller) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 15, color: kSecondaryTextColor),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: !_isEditing,
            textAlign: TextAlign.end,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 12.0),
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              hintText: '...',
              hintStyle: TextStyle(color: kSecondaryTextColor),
            ),
            style: const TextStyle(
              fontSize: 15,
              color: kTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
