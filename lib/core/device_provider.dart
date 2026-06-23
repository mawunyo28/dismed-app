import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/device_service.dart';

class DeviceProvider extends ChangeNotifier {
  List<Device> _devices = [];
  String? _selectedDeviceId;
  bool _loading = false;
  String? _error;

  List<Device> get devices => _devices;
  bool get loading => _loading;
  String? get error => _error;

  String? get selectedDeviceId => _selectedDeviceId;

  Device? get selectedDevice =>
      _selectedDeviceId == null ? null : _devices.firstWhere((d) => d.id == _selectedDeviceId);

  String? get selectedDeviceKey => selectedDevice?.deviceKey;

  void selectDevice(String id) {
    _selectedDeviceId = id;
    notifyListeners();
  }

  Future<void> fetchDevices() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _devices = await DeviceService.fetchDevices();
      // auto-select first device if none selected
      if (_selectedDeviceId == null && _devices.isNotEmpty) {
        _selectedDeviceId = _devices.first.id;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> addDevice(String name, String deviceKey) async {
    _error = null;
    try {
      final device = await DeviceService.addDevice(name, deviceKey);
      _devices.add(device);
      _selectedDeviceId ??= device.id;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> renameDevice(String id, String name) async {
    _error = null;
    try {
      await DeviceService.renameDevice(id, name);
      final index = _devices.indexWhere((d) => d.id == id);
      if (index != -1) {
        _devices[index] = Device(
          id: _devices[index].id,
          ownerId: _devices[index].ownerId,
          deviceKey: _devices[index].deviceKey,
          label: name,
          lastSeenAt: _devices[index].lastSeenAt,
          createdAt: _devices[index].createdAt,
          isOnline: _devices[index].isOnline,
        );
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> deleteDevice(String id) async {
    _error = null;
    try {
      await DeviceService.deleteDevice(id);
      _devices.removeWhere((d) => d.id == id);
      if (_selectedDeviceId == id) {
        _selectedDeviceId = _devices.isNotEmpty ? _devices.first.id : null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
