import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/finance_provider.dart';
import '../services/sync_service.dart';
import '../models/category_model.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        final profile = userProvider.profile;
        return Scaffold(
          backgroundColor: Colors.grey[100],
          appBar: AppBar(
            title: const Text('ตั้งค่า',
                style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          body: ListView(
            children: [
              // ── โปรไฟล์ ──────────────────────────────────
              _buildSection(
                child: Column(children: [
                  const SizedBox(height: 8),
                  // รูปโปรไฟล์
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: profile.avatarPath != null
                              ? FileImage(File(profile.avatarPath!))
                              : null,
                          child: profile.avatarPath == null
                              ? Text(
                                  profile.displayName.isNotEmpty
                                      ? profile.displayName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(fontSize: 36,
                                      fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0, right: 0,
                          child: GestureDetector(
                            onTap: () => _showAvatarPicker(context, userProvider),
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: const BoxDecoration(
                                  color: Colors.blueAccent, shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(profile.displayName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => _showEditNameDialog(context, userProvider),
                    child: const Text('แก้ไขชื่อ'),
                  ),
                  const SizedBox(height: 8),
                ]),
              ),
              const SizedBox(height: 16),

              // ── Sync & Account ────────────────────────────
              const SizedBox(height: 16),
              _buildAccountSection(context),
              _buildCategorySection(
                context, userProvider,
                title: '💸 หมวดหมู่รายจ่าย',
                type: 'expense',
                categories: userProvider.expenseCategories,
              ),
              const SizedBox(height: 16),

              // ── หมวดหมู่รายรับ ────────────────────────────
              _buildCategorySection(
                context, userProvider,
                title: '💰 หมวดหมู่รายรับ',
                type: 'income',
                categories: userProvider.incomeCategories,
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  // ──────────────────────────────────────────────────────
  // Account / Sync Section
  // ──────────────────────────────────────────────────────
  Widget _buildAccountSection(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isLoggedIn = auth.isAuthenticated;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text('บัญชีและ Sync',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),

          if (isLoggedIn) ...[
            // แสดงอีเมล
            ListTile(
              leading: const Icon(Icons.account_circle_outlined,
                  color: Colors.blueAccent),
              title: Text(auth.user?.email ?? ''),
              subtitle: const Text('บัญชีที่เข้าสู่ระบบ',
                  style: TextStyle(fontSize: 12)),
            ),
            const Divider(height: 1, indent: 56),

            // Sync ขึ้น Cloud
            ListTile(
              leading: const Icon(Icons.cloud_upload_outlined,
                  color: Colors.green),
              title: const Text('Sync ขึ้น Cloud'),
              subtitle: const Text('อัปโหลดข้อมูลล่าสุดขึ้น Supabase',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลัง sync...')));
                await SyncService().pushToCloud();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sync เรียบร้อย ✓'),
                      backgroundColor: Colors.green));
              },
            ),
            const Divider(height: 1, indent: 56),

            // ดึงข้อมูลจาก Cloud
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined,
                  color: Colors.blueAccent),
              title: const Text('ดึงข้อมูลจาก Cloud'),
              subtitle: const Text('โหลดข้อมูลจาก Supabase มาใช้งาน',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('ดึงข้อมูลจาก Cloud?'),
                    content: const Text(
                        'ข้อมูลจาก Cloud จะถูกเพิ่มเข้ามา\n(ไม่ลบข้อมูลที่มีอยู่แล้ว)'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('ยกเลิก',
                              style: TextStyle(color: Colors.grey))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('ดึงข้อมูล')),
                    ],
                  ),
                );
                if (confirm != true || !context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลังดึงข้อมูล...')));
                await SyncService().pullFromCloud();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('ดึงข้อมูลเรียบร้อย ✓'),
                      backgroundColor: Colors.green));
              },
            ),
            const Divider(height: 1, indent: 56),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('ออกจากระบบ',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('ออกจากระบบ?'),
                    content: const Text(
                        'ระบบจะ sync ข้อมูลขึ้น Cloud ก่อน แล้วออกจากระบบ'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('ยกเลิก',
                              style: TextStyle(color: Colors.grey))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('ออกจากระบบ',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );
                if (confirm != true || !context.mounted) return;

                // ✅ Push ข้อมูลขึ้น cloud ก่อน logout (ไม่ล้าง local)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('กำลัง sync ข้อมูล...')));
                await SyncService().pushToCloud();

                if (!context.mounted) return;
                await auth.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
          ] else ...[
            // ยังไม่ได้ login
            ListTile(
              leading: const Icon(Icons.login, color: Colors.blueAccent),
              title: const Text('เข้าสู่ระบบ / สมัครสมาชิก'),
              subtitle: const Text('เพื่อ backup และ sync ข้อมูล',
                  style: TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Section wrapper
  // ──────────────────────────────────────────────────────
  Widget _buildSection({required Widget child}) {
    return Container(
      color: Colors.white,
      child: child,
    );
  }

  // ──────────────────────────────────────────────────────
  // Category Section
  // ──────────────────────────────────────────────────────
  Widget _buildCategorySection(
    BuildContext context,
    UserProvider userProvider, {
    required String title,
    required String type,
    required List<CategoryItem> categories,
  }) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(children: [
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('เพิ่ม', style: TextStyle(fontSize: 13)),
                onPressed: () => _showCategorySheet(context, userProvider, type, null),
              ),
            ]),
          ),
          const Divider(height: 1),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categories.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              final list = List<CategoryItem>.from(categories);
              final moved = list.removeAt(oldIndex);
              list.insert(newIndex, moved);
              // อัปเดต sortOrder
              for (int i = 0; i < list.length; i++) {
                await userProvider.updateCategory(list[i].copyWith(sortOrder: i));
              }
            },
            itemBuilder: (ctx, i) {
              final cat = categories[i];
              return ListTile(
                key: ValueKey(cat.id),
                leading: Container(
                  width: 40, height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: type == 'expense'
                        ? Colors.red.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(cat.emoji, style: const TextStyle(fontSize: 20)),
                ),
                title: Text(cat.name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: cat.isDefault
                    ? const Text('หมวดหมู่เริ่มต้น',
                        style: TextStyle(fontSize: 11, color: Colors.grey))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 18, color: Colors.blueAccent),
                      onPressed: () =>
                          _showCategorySheet(context, userProvider, type, cat),
                    ),
                    if (!cat.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        onPressed: () =>
                            _confirmDelete(context, userProvider, cat),
                      ),
                    const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Avatar picker
  // ──────────────────────────────────────────────────────
  void _showAvatarPicker(BuildContext context, UserProvider userProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: Colors.blueAccent),
              title: const Text('ถ่ายรูป'),
              onTap: () async {
                Navigator.pop(context);
                await userProvider.pickAndSaveAvatar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: Colors.blueAccent),
              title: const Text('เลือกจากคลัง'),
              onTap: () async {
                Navigator.pop(context);
                await userProvider.pickAndSaveAvatar(ImageSource.gallery);
              },
            ),
            if (userProvider.profile.avatarPath != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('ลบรูปโปรไฟล์',
                    style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await userProvider.removeAvatar();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Edit name dialog
  // ──────────────────────────────────────────────────────
  void _showEditNameDialog(BuildContext context, UserProvider userProvider) {
    final ctrl = TextEditingController(text: userProvider.profile.displayName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขชื่อผู้ใช้'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'ชื่อของคุณ'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await userProvider.updateDisplayName(ctrl.text);
              Navigator.pop(ctx);
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────
  // Add/Edit category sheet
  // ──────────────────────────────────────────────────────
  void _showCategorySheet(BuildContext context, UserProvider userProvider,
      String type, CategoryItem? existing) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedEmoji = existing?.emoji ?? '📦';

    const emojiList = [
      '🍜','🧁','🛍️','🚌','⛽','🎮','💄','🏠','💡','💊','🏋️','📚',
      '🎵','✈️','🎁','💰','💼','📱','🖥️','🐾','☕','🍕','🎨','🔧',
      '📦','🌿','💍','👔','🎓','🏖️','🎬','🎤','🧴','🚿','🛒','📎',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) {
        return StatefulBuilder(builder: (ctx, setSS) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
              left: 20, right: 20, top: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4,
                      decoration: BoxDecoration(color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  Text(existing == null ? 'เพิ่มหมวดหมู่' : 'แก้ไขหมวดหมู่',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Emoji grid
                  Wrap(spacing: 8, runSpacing: 8, children: emojiList.map((e) {
                    final sel = e == selectedEmoji;
                    return GestureDetector(
                      onTap: () => setSS(() => selectedEmoji = e),
                      child: Container(
                        width: 44, height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: sel ? Colors.blue.shade100 : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: sel ? Border.all(color: Colors.blueAccent, width: 2) : null,
                        ),
                        child: Text(e, style: const TextStyle(fontSize: 22)),
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 16),

                  // ชื่อหมวดหมู่
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'ชื่อหมวดหมู่ *',
                      prefixIcon: Text('  $selectedEmoji',
                          style: const TextStyle(fontSize: 20)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity, height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        if (existing == null) {
                          await userProvider.addCategory(CategoryItem(
                            name: name,
                            emoji: selectedEmoji,
                            type: type,
                            sortOrder: userProvider.categories.length,
                          ));
                        } else {
                          await userProvider.updateCategory(existing.copyWith(
                            name: name, emoji: selectedEmoji));
                        }
                        Navigator.pop(sheetCtx);
                      },
                      child: Text(existing == null ? 'เพิ่มหมวดหมู่' : 'บันทึก',
                          style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  void _confirmDelete(
      BuildContext context, UserProvider userProvider, CategoryItem cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบหมวดหมู่?'),
        content: Text('ต้องการลบ "${cat.emoji} ${cat.name}" ใช่ไหม?\n'
            'รายการที่ใช้หมวดหมู่นี้จะยังอยู่ แต่ชื่อหมวดจะเปลี่ยนเป็นหมวดเดิม'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await userProvider.deleteCategory(cat.id!);
              Navigator.pop(ctx);
            },
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
