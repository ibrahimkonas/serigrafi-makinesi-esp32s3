import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class OperatorPanel extends StatelessWidget {
  final int sayac;
  final double basinc;
  final double vakum;
  final double hiz;
  final double bant;
  final bool isOto;
  final String durum;
  final bool isOnline;
  final bool isError;
  final VoidCallback onReset;
  final int target;
  final void Function(int) onSetTarget;
  final void Function(String path) onSend;

  const OperatorPanel({
    super.key,
    required this.sayac,
    required this.basinc,
    required this.vakum,
    required this.hiz,
    required this.bant,
    required this.isOto,
    required this.durum,
    required this.isOnline,
    required this.isError,
    required this.onReset,
    required this.onSend,
    required this.target,
    required this.onSetTarget,
  });

  Widget _saat(String t, double v, Color c) => Container(
      height: 160,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white10, borderRadius: BorderRadius.circular(15)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: SfRadialGauge(axes: [
              RadialAxis(
                  minimum: 0,
                  maximum: 10,
                  showLabels: false,
                  pointers: [NeedlePointer(value: v, needleColor: c)])
            ]),
          ),
          const SizedBox(height: 6),
          Text(t, style: const TextStyle(fontSize: 10))
        ],
      ));

  Widget _anaKart(String t, String v) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.blueAccent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15)),
      child: Column(children: [
        Text(t),
        Text(v,
            style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold))
      ]));

  Widget _durumMesaji(String durum, bool isError, VoidCallback onReset) =>
      Row(children: [
        Expanded(
            child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: isError ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(6)),
                child: Text(
                    isError
                        ? (durum.isNotEmpty ? durum : 'Bilinmeyen Hata')
                        : 'MAKİNE ÇALIŞMAYA HAZIR',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isError ? Colors.black : Colors.black)))),
        if (isError) const SizedBox(width: 10),
        if (isError)
          ElevatedButton(
              onPressed: onReset,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: Colors.black),
              child: const Text('RESET'))
      ]);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Row(children: [
          Expanded(child: _anaKart('Sayaç', sayac.toString())),
          const SizedBox(width: 10),
          Expanded(child: _saat('Basınç', basinc, Colors.blue)),
          const SizedBox(width: 10),
          Expanded(child: _saat('Vakum', vakum, Colors.orange)),
        ]),
        const SizedBox(height: 20),
        _durumMesaji(durum, isError, onReset),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: _anaKart('Hız', hiz.toStringAsFixed(0))),
          const SizedBox(width: 10),
          Expanded(child: _anaKart('Bant', bant.toStringAsFixed(0))),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () => onSend('cmd?op=oto'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isOto ? Colors.blue : Colors.grey),
                  child: const Text('Otomatik'))),
          const SizedBox(width: 10),
          Expanded(
              child: ElevatedButton(
                  onPressed: () => onSend('cmd?op=man'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: !isOto ? Colors.blue : Colors.grey),
                  child: const Text('Manuel'))),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: isOnline ? () => onSend('cmd?op=stp') : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  child: const Text('DURDUR'))),
          const SizedBox(width: 10),
          Expanded(
              child: ElevatedButton(
                  onPressed: isOnline ? () => onSend('cmd?op=start') : null,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green),
                  child: const Text('BAŞLAT'))),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: ElevatedButton(
                  onPressed: () => onSend('cmd?op=reset_counter'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange),
                  child: const Text('Sayaç Sıfırla'))),
          const SizedBox(width: 10),
          Expanded(
              child: ElevatedButton(
                  onPressed: () => onSend('cmd?op=reset_error'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple),
                  child: const Text('Hata Sıfırla'))),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(
              child: TextField(
            decoration: const InputDecoration(labelText: 'Hedef Üretim'),
            keyboardType: TextInputType.number,
            onSubmitted: (v) {
              final val = int.tryParse(v);
              if (val != null) onSetTarget(val);
            },
          )),
        ]),
      ]),
    );
  }
}
