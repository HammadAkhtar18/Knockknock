import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.onSettingsChanged,
    super.key,
    this.initialVolume = 1.0,
    this.initialDoubleKnock = true,
  });

  final void Function(double threshold, double volume, bool doubleKnock)
      onSettingsChanged;
  final double initialVolume;
  final bool initialDoubleKnock;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _sensitivityKey = 'settings_sensitivity_level';
  static const String _volumeKey = 'settings_response_volume';
  static const String _doubleKnockKey = 'settings_double_knock';

  static const double _mobileLow = 22.0;
  static const double _mobileMedium = 18.0;
  static const double _mobileHigh = 14.0;

  static const double _desktopLow = -20.0;
  static const double _desktopMedium = -25.0;
  static const double _desktopHigh = -30.0;

  static const Color _backgroundColor = Color(0xFF0D1117);
  static const Color _accentColor = Color(0xFF58A6FF);
  static const List<String> _sensitivityLabels = <String>[
    'Low',
    'Medium',
    'High',
  ];

  int _sensitivityIndex = 1;
  double _volume = 1.0;
  bool _doubleKnock = true;

  @override
  void initState() {
    super.initState();
    _volume = widget.initialVolume;
    _doubleKnock = widget.initialDoubleKnock;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final int sensitivityIndex = preferences.getInt(_sensitivityKey) ?? 1;
    final double volume = preferences.getDouble(_volumeKey) ?? _volume;
    final bool doubleKnock =
        preferences.getBool(_doubleKnockKey) ?? _doubleKnock;

    if (!mounted) {
      return;
    }

    setState(() {
      _sensitivityIndex = sensitivityIndex.clamp(0, 2);
      _volume = volume.clamp(0.0, 1.0);
      _doubleKnock = doubleKnock;
    });

    _notifyChange();
  }

  Future<void> _persistSettings() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_sensitivityKey, _sensitivityIndex);
    await preferences.setDouble(_volumeKey, _volume);
    await preferences.setBool(_doubleKnockKey, _doubleKnock);
  }

  Future<void> _updateSettings({
    int? sensitivityIndex,
    double? volume,
    bool? doubleKnock,
  }) async {
    setState(() {
      if (sensitivityIndex != null) {
        _sensitivityIndex = sensitivityIndex;
      }
      if (volume != null) {
        _volume = volume;
      }
      if (doubleKnock != null) {
        _doubleKnock = doubleKnock;
      }
    });

    _notifyChange();
    await _persistSettings();
  }

  void _notifyChange() {
    widget.onSettingsChanged(_thresholdForSelection(), _volume, _doubleKnock);
  }

  double _thresholdForSelection() {
    final bool isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

    if (isDesktop) {
      switch (_sensitivityIndex) {
        case 0:
          return _desktopLow;
        case 2:
          return _desktopHigh;
        case 1:
        default:
          return _desktopMedium;
      }
    }

    switch (_sensitivityIndex) {
      case 0:
        return _mobileLow;
      case 2:
        return _mobileHigh;
      case 1:
      default:
        return _mobileMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _backgroundColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _buildCard(
            title: 'Knock Sensitivity',
            subtitle: _sensitivityLabels[_sensitivityIndex],
            child: Slider(
              value: _sensitivityIndex.toDouble(),
              min: 0,
              max: 2,
              divisions: 2,
              activeColor: _accentColor,
              inactiveColor: Colors.white24,
              label: _sensitivityLabels[_sensitivityIndex],
              onChanged: (double value) {
                _updateSettings(sensitivityIndex: value.round());
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Response Volume',
            subtitle: _volume.toStringAsFixed(2),
            child: Slider(
              value: _volume,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              activeColor: _accentColor,
              inactiveColor: Colors.white24,
              label: _volume.toStringAsFixed(2),
              onChanged: (double value) {
                _updateSettings(volume: value);
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildCard(
            title: 'Double Knock',
            subtitle: _doubleKnock ? 'Enabled' : 'Disabled',
            child: SwitchListTile(
              value: _doubleKnock,
              thumbColor: const WidgetStatePropertyAll<Color>(_accentColor),
              trackColor: WidgetStatePropertyAll<Color>(
                _accentColor.withValues(alpha: 0.5),
              ),
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Require two knocks for double-knock response',
                style: TextStyle(color: Colors.white),
              ),
              onChanged: (bool value) {
                _updateSettings(doubleKnock: value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: _accentColor, fontSize: 13),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
