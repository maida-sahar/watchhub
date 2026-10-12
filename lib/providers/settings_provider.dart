import 'package:flutter/material.dart';
import '../models/settings_model.dart';
import '../repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository _repository;

  SettingsModel? _settings;
  AdminSettings? _adminSettings;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  SettingsProvider({required SettingsRepository repository}) : _repository = repository;

  SettingsModel? get settings => _settings;
  AdminSettings? get adminSettings => _adminSettings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  bool get hasError => _errorMessage != null;

  /// Loads settings for a user.
  Future<void> loadSettings(String userId) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.getSettings(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _settings = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates settings.
  Future<bool> updateSettings(SettingsModel updatedSettings) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.saveSettings(updatedSettings);
      _settings = updatedSettings;
      _successMessage = 'Settings saved successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Loads global admin/store settings.
  Future<void> loadAdminSettings() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _adminSettings = await _repository.getAdminSettings();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _adminSettings = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates global admin/store settings.
  Future<bool> updateAdminSettings(AdminSettings updatedAdmin) async {
    _isSaving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      await _repository.saveAdminSettings(updatedAdmin);
      _adminSettings = updatedAdmin;
      _successMessage = 'Admin settings saved successfully.';
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  /// Helper to clear notifications and status messages.
  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }
}
