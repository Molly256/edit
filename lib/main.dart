import 'package:flutter/material.dart';

void main() => runApp(const MaterialApp(home: LiveCloneStudioPage(), debugShowCheckedModeBanner: false));

class LiveCloneStudioPage extends StatefulWidget {
  const LiveCloneStudioPage({super.key});
  @override
  State<LiveCloneStudioPage> createState() => _LiveCloneStudioPageState();
}

class _LiveCloneStudioPageState extends State<LiveCloneStudioPage> {
  final _time = TextEditingController(text: "12:29");
  final _battery = TextEditingController(text: "85");
  final _title = TextEditingController(text: "Congratulations!");
  final _subTitle = TextEditingController(text: "Funding Award Received");
  final _amount = TextEditingController(text: "53.00");
  final _currency = TextEditingController(text: "USD");
  double _batLvl = 0.85;

  @override
  void initState() {
    super.initState();
    _battery.addListener(() {
      final val = double.tryParse(_battery.text);
      if (val != null) setState(() => _batLvl = (val / 100).clamp(0.0, 1.0));
    });
  }

  @override
  void dispose() {
    for (var c in [_time, _battery, _title, _subTitle, _amount, _currency]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F14),
      appBar: AppBar(title: const Text('Workspace'), backgroundColor: const Color(0xFF16161F)),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 360, height: 640,
            margin: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10, width: 2),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(width: 50, child: TextField(controller: _time, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none, isDense: true))),
                      Row(
                        children: [
                          SizedBox(width: 25, child: TextField(controller: _battery, textAlign: TextAlign.end, style: const TextStyle(color: Colors.white, fontSize: 12), decoration: const InputDecoration(border: InputBorder.none, isDense: true))),
                          const Text("% ", style: TextStyle(color: Colors.white, fontSize: 12)),
                          Container(
                            width: 20, height: 10, padding: const EdgeInsets.all(1),
                            decoration: Border.all(color: Colors.white70),
                            child: Align(alignment: Alignment.centerLeft, child: Container(width: 14 * _batLvl, color: _batLvl < 0.2 ? Colors.red : Colors.green)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: const Color(0xFF252538), borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      TextField(controller: _title, textAlign: TextAlign.center, maxLines: null, style: const TextStyle(color: Colors.amberAccent, fontSize: 22, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none, isDense: true)),
                      const SizedBox(height: 6),
                      TextField(controller: _subTitle, textAlign: TextAlign.center, maxLines: null, style: const TextStyle(color: Color(0xFFCDD6F4), fontSize: 13), decoration: const InputDecoration(border: InputBorder.none, isDense: true)),
                      const Divider(color: Colors.white12, height: 24),
                      TextField(controller: _amount, textAlign: TextAlign.center, keyboardType: TextInputType.number, style: const TextStyle(color: Color(0xFFA6E3A1), fontSize: 44, fontWeight: FontWeight.black, fontFamily: 'monospace'), decoration: const InputDecoration(border: InputBorder.none, isDense: true)),
                      TextField(controller: _currency, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFA6E3A1), fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'monospace'), decoration: const InputDecoration(border: InputBorder.none, isDense: true)),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16), color: const Color(0xFF11111B),
                  child: const Row(children: [Icon(Icons.check_circle, color: Colors.greenAccent, size: 18), SizedBox(width: 8), Text("Logged via Secure API", style: TextStyle(color: Colors.grey, fontSize: 12))]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}