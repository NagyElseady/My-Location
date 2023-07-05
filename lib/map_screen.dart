import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_item.dart';
import 'locations_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Set<Marker> _markers = {};
  Position? _currentPosition;
  List<LocationItem> _locations = [];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadLocations();
  }

  Future<void> _getCurrentLocation() async {
    _currentPosition = await _determinePosition();
    setState(() {});
  }

  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    return await Geolocator.getCurrentPosition();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Screen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentPosition?.latitude ?? 0,
            _currentPosition?.longitude ?? 0,
          ),
          zoom: 16,
        ),
        onMapCreated: _onMapCreated,
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {}

  Future<void> _addMarker(LatLng tappedPoint) async {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(tappedPoint.toString()),
        position: tappedPoint,
        infoWindow: const InfoWindow(
            title: 'New Marker', snippet: 'This is a new marker.'),
        icon: BitmapDescriptor.defaultMarker,
      ));
    });
  }

  void _showLocations(List<LocationItem> locations) {
    setState(() {
      for (LocationItem location in locations) {
        _addMarker(LatLng(location.lat, location.lng));
      }
    });
  }

  void _loadLocations() async {
    final locations = await FirestoreService().getLocations();
    _showLocations(locations);
  }
}
