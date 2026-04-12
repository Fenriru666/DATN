import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/features/auth/services/auth_service.dart';
import 'package:datn/core/constants/map_constants.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});

  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  Stream<UserModel?> _streamCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
      return null;
    });
  }

  Future<void> _openPlaceSearch(BuildContext context, String label) async {
    final result = await showSearch(
      context: context,
      delegate: PlaceSearchDelegate(),
    );

    if (result != null) {
      try {
        await _authService.updateSavedPlace(
          _auth.currentUser!.uid,
          label,
          result,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật địa chỉ ${label == 'home' ? 'Nhà riêng' : 'Công ty'}')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật địa chỉ: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Địa Điểm Yêu Thích'),
        elevation: 0,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _streamCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không tìm thấy dữ liệu."));
          }

          final user = snapshot.data!;
          final savedPlaces = user.savedPlaces ?? {};
          final home = savedPlaces['home'];
          final work = savedPlaces['work'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPlaceItem(
                context,
                icon: Icons.home,
                title: 'Nhà riêng',
                subtitle: home?['address'] ?? 'Chưa thiết lập',
                onTap: () => _openPlaceSearch(context, 'home'),
              ),
              const Divider(),
              _buildPlaceItem(
                context,
                icon: Icons.work,
                title: 'Công ty',
                subtitle: work?['address'] ?? 'Chưa thiết lập',
                onTap: () => _openPlaceSearch(context, 'work'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaceItem(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFFE724C).withValues(alpha: 0.1),
        child: Icon(icon, color: const Color(0xFFFE724C)),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}

class PlaceSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  Future<List<dynamic>> _searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final url = Uri.parse(
        'https://rsapi.goong.io/Place/AutoComplete?api_key=${MapConstants.goongServiceKey}&input=$query');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['predictions'] ?? [];
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>?> _getPlaceDetails(String placeId) async {
    final url = Uri.parse(
        'https://rsapi.goong.io/Place/Detail?place_id=$placeId&api_key=${MapConstants.goongServiceKey}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['geometry'] != null) {
          final location = data['result']['geometry']['location'];
          return {
            'address': data['result']['formatted_address'],
            'lat': location['lat'],
            'lng': location['lng'],
          };
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
    }
    return null;
  }

  @override
  String get searchFieldLabel => 'Tìm kiếm địa chỉ...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return buildSuggestions(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Nhập từ khóa để tìm kiếm...'));
    }

    return FutureBuilder<List<dynamic>>(
      future: _searchPlaces(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Không tìm thấy kết quả.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final prediction = snapshot.data![index];
            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.grey),
              title: Text(prediction['description']),
              onTap: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(child: CircularProgressIndicator()),
                );

                final details = await _getPlaceDetails(prediction['place_id']);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close loading dialog
                  close(context, details); // Return details
                }
              },
            );
          },
        );
      },
    );
  }
}
