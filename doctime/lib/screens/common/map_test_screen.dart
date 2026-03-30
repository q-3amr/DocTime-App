import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapTestScreen extends StatefulWidget {
  @override
  _MapTestScreenState createState() => _MapTestScreenState();
}

class _MapTestScreenState extends State<MapTestScreen> {
  // إحداثيات (جامعة العلوم والتكنولوجيا - التكنو) عشان نجرب عليها
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(32.4948, 35.9912), 
    zoom: 15.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('فحص الخريطة - DocTime'),
        backgroundColor: Colors.blueAccent,
      ),
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        mapType: MapType.normal,
        onMapCreated: (GoogleMapController controller) {
          // الخريطة اشتغلت!
        },
      ),
    );
  }
}