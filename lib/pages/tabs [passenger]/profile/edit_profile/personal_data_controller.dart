import 'package:flutter/material.dart';

/// Holds all state and logic for the PersonalDataPage.
/// Keeps the page widget thin and testable.
class PersonalDataController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController firstName = TextEditingController(text: 'Hamza');
  final TextEditingController lastName  = TextEditingController(text: '');
  final TextEditingController email     = TextEditingController(text: 'hamza@example.com');
  final TextEditingController phone     = TextEditingController(text: '+212 929 698 05');

  List<TextEditingController> get _all => [firstName, lastName, email, phone];

  bool isSaving   = false;
  bool hasChanges = false;

  /// Call in initState — pass setState so listeners can trigger rebuilds.
  void init(VoidCallback setState) {
    for (final c in _all) {
      c.addListener(() => setState());
    }
  }

  

  /// Returns true if save succeeded.
  Future<bool> save() async {
    if (!formKey.currentState!.validate()) return false;
    isSaving = true;
    await Future.delayed(const Duration(milliseconds: 900));
    isSaving    = false;
    hasChanges  = false;
    return true;
  }

  void dispose() {
    for (final c in _all) {
      c.dispose();
    }
  }
}