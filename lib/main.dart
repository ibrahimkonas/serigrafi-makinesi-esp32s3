import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/widgets/operator_panel.dart';
import 'src/widgets/reports_page.dart';
import 'src/models/machine_event.dart';
import 'src/widgets/technician_menu_extra.dart';

void main() => runApp(const SgmProHmi());

class SgmProHmi extends StatelessWidget {
  const SgmProHmi({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0D1117),
      ),
      home: const AnaPanel(),
    );
  }
}

class AnaPanel extends StatefulWidget {
  const AnaPanel({super.key});
  @override
  State<AnaPanel> createState() => _AnaPanelState();
}

class _AnaPanelState extends State<AnaPanel> {
  bool _pressureOk = true;
  bool _vacuumOk = true;
  final String ip = "192.168.4.1";
  Timer? _pollTimer;
  String _password = '1234';
  int _sayfaIndex = 0;
  List<ProductionReport> _reports = [];
  List<MachineEvent> _events = [];
  int sayac = 0;
  int _targetProduction = 0;
  bool _targetReached = false;
  bool _stoppedForError = false;
  double basinc = 0, vakum = 0, hiz = 850, bant = 1000, anaP = 500, ragP = 400;
  bool isOnline = false, isOto = true;
  String durum = "BEKLENIYOR";
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 1),
      (t) => _verileriGetir(),
    );
    _loadPassword();
  }

  Future<void> _loadPassword() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _password = prefs.getString('password') ?? '1234';
    });
  }

  Future<void> _savePassword(String newPass) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', newPass);
    setState(() => _password = newPass);
  }

  Future<void> _verileriGetir() async {
    try {
      final res = await http
          .get(Uri.parse('http://$ip/status'))
          .timeout(const Duration(milliseconds: 900));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        setState(() {
          void _addReport(int count) {
            final now = DateTime.now();
            _reports.add(ProductionReport(count: count, time: now));
            _reports = _reports
                .where(
                  (r) =>
                      r.time.day == now.day &&
                      r.time.month == now.month &&
                      r.time.year == now.year,
                )
                .toList();
          }

          if (_targetProduction > 0) {
            if (_targetReached) {
              sayac = _targetProduction;
            } else if (d['sayac'] == 0) {
              sayac = 0;
            } else if (d['sayac'] > 0 && sayac == 0) {
              sayac = 1;
              _addReport(1);
            } else if (d['sayac'] > 0 && sayac > 0) {
              if (d['sayac'] > sayac) {
                for (int i = sayac + 1; i <= d['sayac']; i++) {
                  _addReport(i);
                }
              }
              sayac = d['sayac'];
            }
          } else {
            sayac = d['sayac'] ?? 0;
          }
          hiz = (d['hiz'] ?? 850).toDouble();
          bant = (d['bant'] ?? 1000).toDouble();
          anaP = (d['anaP'] ?? 500).toDouble();
          ragP = (d['ragP'] ?? 400).toDouble();
          durum = d['durum'] ?? "HAZIR";
          isOto = d['isOto'] ?? true;
          basinc = ((d['basinc'] ?? 0) / 4095) * 10;
          vakum = ((d['vakum'] ?? 0) / 4095) * 10;
          isOnline = true;
          _pressureOk = (d['pressure'] ?? 1) == 1;
          _vacuumOk = (d['vacuum'] ?? 1) == 1;
          _errorMessage = '';
          String? detectedError;
          if (d['error_msg'] != null && (d['error_msg'] as String).isNotEmpty) {
            detectedError = (d['error_msg'] as String).toUpperCase();
          } else {
            if (basinc < 2.0) {
              detectedError = 'HAVA BASINCI YOK';
            } else if (vakum < 1.5) {
              detectedError = 'VAKUM DÜŞÜK';
            } else if ((d['durum'] ?? '').toString().toLowerCase().contains(
              'ana piston',
            )) {
              detectedError = 'ANA PİSTON AŞAĞIYA İNMEDİ';
            } else if ((d['durum'] ?? '').toString().toLowerCase().contains(
              'ragle',
            )) {
              detectedError = 'RAGLE PİSTON YERİNE ULAŞMADI';
            }
          }
          if (detectedError != null && detectedError.isNotEmpty) {
            _errorMessage = detectedError;
            if (_events.isEmpty || _events.last.reason != detectedError) {
              _events.add(
                MachineEvent(
                  time: DateTime.now(),
                  type: 'ariza',
                  reason: detectedError,
                ),
              );
            }
          }
        });
        if (mounted) {
          if (_errorMessage.isNotEmpty && !_stoppedForError) {
            _events.add(
              MachineEvent(
                time: DateTime.now(),
                type: 'duruş',
                reason: _errorMessage,
              ),
            );
            try {
              await _gonder('cmd?op=stp');
            } catch (_) {}
            setState(() => _stoppedForError = true);
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Makine hata nedeniyle durduruldu'),
                ),
              );
          } else if (_errorMessage.isEmpty && _stoppedForError) {
            setState(() => _stoppedForError = false);
          }
          if (_targetProduction > 0 &&
              sayac >= _targetProduction &&
              !_targetReached) {
            try {
              await _gonder('cmd?op=stp');
            } catch (_) {}
            setState(() => _targetReached = true);
            if (mounted)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('HEDEFE ULAŞILDI - MAKİNE DURDURULDU'),
                ),
              );
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => isOnline = false);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<http.Response> _gonder(String path) =>
      http.get(Uri.parse('http://$ip/$path'));

  void _showChangePasswordDialog() {
    final TextEditingController cur = TextEditingController();
    final TextEditingController np = TextEditingController();
    final TextEditingController np2 = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cur,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mevcut Şifre'),
            ),
            TextField(
              controller: np,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Yeni Şifre'),
            ),
            TextField(
              controller: np2,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (cur.text != _password) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Mevcut şifre yanlış')),
                );
                return;
              }
              if (np.text.isEmpty || np.text != np2.text) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Yeni şifreler uyuşmuyor')),
                );
                return;
              }
              await _savePassword(np.text);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Şifre değiştirildi')),
              );
            },
            child: const Text('Kaydet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
        ],
      ),
    );
  }

  void _performFactoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Üretim Sayacı Sıfırlama'),
        content: const Text(
          'Bu işlem yalnızca üretim sayacını sıfırlayacaktır. Program ve uygulama şifresi etkilenmeyecektir. Emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Evet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hayır'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    String message = 'İstek gönderiliyor...';
    try {
      final resp = await _gonder('cmd?op=reset_counter&pw=$_password');
      final body = resp.body;
      if (resp.statusCode == 200) {
        setState(() {
          sayac = 0;
        });
        await Future.delayed(const Duration(milliseconds: 700));
        await _verileriGetir();
        if (sayac == 0) {
          message = 'Üretim sayacı başarıyla sıfırlandı.';
        } else {
          message =
              'Cihaz sayaçı sıfırlamadı. Cihaz cevabı: ${body.isNotEmpty ? body : resp.statusCode.toString()}';
        }
      } else {
        message =
            'Cihazdan hata: ${resp.statusCode} ${body.isNotEmpty ? '- $body' : ''}';
      }
    } catch (e) {
      message = 'Sıfırlama isteği gönderilemedi: $e';
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _sayfaIndex == 0
              ? "OPERATOR"
              : _sayfaIndex == 1
              ? "RAPORLAR"
              : "TEKNISYEN",
        ),
        actions: [
          Icon(Icons.wifi, color: isOnline ? Colors.green : Colors.red),
          const SizedBox(width: 15),
        ],
      ),
      body: _sayfaIndex == 0
          ? _operatorBody()
          : _sayfaIndex == 1
          ? ReportsPage(
              reports: _reports,
              events: _events,
              onExport: _exportReports,
            )
          : _teknisyenBody(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _sayfaIndex,
        onTap: (i) {
          if (i == 2) {
            _sifreSorgula();
          } else {
            setState(() => _sayfaIndex = i);
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: "Panel"),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: "Raporlar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Ayarlar"),
        ],
      ),
    );
  }

  Future<void> _exportReports() async {
    final buffer = StringBuffer();
    buffer.writeln('TÜR;ADET/SEBEP;TARİH-SAAT');
    for (final r in _reports) {
      buffer.writeln('Üretim;${r.count};${r.timeString}');
    }
    for (final e in _events) {
      buffer.writeln(
        '${e.type == 'ariza' ? 'Arıza' : 'Duruş'};${e.reason};${e.timeString}',
      );
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rapor Dışa Aktar'),
        content: SingleChildScrollView(child: Text(buffer.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _operatorBody() {
    return Column(
      children: [
        _uyariBanner(),
        Expanded(
          child: OperatorPanel(
            sayac: sayac,
            basinc: basinc,
            vakum: vakum,
            hiz: hiz,
            bant: bant,
            isOto: isOto,
            durum: durum,
            isOnline: isOnline,
            isError: _errorMessage.isNotEmpty,
            onReset: _resetError,
            onSend: (p) => _gonder(p),
            target: _targetProduction,
            onSetTarget: _setTarget,
          ),
        ),
      ],
    );
  }

  Widget _uyariBanner() {
    if (_pressureOk && _vacuumOk) return const SizedBox.shrink();
    String msg = '';
    if (!_pressureOk) msg += 'BASINÇLI HAVA YOK! ';
    if (!_vacuumOk) msg += 'VAKUM MOTORU ÇALIŞMIYOR!';
    return Container(
      width: double.infinity,
      color: (_pressureOk && _vacuumOk) ? Colors.green : Colors.red,
      padding: const EdgeInsets.all(12),
      child: Text(
        msg,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  void _resetError() async {
    String message = 'İstek gönderiliyor...';
    try {
      final resp = await _gonder('cmd?op=reset_error&pw=$_password');
      if (resp.statusCode == 200) {
        setState(() {
          durum = 'HAZIR';
          _errorMessage = '';
        });
        await _verileriGetir();
        message = 'Hata başarıyla sıfırlandı.';
      } else {
        message = 'Cihazdan hata: ${resp.statusCode}';
      }
    } catch (e) {
      message = 'Hata sıfırlama isteği gönderilemedi: $e';
    }
    if (mounted)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setTarget(int v) {
    setState(() {
      _targetProduction = v;
      _targetReached = false;
      _stoppedForError = false;
    });
    _verileriGetir();
  }

  void _sifreSorgula() {
    final TextEditingController c = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Teknisyen Girişi'),
        content: TextField(
          controller: c,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Şifre'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              if (c.text == _password) setState(() => _sayfaIndex = 2);
              Navigator.pop(ctx);
            },
            child: const Text('Giriş'),
          ),
        ],
      ),
    );
  }

  Widget _teknisyenBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Ragle Hızı'),
          subtitle: Text('$hiz'),
          trailing: _ayarS('Ragle Hizi', hiz, 200, 2000, 'hiz'),
        ),
        ListTile(
          title: const Text('Bant Süresi'),
          subtitle: Text('$bant'),
          trailing: _ayarS('Bant Suresi', bant, 100, 5000, 'bant'),
        ),
        ListTile(
          title: const Text('Ana Piston Süresi'),
          subtitle: Text('$anaP'),
          trailing: _ayarS('Ana Piston Suresi', anaP, 100, 2000, 'ap'),
        ),
        ListTile(
          title: const Text('Ragle Piston Süresi'),
          subtitle: Text('$ragP'),
          trailing: _ayarS('Ragle Piston Suresi', ragP, 100, 2000, 'rp'),
        ),
        const Divider(),
        ListTile(
          title: const Text('Şifre Değiştir'),
          trailing: ElevatedButton(
            onPressed: _showChangePasswordDialog,
            child: const Text('Değiştir'),
          ),
        ),
        ListTile(
          title: const Text('Sayaç Sıfırla'),
          trailing: ElevatedButton(
            onPressed: _performFactoryReset,
            child: const Text('Sıfırla'),
          ),
        ),
        const Divider(),
        // ESP32 Pin Dökümü Butonu
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TechnicianMenuExtra(deviceIp: ip),
        ),
      ],
    );
  }

  Widget _ayarS(String t, double v, double min, double max, String p) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove),
          onPressed: () {
            setState(() {});
            _gonder("set?$p=${(v - 10).toInt()}");
          },
        ),
        Text('${v.toInt()}'),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            setState(() {});
            _gonder("set?$p=${(v + 10).toInt()}");
          },
        ),
      ],
    );
  }
}
