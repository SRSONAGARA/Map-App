import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_app/direction_repository.dart';
import 'package:map_app/models/direction_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const CameraPosition initialPosition = CameraPosition(
    target: LatLng(23.0225, 72.5714),
    zoom: 12.4746,
  );
  GoogleMapController? _googleMapController;
  Marker? _origin;
  Marker? _destination;
  Marker? _currentLocation;
  Directions? _info;
  double? tapPointLatitude;
  double? tapPointLongitude;
  String? currentAddress;
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    checkLocationPermission();
  }

  @override
  void dispose() {
    super.dispose();
    _googleMapController!.dispose();
  }

  Future<void> checkLocationPermission() async {
    final bool hasPermission = await requestLocationPermission();
    if (!hasPermission) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
            title: const Text('Location Permission Required'),
            content: const Text(
                'Please grant location permission in settings to use this feature.'),
            actions: <Widget>[
              ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Okay',
                    style: TextStyle(color: Colors.green),
                  ))
            ],
          );
        },
      );
    }
  }

  Future<bool> requestLocationPermission() async {
    final PermissionStatus status =
        await Permission.locationWhenInUse.request();
    return status == PermissionStatus.granted;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[400],
          title: const Text(
            'Map App',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_origin != null)
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9EE0A2)),
                  onPressed: () {
                    _googleMapController!.animateCamera(
                        CameraUpdate.newCameraPosition(CameraPosition(
                            target: _origin!.position, zoom: 16, tilt: 50.0)));
                  },
                  child: const Text(
                    'ORIGIN',
                    style: TextStyle(color: Colors.black),
                  )),
            const SizedBox(width: 5),
            if (_destination != null)
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9EE0A2),
                  ),
                  onPressed: () {
                    _googleMapController!.animateCamera(
                        CameraUpdate.newCameraPosition(CameraPosition(
                            target: _destination!.position,
                            zoom: 16,
                            tilt: 50.0)));
                  },
                  child: const Text(
                    'DESTINATION',
                    style: TextStyle(color: Colors.black),
                  )),
          ],
        ),
        body: Stack(alignment: Alignment.center, children: [
          GoogleMap(
            mapType: MapType.hybrid,
            initialCameraPosition: initialPosition,
            onMapCreated: (controller) => _googleMapController = controller,
            markers: {
              if (_origin != null) _origin!,
              if (_destination != null) _destination!,
              if (_currentLocation != null) _currentLocation!,
            },
            polylines: {
              if (_info != null)
                Polyline(
                    polylineId: const PolylineId('overview_polyline'),
                    color: Colors.blueAccent,
                    width: 5,
                    points: _info!.polylinePoints
                        .map((e) => LatLng(e.latitude, e.longitude))
                        .toList())
            },
            onTap: (LatLng tappedPoint) {
              setState(() {
                tapPointLatitude = tappedPoint.latitude;
                tapPointLongitude = tappedPoint.longitude;
              });
              print('tapPointLatitude = ${tappedPoint.latitude}');
              print('tapPointLongitude = ${tappedPoint.longitude}');

              Timer(const Duration(seconds: 5), () {
                setState(() {
                  tapPointLatitude = null;
                  tapPointLongitude = null;
                });
              });
            },
            onLongPress: addMarker,
          ),
          if (_info != null)
            Positioned(
                top: 15,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                      color: Colors.yellowAccent.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 6.0)
                      ]),
                  child: Text(
                    '${_info!.totalDistance}, ${_info!.totalDuration}',
                    style: const TextStyle(
                        fontSize: 15.0, fontWeight: FontWeight.w600),
                  ),
                )),
          if (tapPointLatitude != null && tapPointLongitude != null)
            Positioned(
              bottom: 35,
              child: AnimatedOpacity(
                opacity: tapPointLatitude != null && tapPointLongitude != null
                    ? 1.0
                    : 0.0,
                duration: const Duration(seconds: 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 6.0, horizontal: 12.0),
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20.0),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            offset: Offset(0, 2),
                            blurRadius: 6.0)
                      ]),
                  child: Column(
                    children: [
                      const Text(
                        'Tapped point Lat-Long',
                        style: TextStyle(
                            fontSize: 10.0, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$tapPointLatitude , $tapPointLongitude',
                        style: const TextStyle(
                            fontSize: 10.0, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          if (_googleMapController != null)
            Positioned(
              left: 5,
              bottom: 85,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green[400],
                ),
                child: IconButton(
                    onPressed: () async {
                      if (currentPosition != null) {
                        // String message = 'Check out my location: ${currentPosition!.latitude}, ${currentPosition!.longitude}';
                        // await Share.share(message);
                        await Share.shareUri(Uri.parse(
                            'https://www.google.com/maps/search/?api=1&query=${currentPosition!.latitude},${currentPosition!.longitude}'));
                      } else {
                        showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                      'Please first get your current location by clicking focus button.'),
                                  actions: [
                                    ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text(
                                          'Okay',
                                          style: TextStyle(color: Colors.green),
                                        ))
                                  ],
                                ));
                      }
                    },
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                      size: 20,
                    )),
              ),
            ),
        ]),
        floatingActionButton: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 15.0, left: 20.0),
            child: FloatingActionButton(
              backgroundColor: Colors.green[400],
              mini: true,
              onPressed: () async {
                checkLocationPermission();
                await getCurrentPosition();
                addCurrentLocationMarker();
                _googleMapController!.animateCamera(_googleMapController != null
                    ? CameraUpdate.newCameraPosition(CameraPosition(
                        target: LatLng(
                          currentPosition!.latitude,
                          currentPosition!.longitude,
                        ),
                        zoom: 18.0,
                      ))
                    : CameraUpdate.newCameraPosition(initialPosition));
              },
              child: const Icon(
                Icons.center_focus_strong,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void addCurrentLocationMarker() {
    if (currentPosition != null && _googleMapController != null) {
      Marker currentLocationMarker = Marker(
        markerId: const MarkerId('currentLocation'),
        infoWindow: const InfoWindow(title: 'Current Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        position: LatLng(
          currentPosition!.latitude,
          currentPosition!.longitude,
        ),
      );
      setState(() {
        _currentLocation = currentLocationMarker;
      });
    }
  }

  Future<void> getCurrentPosition() async {
    await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high)
        .then((Position position) {
      setState(() {
        currentPosition = position;
      });
    }).catchError((e) {
      print(e);
    });
  }

  void addMarker(LatLng pos) async {
    if (_origin == null || (_origin != null && _destination != null)) {
      setState(() {
        _origin = Marker(
            markerId: const MarkerId('origin'),
            infoWindow: const InfoWindow(title: 'Origin'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            position: pos);
        _destination = null;
        _info = null;
      });
    } else {
      setState(() {
        _destination = Marker(
            markerId: const MarkerId('destination'),
            infoWindow: const InfoWindow(title: 'Destination'),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            position: pos);
      });
      final direction = await DirectionRepository()
          .getDirections(origin: _origin!.position, destination: pos);
      setState(() {
        _info = direction;
      });
    }
  }
}
