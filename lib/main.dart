import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const SalahLiteApp());
}

class SalahLiteApp extends StatelessWidget {
  const SalahLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salah Lite',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: const PrayerTimesScreen(),
    );
  }
}

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  bool isLoading = true;
  String cityName = '';
  Map<String, dynamic> todayPrayerTimes = {};
  Map<String, dynamic> tomorrowPrayerTimes = {};
  String errorMessage = '';
  bool isToday = true;

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition();

      // Get city name from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        cityName = place.locality ?? place.subAdministrativeArea ?? 'Unknown';
      }

      // Get today's date
      DateTime today = DateTime.now();
      DateTime tomorrow = today.add(const Duration(days: 1));

      // Format dates for API
      String todayFormatted = DateFormat('dd-MM-yyyy').format(today);
      String tomorrowFormatted = DateFormat('dd-MM-yyyy').format(tomorrow);

      // Fetch prayer times for today
      todayPrayerTimes = await _fetchPrayerTimes(
        position.latitude,
        position.longitude,
        todayFormatted,
      );

      // Fetch prayer times for tomorrow
      tomorrowPrayerTimes = await _fetchPrayerTimes(
        position.latitude,
        position.longitude,
        tomorrowFormatted,
      );

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<Map<String, dynamic>> _fetchPrayerTimes(
      double latitude, double longitude, String date) async {
    final response = await http.get(Uri.parse(
        'https://api.aladhan.com/v1/timings/$date?latitude=$latitude&longitude=$longitude&method=2'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['timings'];
    } else {
      throw Exception('Failed to load prayer times');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Error. Couldn't load prayer times",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadPrayerTimes,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              cityName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(
                                isToday
                                    ? DateTime.now()
                                    : DateTime.now()
                                        .add(const Duration(days: 1)),
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isToday = true;
                              });
                            },
                            style: isToday
                                ? TextButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1))
                                : null,
                            child: Text(
                              'Today',
                              style: TextStyle(
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                isToday = false;
                              });
                            },
                            style: !isToday
                                ? TextButton.styleFrom(
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.1),
                                  )
                                : null,
                            child: Text(
                              'Tomorrow',
                              style: TextStyle(
                                fontWeight: !isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: !isToday
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            _buildPrayerTimeCard(
                              'Fajr',
                              isToday
                                  ? todayPrayerTimes['Fajr']
                                  : tomorrowPrayerTimes['Fajr'],
                              Icons.nightlight_round,
                            ),
                            _buildPrayerTimeCard(
                              'Sunrise',
                              isToday
                                  ? todayPrayerTimes['Sunrise']
                                  : tomorrowPrayerTimes['Sunrise'],
                              Icons.wb_sunny_outlined,
                            ),
                            _buildPrayerTimeCard(
                              'Dhuhr',
                              isToday
                                  ? todayPrayerTimes['Dhuhr']
                                  : tomorrowPrayerTimes['Dhuhr'],
                              Icons.wb_sunny,
                            ),
                            _buildPrayerTimeCard(
                              'Asr',
                              isToday
                                  ? todayPrayerTimes['Asr']
                                  : tomorrowPrayerTimes['Asr'],
                              Icons.wb_twighlight,
                            ),
                            _buildPrayerTimeCard(
                              'Maghrib',
                              isToday
                                  ? todayPrayerTimes['Maghrib']
                                  : tomorrowPrayerTimes['Maghrib'],
                              Icons.nights_stay_outlined,
                            ),
                            _buildPrayerTimeCard(
                              'Isha',
                              isToday
                                  ? todayPrayerTimes['Isha']
                                  : tomorrowPrayerTimes['Isha'],
                              Icons.nights_stay,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadPrayerTimes,
        mini: true,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildPrayerTimeCard(String name, String time, IconData icon) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
            ),
            const Spacer(),
            Text(
              _formatTime(time),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String time24) {
    // Convert 24-hour format to 12-hour format
    final timeParts = time24.split(':');
    if (timeParts.length != 2) return time24;

    int hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = timeParts[1];
    final period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$hour:$minute $period';
  }
}
