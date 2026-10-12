import '../models/settings_model.dart';
import '../services/settings_service.dart';

class SettingsRepositoryException implements Exception {
  final String message;
  const SettingsRepositoryException(this.message);

  @override
  String toString() => message;
}

class SettingsRepository {
  final SettingsService _service;

  SettingsRepository({required SettingsService service}) : _service = service;

  Future<SettingsModel> getSettings(String userId) async {
    try {
      return await _service.fetchSettings(userId);
    } catch (e) {
      throw SettingsRepositoryException(e.toString());
    }
  }

  Future<void> saveSettings(SettingsModel settings) async {
    try {
      await _service.updateSettings(settings);
    } catch (e) {
      throw SettingsRepositoryException(e.toString());
    }
  }

  Future<AdminSettings> getAdminSettings() async {
    try {
      return await _service.fetchAdminSettings();
    } catch (e) {
      throw SettingsRepositoryException(e.toString());
    }
  }

  Future<void> saveAdminSettings(AdminSettings admin) async {
    try {
      await _service.updateAdminSettings(admin);
    } catch (e) {
      throw SettingsRepositoryException(e.toString());
    }
  }
}
