import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart'; // لازم تضيف هاي المكتبة في pubspec.yaml

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({Key? key}) : super(key: key);

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _initialPosition = LatLng(31.9539, 35.9106); 
  LatLng? _pickedLocation;
  GoogleMapController? _mapController;

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  // دالة لتحديد الموقع الحالي ونقل الكاميرا إليه
  Future<void> _goToCurrentLocation() async {
    // نطلب الإذن من المستخدم للوصول للموقع
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15),
      );
      
      setState(() {
        _pickedLocation = currentLatLng;
      });
    }
  }

  void _selectLocation(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('حدد موقع العيادة'),
        actions: [
          if (_pickedLocation != null)
            IconButton(
              icon: const Icon(Icons.check, color: Colors.green, size: 30),
              onPressed: () => Navigator.of(context).pop(_pickedLocation),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: _initialPosition,
              zoom: 13,
            ),
            onTap: _selectLocation,
            myLocationEnabled: true, // بظهر النقطة الزرقاء تاعت موقعك
            myLocationButtonEnabled: false, // بنطفي الزر الأصلي عشان نتحكم بمكانه
            markers: _pickedLocation == null
                ? {}
                : {
                    Marker(
                      markerId: const MarkerId('picked_location'),
                      position: _pickedLocation!,
                    ),
                  },
          ),
        ],
      ),
      // زر تحديد الموقع التلقائي بشكل أجمل
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCurrentLocation,
        label: const Text('موقعي الحالي'),
        icon: const Icon(Icons.my_location),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}