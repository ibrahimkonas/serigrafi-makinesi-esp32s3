import 'package:flutter/material.dart';
import '../models/pin_info.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PinDumpPage extends StatefulWidget {
  final String deviceIp;
  const PinDumpPage({super.key, required this.deviceIp});

  @override
  State<PinDumpPage> createState() => _PinDumpPageState();
}

class _PinDumpPageState extends State<PinDumpPage> {
  List<PinInfo>? pins;
  bool loading = true;
  String? error;

  Future<void> fetchPins() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final res = await http.get(Uri.parse('http://${widget.deviceIp}/pins'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        pins = data.map((e) => PinInfo.fromJson(e)).toList();
      } else {
        error = 'Cihazdan hata: ${res.statusCode}';
      }
    } catch (e) {
      error = e.toString();
    }
    setState(() {
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchPins();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ESP32 Pin Dökümü')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Hata: $error'))
              : pins == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('No')),
                          DataColumn(label: Text('Adı')),
                          DataColumn(label: Text('Fonksiyon')),
                          DataColumn(label: Text('Mod')),
                          DataColumn(label: Text('Pull')),
                        ],
                        rows: pins!
                            .map((p) => DataRow(cells: [
                                  DataCell(Text(p.number.toString())),
                                  DataCell(Text(p.name)),
                                  DataCell(Text(p.function)),
                                  DataCell(Text(p.mode)),
                                  DataCell(Text(p.pull)),
                                ]))
                            .toList(),
                      ),
                    ),
    );
  }
}
