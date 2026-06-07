import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health Trader',
      theme: ThemeData.dark(),
      home: const HealthPage(),
    );
  }
}

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final HealthFactory health = HealthFactory();
  bool isLoading = true;
  bool hasPermission = false;

  int steps = 0;
  int heartRate = 0;
  double sleepHours = 0;

  @override
  void initState() {
    super.initState();
    _getHealthData();
  }

  Future<void> _getHealthData() async {
    setState(() => isLoading = true);

    try {
      // درخواست مجوز
      final types = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.SLEEP_ASLEEP,
      ];
      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      final granted = await health.requestAuthorization(types, permissions: permissions);

      if (!granted) {
        setState(() {
          hasPermission = false;
          isLoading = false;
        });
        return;
      }

      hasPermission = true;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = DateTime(now.year, now.month, now.day - 1);

      // گرفتن قدم‌ها
      final stepsData = await health.getHealthDataFromTypes(today, now, [HealthDataType.STEPS]);
      steps = stepsData.fold<int>(0, (sum, point) => sum + point.value.toInt());

      // گرفتن ضربان قلب (میانگین)
      final hrData = await health.getHealthDataFromTypes(today, now, [HealthDataType.HEART_RATE]);
      if (hrData.isNotEmpty) {
        double avg = hrData.fold<double>(0, (sum, point) => sum + point.value) / hrData.length;
        heartRate = avg.round();
      }

      // گرفتن خواب
      final sleepData = await health.getHealthDataFromTypes(yesterday, today, [HealthDataType.SLEEP_ASLEEP]);
      int sleepSec = sleepData.fold<int>(0, (sum, point) => sum + point.value.toInt());
      sleepHours = sleepSec / 3600;

      setState(() {});
    } catch (e) {
      print("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trader Health')),
      body: RefreshIndicator(
        onRefresh: _getHealthData,
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!hasPermission)
                        const Text(
                          '⚠️ ابتدا دسترسی Health را بدهید',
                          style: TextStyle(color: Colors.orange),
                        ),
                      const SizedBox(height: 20),
                      _buildCard('👣 قدم', '$steps', 'گام'),
                      const SizedBox(height: 16),
                      _buildCard('❤️ ضربان قلب', heartRate == 0 ? '---' : '$heartRate', 'BPM'),
                      const SizedBox(height: 16),
                      _buildCard('😴 خواب', '${sleepHours.toStringAsFixed(1)}', 'ساعت'),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _getHealthData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('بروزرسانی'),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildCard(String title, String value, String unit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(unit, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
