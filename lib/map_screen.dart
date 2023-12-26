import 'dart:math';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_app/direction_repository.dart';
import 'package:map_app/models/direction_model.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

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
    // TODO: implement initState
    super.initState();
    // getCurrentPosition();
    checkLocationPermission();
  }
  @override
  void dispose() {
    // TODO: implement dispose
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
            title: const Text('Location Permission Required'),
            content: const Text('Please grant location permission in settings to use this feature.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      getCurrentPosition();
    }
  }

  Future<bool> requestLocationPermission() async {
    final PermissionStatus status = await Permission.locationWhenInUse.request();
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
            style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
          ),
          actions: [
            if (_origin != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent
                ),
                  onPressed: () {
                    _googleMapController!.animateCamera(
                        CameraUpdate.newCameraPosition(CameraPosition(
                            target: _origin!.position,
                            zoom: 16,
                            tilt: 50.0)));
                  },
                  child: const Text(
                    'ORIGIN',
                    style: TextStyle(color: Colors.black),
                  )),
            const SizedBox(width: 5),
            if (_destination != null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
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
                      color: Colors.yellowAccent,
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
                        fontSize: 18.0, fontWeight: FontWeight.w600),
                  ),
                )),
          if (tapPointLatitude != null && tapPointLongitude != null)
            Positioned(
              bottom: 35,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                decoration: BoxDecoration(
                    color: Colors.yellowAccent,
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
                      'Tapped point',
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
          const SizedBox(height: 10),
          if(currentPosition !=null)Positioned(
            right: 10,
            top: 10,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellowAccent,
              ),
              child: IconButton(
                onPressed: () {
                  if (tapPointLatitude != null && tapPointLongitude != null) {
                    // shareLocation(tapPointLatitude!, tapPointLongitude!);
                  }
                },
                icon: const Icon(Icons.share)
              ),
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
                _googleMapController!.animateCamera(
                    _googleMapController != null
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
      // getAddressFromLatLng(currentPosition!);
    }).catchError((e) {
      print(e);
    });
  }

/*  Future<void> getAddressFromLatLng(Position position) async {
    await placemarkFromCoordinates(position.latitude, position.longitude)
        .then((List<Placemark> placemarks) {
      Placemark place = placemarks[0];
      setState(() {
        currentAddress =
            '${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea} ${place.postalCode}, ${place.country}';
      });
      print('currentAddress: $currentAddress');
    }).catchError((e) {
      print(e);
    });
  }*/

/*  void shareLocation(double latitude, double longitude) async {
    String message =
        'Check out this location: https://www.google.com/maps?q=$latitude,$longitude';
    String url = 'https://wa.me/?text=${Uri.encodeFull(message)}';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }*/

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
