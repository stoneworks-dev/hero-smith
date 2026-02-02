import 'dart:convert';

class DowntimeEntry {
  final String id;
  final String type;
  final String name;
  final Map<String, dynamic> raw;

  DowntimeEntry({required this.id, required this.type, required this.name, required this.raw});

  factory DowntimeEntry.fromJson(Map<String, dynamic> j) => DowntimeEntry(
        id: j['id']?.toString() ?? '',
        type: j['type']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        raw: j,
      );
}

class EventRow {
  final String diceValue;
  final String description;
  EventRow({required this.diceValue, required this.description});
  factory EventRow.fromJson(Map<String, dynamic> j) => EventRow(
        diceValue: j['dice_value']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
      );
}

class EventTable {
  final String id;
  final String name;
  final List<EventRow> events;
  EventTable({required this.id, required this.name, required this.events});

  factory EventTable.fromJson(Map<String, dynamic> j) => EventTable(
        id: j['id']?.toString() ?? '',
        name: j['name']?.toString() ?? '',
        events: (j['events'] as List<dynamic>? ?? [])
            .map((e) => EventRow.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

List<dynamic> decodeJsonList(String source) => jsonDecode(source) as List<dynamic>;
