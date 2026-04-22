import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

/// Holds all state and logic for the PersonalDataPage.
/// Keeps the page widget thin and testable.
class PersonalDataController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController phone = TextEditingController();

  List<TextEditingController> get _all => [firstName, lastName, email, phone];

  bool isSaving = false;
  bool hasChanges = false;
  bool isLoading = true;

  /// Call in initState — pass setState so listeners can trigger rebuilds.
  void init(VoidCallback setState) async {
    for (final c in _all) {
      c.addListener(() => setState());
    }
    await _loadUser();
    setState();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        firstName.text = user['firstName'] ?? '';
        lastName.text = user['lastName'] ?? '';
        email.text = user['email'] ?? '';
        // Strip +216 prefix if present (backend stores full international format)
        final rawPhone = user['phone'] ?? '';
        phone.text = rawPhone.startsWith('+216')
            ? rawPhone.substring(4)
            : rawPhone;
      }
    } catch (_) {
      // Keep empty fields on error
    } finally {
      isLoading = false;
    }
  }

  /// Returns true if save succeeded.
  Future<bool> save() async {
    if (!formKey.currentState!.validate()) return false;
    isSaving = true;
    try {
      await _authService.updateProfile(
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        phone: '+216${phone.text.trim()}',
      );
      hasChanges = false;
      return true;
    } catch (_) {
      return false;
    } finally {
      isSaving = false;
    }
  }

  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
  }
}
