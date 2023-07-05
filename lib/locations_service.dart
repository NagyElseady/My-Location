import 'package:cloud_firestore/cloud_firestore.dart';

import 'location_item.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<LocationItem>> getLocations() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('locations').get();
    final List<LocationItem> locations = snapshot.docs.map((doc) {
      final data = doc.data();
      return LocationItem(
        lat: data['lat'],
        lng: data['lng'],
      );
    }).toList();
    return locations;
  }
}
