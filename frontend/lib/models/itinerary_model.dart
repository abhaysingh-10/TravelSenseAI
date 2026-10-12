import 'package:flutter/material.dart';

class ItineraryActivity {
  final String description;
  final String tag;
  final IconData icon;
  final Color color;

  ItineraryActivity({
    required this.description,
    required this.tag,
    required this.icon,
    required this.color,
  });
}

class ItineraryTimeSlot {
  final String timeOfDay;
  final String timeRange;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final List<ItineraryActivity> activities;

  ItineraryTimeSlot({
    required this.timeOfDay,
    required this.timeRange,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    required this.activities,
  });
}

class ItineraryDay {
  final int dayNumber;
  final String title;
  final List<ItineraryTimeSlot> slots;

  ItineraryDay({
    required this.dayNumber,
    required this.title,
    required this.slots,
  });
}

class ItineraryParser {
  static (IconData, Color, String) _getActivityMeta(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('hotel') ||
        lower.contains('check-in') ||
        lower.contains('check in') ||
        lower.contains('arrive')) {
      return (Icons.hotel_rounded, const Color(0xFF3F51B5), 'Stay & Arrival');
    }
    if (lower.contains('lunch') ||
        lower.contains('dinner') ||
        lower.contains('breakfast') ||
        lower.contains('food') ||
        lower.contains('eat') ||
        lower.contains('restaurant') ||
        lower.contains('gyros') ||
        lower.contains('souvlaki') ||
        lower.contains('cafe') ||
        lower.contains('coffee') ||
        lower.contains('wine') ||
        lower.contains('drinks') ||
        lower.contains('cocktail') ||
        lower.contains('taste') ||
        lower.contains('dine')) {
      return (Icons.restaurant_rounded, const Color(0xFFFF7043), 'Food & Dining');
    }
    if (lower.contains('walk') ||
        lower.contains('hike') ||
        lower.contains('trail') ||
        lower.contains('trek') ||
        lower.contains('stroll') ||
        lower.contains('climb') ||
        lower.contains('path')) {
      return (Icons.hiking_rounded, const Color(0xFF00897B), 'Scenic Walk / Hike');
    }
    if (lower.contains('sunset') ||
        lower.contains('photo') ||
        lower.contains('view') ||
        lower.contains('panorama') ||
        lower.contains('overlook') ||
        lower.contains('scenic') ||
        lower.contains('bells')) {
      return (Icons.camera_alt_rounded, const Color(0xFFE91E63), 'Viewpoint & Photo');
    }
    if (lower.contains('museum') ||
        lower.contains('cathedral') ||
        lower.contains('temple') ||
        lower.contains('church') ||
        lower.contains('castle') ||
        lower.contains('ruins') ||
        lower.contains('history') ||
        lower.contains('historic') ||
        lower.contains('heritage')) {
      return (Icons.account_balance_rounded, const Color(0xFF795548), 'Heritage & Culture');
    }
    if (lower.contains('beach') ||
        lower.contains('sea') ||
        lower.contains('boat') ||
        lower.contains('cruise') ||
        lower.contains('ferry') ||
        lower.contains('swim') ||
        lower.contains('bay') ||
        lower.contains('caldera') ||
        lower.contains('water')) {
      return (Icons.beach_access_rounded, const Color(0xFF0288D1), 'Coastal & Scenic');
    }
    if (lower.contains('bus') ||
        lower.contains('train') ||
        lower.contains('flight') ||
        lower.contains('taxi') ||
        lower.contains('drive') ||
        lower.contains('transit')) {
      return (Icons.directions_bus_rounded, const Color(0xFF607D8B), 'Transit');
    }
    return (Icons.explore_rounded, const Color(0xFF009688), 'Sightseeing');
  }

  static (String, IconData, Color, Color) _getTimeSlotMeta(String slotName) {
    final lower = slotName.toLowerCase();
    if (lower.contains('morning')) {
      return (
        '09:00 AM – 12:30 PM',
        Icons.wb_twilight_rounded,
        const Color(0xFFE65100),
        const Color(0xFFFFF3E0),
      );
    }
    if (lower.contains('afternoon') || lower.contains('midday') || lower.contains('lunch')) {
      return (
        '01:00 PM – 05:30 PM',
        Icons.wb_sunny_rounded,
        const Color(0xFF0277BD),
        const Color(0xFFE1F5FE),
      );
    }
    if (lower.contains('evening') || lower.contains('night') || lower.contains('dinner')) {
      return (
        '06:00 PM – 10:00 PM',
        Icons.nights_stay_rounded,
        const Color(0xFF512DA8),
        const Color(0xFFEDE7F6),
      );
    }
    return (
      'Flexible Time',
      Icons.schedule_rounded,
      const Color(0xFF00796B),
      const Color(0xFFE0F2F1),
    );
  }

  static List<ItineraryDay> parse(String rawText) {
    final lines = rawText.split('\n');
    final List<ItineraryDay> days = [];

    int currentDayNum = 0;
    String currentDayTitle = '';

    String currentSlotName = '';
    final List<String> currentSlotActivities = [];
    final List<ItineraryTimeSlot> currentDaySlots = [];

    void commitSlot() {
      if (currentSlotActivities.isNotEmpty) {
        final slotTitle = currentSlotName.isEmpty ? 'Highlights' : currentSlotName;
        final (range, icon, accent, bg) = _getTimeSlotMeta(slotTitle);

        final activities = currentSlotActivities.map((act) {
          final (actIcon, actColor, actTag) = _getActivityMeta(act);
          return ItineraryActivity(
            description: act,
            tag: actTag,
            icon: actIcon,
            color: actColor,
          );
        }).toList();

        currentDaySlots.add(ItineraryTimeSlot(
          timeOfDay: slotTitle,
          timeRange: range,
          icon: icon,
          accentColor: accent,
          bgColor: bg,
          activities: activities,
        ));

        currentSlotActivities.clear();
        currentSlotName = '';
      }
    }

    void commitDay() {
      commitSlot();
      if (currentDayNum > 0 || currentDaySlots.isNotEmpty) {
        days.add(ItineraryDay(
          dayNumber: currentDayNum > 0 ? currentDayNum : days.length + 1,
          title: currentDayTitle.isEmpty ? 'Day ${days.length + 1} Exploration' : currentDayTitle,
          slots: List.from(currentDaySlots),
        ));
        currentDaySlots.clear();
        currentDayTitle = '';
        currentDayNum = 0;
      }
    }

    final dayRegex = RegExp(r'^(?:#+\s*)?(?:\*\*)?Day\s*(\d+)[:\-\s]*(.*?)(?:\*\*)?$', caseSensitive: false);
    final timeSlotRegex = RegExp(r'^(?:[*\-#\s]*)(Morning|Afternoon|Evening|Night|Midday|Lunch|Dinner)[:\s*]*(.*)$', caseSensitive: false);

    for (var rawLine in lines) {
      var line = rawLine.trim();
      if (line.isEmpty) continue;

      // Match Day header
      final dayMatch = dayRegex.firstMatch(line);
      if (dayMatch != null) {
        commitDay();
        currentDayNum = int.tryParse(dayMatch.group(1) ?? '') ?? (days.length + 1);
        final titlePart = (dayMatch.group(2) ?? '')
            .replaceAll('*', '')
            .replaceAll('#', '')
            .replaceAll(':', '')
            .trim();
        currentDayTitle = titlePart.isEmpty ? 'Exploration & Sights' : titlePart;
        continue;
      }

      // Match Time Slot header (Morning, Afternoon, Evening)
      final timeMatch = timeSlotRegex.firstMatch(line);
      if (timeMatch != null) {
        commitSlot();
        currentSlotName = (timeMatch.group(1) ?? 'Activities').trim();
        final rest = (timeMatch.group(2) ?? '')
            .replaceAll('*', '')
            .replaceAll('#', '')
            .trim();
        if (rest.isNotEmpty && rest != ':') {
          currentSlotActivities.add(rest);
        }
        continue;
      }

      // Bullet / Activity lines
      var clean = line;
      if (clean.startsWith('- ') || clean.startsWith('* ') || clean.startsWith('• ')) {
        clean = clean.substring(2).trim();
      }
      clean = clean.replaceAll('**', '').replaceAll('*', '').trim();
      if (clean.isNotEmpty) {
        if (currentSlotName.isEmpty && currentDaySlots.isEmpty) {
          currentSlotName = 'Morning';
        }
        currentSlotActivities.add(clean);
      }
    }

    commitDay();
    return days;
  }
}
