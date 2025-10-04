import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Add your OPENWEATHER_API_KEY here
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Futuristic Weather App",
      theme: ThemeData.dark(),
      home: const WeatherHome(),
    );
  }
}

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  Map<String, dynamic>? weatherData;
  bool isLoading = false;

  late AnimationController _animationController;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _animationController =
    AnimationController(vsync: this, duration: const Duration(seconds: 20))
      ..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> fetchWeather(String city) async {
    setState(() {
      isLoading = true;
    });

    final apiKey = dotenv.env['OPENWEATHER_API_KEY']!;
    final url =
        "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=$apiKey&units=metric";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          weatherData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          weatherData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        weatherData = null;
        isLoading = false;
      });
    }
  }

  String getWeatherEmoji(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'snow':
        return '❄️';
      case 'thunderstorm':
        return '⚡';
      default:
        return '🌤️';
    }
  }

  String getMood(String main) {
    switch (main.toLowerCase()) {
      case 'clear':
        return "Perfect day for a walk 👟";
      case 'clouds':
        return "Coffee & music ☕🎶";
      case 'rain':
        return "Read a book ☔📖";
      case 'snow':
        return "Stay cozy 🧣❄️";
      case 'thunderstorm':
        return "Stay safe indoors ⚡🎬";
      default:
        return "Enjoy your day 🌈";
    }
  }

  LinearGradient getSkyGradient(String main) {
    final hour = DateTime.now().hour;
    if (hour < 6 || hour > 18) {
      return const LinearGradient(
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter);
    }
    switch (main.toLowerCase()) {
      case 'clear':
        return const LinearGradient(
            colors: [Color(0xFFFEF253), Color(0xFFFF7300)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case 'clouds':
        return const LinearGradient(
            colors: [Color(0xFFB0BEC5), Color(0xFF78909C)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case 'rain':
        return const LinearGradient(
            colors: [Color(0xFF4A148C), Color(0xFF880E4F)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      case 'snow':
        return const LinearGradient(
            colors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
      default:
        return const LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mainWeather =
    weatherData != null ? weatherData!["weather"][0]["main"] : 'default';
    final emoji =
    weatherData != null ? getWeatherEmoji(weatherData!["weather"][0]["main"]) : '🌍';
    final cityName = weatherData != null ? weatherData!["name"] : '';

    return Scaffold(
      body: Stack(
        children: [
          // Sky Gradient Background
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: getSkyGradient(mainWeather),
            ),
          ),
          // Floating Particles
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: ParticlePainter(
                controller: _animationController,
                weather: mainWeather,
                random: random),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Enter City",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.2),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search, color: Colors.white),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            fetchWeather(_controller.text.trim());
                          }
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
                isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : weatherData == null
                    ? const Text(
                  "Enter a city to see the weather 🌍",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                )
                    : Expanded(
                  child: Center(
                    child: GlassCircularCard(
                      cityName: cityName,
                      emoji: emoji,
                      temp: weatherData!["main"]["temp"],
                      weather: mainWeather,
                      description: weatherData!["weather"][0]
                      ["description"]
                          .toString()
                          .toUpperCase(),
                      mood: getMood(mainWeather),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- Glass Circular Weather Card ----------------
class GlassCircularCard extends StatelessWidget {
  final String cityName;
  final String emoji;
  final double temp;
  final String weather;
  final String description;
  final String mood;

  const GlassCircularCard({
    super.key,
    required this.cityName,
    required this.emoji,
    required this.temp,
    required this.weather,
    required this.description,
    required this.mood,
  });

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                emoji,
                style: const TextStyle(fontSize: 50),
              ),
              const SizedBox(height: 10),
              Text(
                cityName,
                style:
                const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                "${temp.toStringAsFixed(1)} °C",
                style:
                const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(description, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              Text(mood, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------- Particle Painter ----------------
class ParticlePainter extends CustomPainter {
  final AnimationController controller;
  final String weather;
  final Random random;

  ParticlePainter({
    required this.controller,
    required this.weather,
    required this.random,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5);

    if (weather.toLowerCase() == 'rain') {
      for (int i = 0; i < 150; i++) {
        double x = random.nextDouble() * size.width;
        double y = (random.nextDouble() * size.height +
            controller.value * size.height) %
            size.height;
        canvas.drawLine(Offset(x, y), Offset(x, y + 10), paint);
      }
    } else if (weather.toLowerCase() == 'snow') {
      for (int i = 0; i < 80; i++) {
        double x = random.nextDouble() * size.width;
        double y = (random.nextDouble() * size.height +
            controller.value * size.height) %
            size.height;
        canvas.drawCircle(Offset(x, y), 4, paint);
      }
    } else if (weather.toLowerCase() == 'clouds') {
      for (int i = 0; i < 6; i++) {
        double x = (controller.value * size.width + i * 100) % size.width;
        double y = 50.0 + i * 30;
        canvas.drawCircle(Offset(x, y), 40, paint);
      }
    } else {
      // Night stars
      for (int i = 0; i < 60; i++) {
        double x = random.nextDouble() * size.width;
        double y = random.nextDouble() * size.height / 2;
        paint.color = Colors.white.withOpacity(random.nextDouble());
        canvas.drawCircle(Offset(x, y), 2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}




