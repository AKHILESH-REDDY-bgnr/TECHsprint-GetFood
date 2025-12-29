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
/* ----------------open navigation---------------- */
Future<void> openNavigation(
  double? fromLat,
  double? fromLng,
  double? toLat,
  double? toLng,
) async {
  if (fromLat == null || fromLng == null || toLat == null || toLng == null) {
    debugPrint("Navigation failed: Null location values");
    return;
  }

  final Uri googleMapsUri = Uri.parse(
    "https://www.google.com/maps/dir/?api=1"
    "&origin=$fromLat,$fromLng"
    "&destination=$toLat,$toLng"
    "&travelmode=driving",
  );

  if (!await canLaunchUrl(googleMapsUri)) {
    debugPrint("Could not launch Google Maps");
    return;
  }

  await launchUrl(
    googleMapsUri,
    mode: LaunchMode.externalApplication,
  );
}


/* ---------------- DASHBOARD CARD ---------------- */

class MealsSavedDashboard extends StatelessWidget {
  const MealsSavedDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where('status', isEqualTo: 'Received')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          );
        }

        int mealsSaved = 0;

for (var doc in snapshot.data!.docs) {
  final int qty = doc['quantity'];

  if (doc['status'] == 'Received') {
    mealsSaved += qty;
  }
}
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Meals Saved",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      mealsSaved.toString(),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


/* ---------------- DASHBOARD WIDGET ---------------- */

class DashboardWidget extends StatelessWidget {
  const DashboardWidget({super.key});

  Widget statCard(String title, IconData icon, Color color, String field, String equals) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('donations')
          .where(field, isEqualTo: equals)
          .snapshots(),
      builder: (context, snapshot) {
        int count = snapshot.hasData ? snapshot.data!.docs.fold<int>(
          0,
          (sum, doc) => sum + (doc['quantity'] as int),
        ) : 0;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "$count meals",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        const Text(
          "📊 Impact Dashboard",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          children: [
            statCard("Meals Saved", Icons.check_circle, Colors.green, 'status', 'Received'),
            statCard("Available", Icons.restaurant, Colors.orange, 'status', 'Available'),
            statCard("Accepted", Icons.volunteer_activism, Colors.blue, 'status', 'Accepted'),
            statCard("Total Posts", Icons.food_bank, Colors.purple, 'status', 'Received'),
          ],
        ),
      ],
    );
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
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.green,
    primary: Colors.green.shade700,
    secondary: Colors.green.shade400,
  ),
  scaffoldBackgroundColor: const Color(0xFFF3F7F5),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    elevation: 0,
  ),
  cardTheme: CardThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
  ),
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
  padding: const EdgeInsets.all(20),
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
      body: SingleChildScrollView(
  padding: const EdgeInsets.all(20),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
            const Icon(Icons.food_bank, size: 90, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              "GetFood",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            const SizedBox(height: 10),
            const DashboardWidget(),
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
  LatLng selected = const LatLng(20.5937, 78.9629); // India center
  GoogleMapController? mapController;

  Future<void> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Pickup Location")),
      body: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: CameraPosition(
          target: selected,
          zoom: 15,
        ),
        onMapCreated: (controller) {
          mapController = controller;
        },
        markers: {
          Marker(
            markerId: const MarkerId("pickup"),
            position: selected,
            draggable: true,
            onDragEnd: (pos) {
              setState(() => selected = pos);
            },
          ),
        },
        onTap: (pos) {
          setState(() {
            selected = pos;
          });

          mapController?.animateCamera(
            CameraUpdate.newLatLng(pos),
          );
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomGesturesEnabled: true,
        scrollGesturesEnabled: true,
        rotateGesturesEnabled: true,
        tiltGesturesEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text("Confirm Location"),
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
/*---------NGO LOCATION PICKER---------*/
class NGOLocationPicker extends StatefulWidget {
  const NGOLocationPicker({super.key});

  @override
  State<NGOLocationPicker> createState() => _NGOLocationPickerState();
}

class _NGOLocationPickerState extends State<NGOLocationPicker> {
  LatLng selected = const LatLng(20.5937, 78.9629); // India center

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select NGO Location")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: selected,
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("ngo"),
            position: selected,
            draggable: true,
            onDragEnd: (pos) => setState(() => selected = pos),
          ),
        },
        onTap: (pos) => setState(() => selected = pos),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.check),
        label: const Text("Confirm Location"),
        onPressed: () => Navigator.pop(context, selected),
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
        stream: FirebaseFirestore.instance.collection('donations').snapshots(),
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
                  trailing: Builder(
                    builder: (context) {
                      final status = doc['status'];

                      if (status == "Available") {
                        return ElevatedButton(
                          child: const Text("Accept"),
                          onPressed: () async {
  final LatLng? ngoLoc = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const NGOLocationPicker(),
    ),
  );

  if (ngoLoc == null) return;

  await doc.reference.update({
    'status': 'Accepted',
    'ngoLocation': {
      'lat': ngoLoc.latitude,
      'lng': ngoLoc.longitude,
                       },
                      });

                       ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text("Donation accepted & location set")),
                          );
                         },
                        );
                      }

                      if (status == "Delivered") {
                        return ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle),
                          label: const Text("Received"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            await doc.reference
                                .update({'status': 'Received'});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text("Food marked as received")),
                            );
                          },
                        );
                      }

                      if (status == "Received") {
                        return const Chip(
                          label: Text("Received"),
                          backgroundColor: Colors.green,
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }

                      return const Icon(
                        Icons.check_circle,
                        color: Colors.blue,
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

// ==================== VOLUNTEER ====================

class VolunteerScreen extends StatefulWidget {
  const VolunteerScreen({super.key});

  @override
  State<VolunteerScreen> createState() => _VolunteerScreenState();
}

class _VolunteerScreenState extends State<VolunteerScreen> {
  Future<Position> getCurrentLocation() async {
    await Geolocator.requestPermission();
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Volunteer Panel")),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('donations')
            .where('status', whereIn: ['Accepted', 'Picked Up'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No deliveries available",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String status = data['status'] ?? '';

              return Card(
                margin: const EdgeInsets.all(12),
                child: ListTile(
                  title: Text(
                    data['food'] ?? 'Food',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Meals: ${data['quantity'] ?? 0}",
                  ),
                  trailing: Builder(
                    builder: (context) {
                      // ================= PICK UP =================
                      if (status == "Accepted") {
                        return ElevatedButton(
                          child: const Text("Pick Up Food"),
                          onPressed: () async {
                            final position =
                                await getCurrentLocation();

                            final double pickupLat = data['lat'];
                            final double pickupLng = data['lng'];

                            await openNavigation(
                              position.latitude,
                              position.longitude,
                              pickupLat,
                              pickupLng,
                            );

                            await doc.reference.update({
                              'status': 'Picked Up',
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Navigate to pickup location"),
                              ),
                            );
                          },
                        );
                      }

                      // ================= DELIVER =================
                      if (status == "Picked Up") {
                        final ngoLocation =
                            data['ngoLocation'] as Map<String, dynamic>?;

                        if (ngoLocation == null) {
                          return const Text(
                            "NGO location not set",
                            style: TextStyle(color: Colors.red),
                          );
                        }

                        final double ngoLat = ngoLocation['lat'];
                        final double ngoLng = ngoLocation['lng'];

                        final double pickupLat = data['lat'];
                        final double pickupLng = data['lng'];

                        return ElevatedButton(
                          child: const Text("Deliver to NGO"),
                          onPressed: () async {
                            await openNavigation(
                              pickupLat,
                              pickupLng,
                              ngoLat,
                              ngoLng,
                            );

                            await doc.reference.update({
                              'status': 'Delivered',
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text("Navigate to NGO location"),
                              ),
                            );
                          },
                        );
                      }

                      return const Icon(
                        Icons.check_circle,
                        color: Colors.green,
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

          int mealsSaved = 0;
int deliveredMeals = 0;

for (var doc in snapshot.data!.docs) {
  final int qty = doc['quantity'];

  if (doc['status'] == 'Received') {
    mealsSaved += qty;
  }

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
  value: mealsSaved.toString(),
  icon: Icons.favorite,
  color: Colors.green,
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
                  title: "Meals In Transit",
                   value: deliveredMeals.toString(),
                    icon: Icons.delivery_dining,
                    color: Colors.orange,
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