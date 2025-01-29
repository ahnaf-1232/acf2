import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceHelper {
  static const String _deviceIdKey = "device_id";
  static const _uuid = Uuid();

  /// Generates or retrieves a unique and constant device ID.
  static Future<String> getDeviceID() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if the device ID already exists
    String? deviceId = prefs.getString(_deviceIdKey);

    if (deviceId == null) {
      // Generate a new UUID for the device
      deviceId = _uuid.v4();

      // Save it to shared preferences
      await prefs.setString(_deviceIdKey, deviceId);

      print("Generated new Device ID: $deviceId");
    } else {
      print("Retrieved existing Device ID: $deviceId");
    }

    return deviceId;
  }
}