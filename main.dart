import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

/* ---------------- HELPERS ---------------- */

Color statusColor(String status) {
  switch (status) {
    case "Available":
      return Colors.orange;
    case "Accepted":
      return Colors.blue;
    case "Delivered":
      return Colors.green;
    default:
      return Colors.grey;
  }
}

/* ---------------- MAIN ---------------- */

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FoodApp());
}

/* ---------------- APP ROOT ---------------- */

class FoodApp extends StatelessWidget {
  const FoodApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Redistribution App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const AuthGate(),
    );
  }
}

/* ---------------- AUTH GATE ---------------- */

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const LoginScreen(); // role selection
        }

        return const AuthScreen();
      },
    );
  }
}

/* ---------------- AUTH SCREEN ---------------- */

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  bool isLogin = true;
  bool loading = false;

  Future<void> submit() async {
    setState(() => loading = true);

    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text.trim(),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: submit,
                    child: Text(isLogin ? "Login" : "Register"),
                  ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin
                    ? "Create new account"
                    : "Already have an account?",
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- ROLE SELECTION ---------------- */

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Widget roleCard(
    BuildContext context,
    String title,
    IconData icon,
    Widget screen,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.green, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => screen)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Food Redistribution App"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.food_bank, size: 90, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "GetFood",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            roleCard(
              context,
              "Restaurant",
              Icons.restaurant,
              const RestaurantScreen(),
            ),
            roleCard(
              context,
              "NGO",
              Icons.volunteer_activism,
              const NGOScreen(),
            ),
            roleCard(
              context,
              "Volunteer",
              Icons.delivery_dining,
              const VolunteerScreen(),
            ),
            roleCard(
              context,
              "Impact Dashboard",
               Icons.analytics,
               const DashboardScreen(),
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- PICK LOCATION ---------------- */

class PickLocationScreen extends StatefulWidget {
  const PickLocationScreen({super.key});

  @override
  State<PickLocationScreen> createState() => _PickLocationScreenState();
}

class _PickLocationScreenState extends State<PickLocationScreen> {
  LatLng selected = const LatLng(20.5937, 78.9629);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Pickup Location")),
      body: GoogleMap(
        initialCameraPosition:
            CameraPosition(target: selected, zoom: 14),
        markers: {
          Marker(
            markerId: const MarkerId("pickup"),
            position: selected,
            draggable: true,
            onDragEnd: (pos) => setState(() => selected = pos),
          ),
        },
        onTap: (pos) => setState(() => selected = pos),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text("Confirm"),
        onPressed: () => Navigator.pop(context, selected),
      ),
    );
  }
}

/* ---------------- RESTAURANT ---------------- */

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen> {
  final food = TextEditingController();
  final qty = TextEditingController();

  LatLng? pickupLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Restaurant – Donate Food")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: food,
              decoration: const InputDecoration(labelText: "Food Item"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Quantity"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.location_on),
              label: const Text("Select Pickup Location"),
              onPressed: () async {
                pickupLocation = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PickLocationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text("Donate"),
              onPressed: () async {
                if (pickupLocation == null) return;

                await FirebaseFirestore.instance
                    .collection('donations')
                    .add({
                  'food': food.text,
                  'quantity': int.parse(qty.text),
                  'status': 'Available',
                  'lat': pickupLocation!.latitude,
                  'lng': pickupLocation!.longitude,
                });

                food.clear();
                qty.clear();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Food donation posted successfully"),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* ---------------- NGO ---------------- */

class NGOScreen extends StatelessWidget {
  const NGOScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("NGO Dashboard")),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('donations').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Card(
                margin: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ListTile(
                  title: Text(
                    doc['food'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Meals: ${doc['quantity']}"),
                      const SizedBox(height: 6),
                      Chip(
                        label: Text(doc['status']),
                        backgroundColor:
                            statusColor(doc['status']).withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: statusColor(doc['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: doc['status'] == "Available"
                      ? ElevatedButton(
                          child: const Text("Accept"),
                          onPressed: () {
                            doc.reference.update(
                              {'status': 'Accepted'},
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Donation accepted"),
                              ),
                            );
                          },
                        )
                      : const Icon(Icons.check_circle,
                          color: Colors.green),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

/* ---------------- VOLUNTEER ---------------- */

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  StreamSubscription<Position>? positionStream;

  @override
  void initState() {
    super.initState();
    startTracking();
  }

  Future<void> startTracking() async {
    bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission =
        await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    positionStream = Geolocator.getPositionStream(
      locationSettings:
          const LocationSettings(accuracy: LocationAccuracy.high),
    ).listen((position) {
      FirebaseFirestore.instance
          .collection('volunteer')
          .doc('live')
          .set({
        'lat': position.latitude,
        'lng': position.longitude,
      });
    });
  }

  Future<void> openNavigation(double lat, double lng) async {
    final uri = Uri.parse(
      "https://www.google.com/maps/dir/?api=1&destination=$lat,$lng",
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  void dispose() {
    positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Volunteer Panel")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('status', isEqualTo: 'Accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(doc['food']),
                  subtitle:
                      Text("Meals: ${doc['quantity']}"),
                  trailing: ElevatedButton(
                    child: const Text("Deliver"),
                    onPressed: () async {
                      await openNavigation(
                        doc['lat'],
                        doc['lng'],
                      );
                      await doc.reference
                          .update({'status': 'Delivered'});

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text("Delivery completed"),
                        ),
                      );
                    },
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
/* ---------------- DASHBOARD ---------------- */

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Impact Dashboard"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          int totalMeals = 0;
          int deliveredMeals = 0;

          for (var doc in snapshot.data!.docs) {
            final int qty = doc['quantity'];
            totalMeals += qty;

            if (doc['status'] == 'Delivered') {
              deliveredMeals += qty;
            }
          }

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                dashboardCard(
                  title: "Total Meals Donated",
                  value: totalMeals.toString(),
                  icon: Icons.restaurant,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),
                dashboardCard(
                  title: "Meals Successfully Delivered",
                  value: deliveredMeals.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                const SizedBox(height: 20),
                dashboardCard(
                  title: "Meals Yet To Be Delivered",
                  value: (totalMeals - deliveredMeals).toString(),
                  icon: Icons.pending,
                  color: Colors.blue,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget dashboardCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

