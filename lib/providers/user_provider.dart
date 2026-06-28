import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile_model.dart';

class UserProvider extends ChangeNotifier {
  UserProvider();

  final SupabaseClient _supabase = Supabase.instance.client;

  ProfileModel? _profile;
  bool _isLoading = false;
  Object? _error;

  ProfileModel? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get hasProfile => _profile != null;
  Object? get error => _error;

  String get id => _profile?.id ?? '';
  String get name => _profile?.name ?? '';
  UserRole get role => _profile?.role ?? UserRole.user;
  String get email => _profile?.email ?? '';
  String get sport => _profile?.sport ?? '';
  int get notifications => _profile?.notifications ?? 0;

  String get initials {
    final displayName = name.trim();
    if (displayName.isEmpty) {
      return '?';
    }
    final parts = displayName.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  Future<void> loadProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _profile = null;
      _error = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        _profile = null;
      } else {
        _profile = ProfileModel.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (error) {
      _error = error;
      _profile = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearProfile() {
    _profile = null;
    _error = null;
    notifyListeners();
  }
}
