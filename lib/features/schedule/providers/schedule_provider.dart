import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/schedule.dart';

class ScheduleNotifier extends StateNotifier<List<FocusSchedule>> {
  ScheduleNotifier() : super([]) {
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('focus_schedules');
    if (saved != null) {
      state = saved.map((s) => FocusSchedule.fromMap(json.decode(s))).toList();
    }
  }

  Future<void> _saveSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'focus_schedules',
      state.map((s) => json.encode(s.toMap())).toList(),
    );
  }

  Future<void> addSchedule(FocusSchedule schedule) async {
    state = [...state, schedule];
    await _saveSchedules();
  }

  Future<void> removeSchedule(String id) async {
    state = state.where((s) => s.id != id).toList();
    await _saveSchedules();
  }

  Future<void> toggleSchedule(String id, bool isEnabled) async {
    state = state.map((s) {
      if (s.id == id) {
        return s.copyWith(isEnabled: isEnabled);
      }
      return s;
    }).toList();
    await _saveSchedules();
  }
}

final scheduleProvider =
    StateNotifierProvider<ScheduleNotifier, List<FocusSchedule>>((ref) {
      return ScheduleNotifier();
    });
