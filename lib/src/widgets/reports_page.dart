import '../models/machine_event.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  final List<ProductionReport> reports;
  final List<MachineEvent> events;
  final VoidCallback? onExport;

  const ReportsPage({Key? key, required this.reports, required this.events, this.onExport}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        actions: [
          if (onExport != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: onExport,
              tooltip: 'Raporları Dışa Aktar',
            ),
        ],
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Günlük Üretim', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (reports.isEmpty)
            const ListTile(title: Text('Kayıtlı üretim yok.'))
          else ...reports.map((r) => ListTile(
                leading: const Icon(Icons.event_note),
                title: Text('${r.count} adet'),
                subtitle: Text(r.timeString),
              )),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text('Arıza ve Duruşlar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          if (events.isEmpty)
            const ListTile(title: Text('Kayıtlı arıza veya duruş yok.'))
          else ...events.map((e) => ListTile(
                leading: Icon(e.type == 'ariza' ? Icons.error : Icons.pause_circle_filled, color: e.type == 'ariza' ? Colors.red : Colors.orange),
                title: Text('${e.type == 'ariza' ? 'Arıza' : 'Duruş'}: ${e.reason}'),
                subtitle: Text(e.timeString),
              )),
        ],
      ),
    );
  }
}

class ProductionReport {
  final int count;
  final DateTime time;
  ProductionReport({required this.count, required this.time});
  String get timeString => '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}  ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}
