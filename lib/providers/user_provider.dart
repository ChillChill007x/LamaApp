import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile_model.dart';
import '../models/category_model.dart';
import '../database/db_helper.dart';

class UserProvider with ChangeNotifier {
  UserProfile _profile = const UserProfile();
  List<CategoryItem> _categories = [];

  UserProfile get profile => _profile;
  List<CategoryItem> get categories => _categories;

  List<CategoryItem> get expenseCategories =>
      _categories.where((c) => c.type == 'expense' || c.type == 'both').toList();

  List<CategoryItem> get incomeCategories =>
      _categories.where((c) => c.type == 'income' || c.type == 'both').toList();

  List<String> get expenseCategoryNames =>
      expenseCategories.map((c) => '${c.emoji} ${c.name}').toList();

  List<String> get incomeCategoryNames =>
      incomeCategories.map((c) => '${c.emoji} ${c.name}').toList();

  // ── key ผูกกับ userId เพื่อแยกแต่ละ account ──────────
  String _nameKey(String uid)   => 'user_name_$uid';
  String _avatarKey(String uid) => 'user_avatar_$uid';

  String? get _uid => Supabase.instance.client.auth.currentUser?.id;

  // ── Load ──────────────────────────────────────────────
  Future<void> load() async {
    await _loadProfile();
    await _loadCategories();
    notifyListeners();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final uid   = _uid;
    final user  = Supabase.instance.client.auth.currentUser;

    String displayName;
    String? avatarPath;

    if (uid != null && user != null) {
      // ── Login mode ─────────────────────────────────────
      // ดึงชื่อจาก Supabase metadata ก่อน (ชื่อที่ตั้งตอนสมัคร)
      final meta = user.userMetadata;
      final cloudName = meta != null && meta['display_name'] != null
          ? meta['display_name'] as String
          : null;

      // ถ้า user เคยแก้ชื่อใน app → ใช้ค่าที่บันทึกไว้ใน SharedPrefs
      // ถ้ายังไม่เคย → ใช้ชื่อจาก Supabase metadata
      final savedName = prefs.getString(_nameKey(uid));
      displayName = savedName ?? cloudName ?? user.email?.split('@').first ?? 'ผู้ใช้';

      // ถ้ายังไม่เคย save → บันทึก cloudName ลงไปเลย
      if (savedName == null && (cloudName != null || user.email != null)) {
        await prefs.setString(_nameKey(uid), displayName);
      }

      avatarPath = prefs.getString(_avatarKey(uid));
    } else {
      // ── Offline mode ───────────────────────────────────
      displayName = prefs.getString('user_display_name') ?? 'ผู้ใช้';
      avatarPath  = prefs.getString('user_avatar_path');
    }

    _profile = UserProfile(displayName: displayName, avatarPath: avatarPath);
  }

  Future<void> _loadCategories() async {
    _categories = await DBHelper().getCategories();
  }

  // ── Profile Update ────────────────────────────────────
  Future<void> updateDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = _uid;
    final cleanName = name.trim().isEmpty ? 'ผู้ใช้' : name.trim();

    if (uid != null) {
      await prefs.setString(_nameKey(uid), cleanName);
    } else {
      await prefs.setString('user_display_name', cleanName);
    }
    _profile = _profile.copyWith(displayName: cleanName);
    notifyListeners();
  }

  Future<void> pickAndSaveAvatar(ImageSource source) async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(source: source, imageQuality: 80);
    if (xFile == null) return;

    final dir  = await getApplicationDocumentsDirectory();
    final uid  = _uid;
    // ตั้งชื่อไฟล์ตาม uid เพื่อแยกแต่ละ account
    final name = uid != null ? 'avatar_$uid.jpg' : 'avatar.jpg';
    final dest = p.join(dir.path, name);
    await File(xFile.path).copy(dest);

    final prefs = await SharedPreferences.getInstance();
    if (uid != null) {
      await prefs.setString(_avatarKey(uid), dest);
    } else {
      await prefs.setString('user_avatar_path', dest);
    }
    _profile = _profile.copyWith(avatarPath: dest);
    notifyListeners();
  }

  Future<void> removeAvatar() async {
    final prefs  = await SharedPreferences.getInstance();
    final uid    = _uid;
    if (uid != null) {
      await prefs.remove(_avatarKey(uid));
    } else {
      await prefs.remove('user_avatar_path');
    }
    _profile = _profile.copyWith(clearAvatar: true);
    notifyListeners();
  }

  // ── Categories CRUD ────────────────────────────────────
  Future<void> addCategory(CategoryItem cat) async {
    final id = await DBHelper().insertCategory(cat);
    _categories.add(cat.copyWith(id: id));
    _categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    notifyListeners();
  }

  Future<void> updateCategory(CategoryItem cat) async {
    await DBHelper().updateCategory(cat);
    final i = _categories.indexWhere((c) => c.id == cat.id);
    if (i != -1) {
      _categories[i] = cat;
      notifyListeners();
    }
  }

  Future<void> deleteCategory(int id) async {
    await DBHelper().deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
