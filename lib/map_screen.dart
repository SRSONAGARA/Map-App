import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:map_app/direction_repository.dart';
import 'package:map_app/models/direction_model.dart';

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
  Directions? _info;
  double? tapPointLatitude;
  double? tapPointLongitude;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _googleMapController!.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.green[400],
          title: const Text(
            'Map App',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            if (_origin != null)
              TextButton(
                  onPressed: () {
                    _googleMapController!.animateCamera(
                        CameraUpdate.newCameraPosition(CameraPosition(
                            target: _origin!.position,
                            zoom: 14.5,
                            tilt: 50.0)));
                  },
                  child: const Text(
                    'ORIGIN',
                    style: TextStyle(color: Colors.white),
                  )),
            if (_destination != null)
              TextButton(
                  onPressed: () {
                    _googleMapController!.animateCamera(
                        CameraUpdate.newCameraPosition(CameraPosition(
                            target: _destination!.position,
                            zoom: 14.5,
                            tilt: 50.0)));
                  },
                  child: const Text(
                    'DESTINATION',
                    style: TextStyle(color: Colors.white),
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
            },
            onLongPress: addMarker,
          ),
          if (_info != null)
            Positioned(
                top: 20,
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
              bottom: 45,
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
                child: Text(
                  '$tapPointLatitude , $tapPointLongitude',
                  style: const TextStyle(
                      fontSize: 10.0, fontWeight: FontWeight.w600),
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
              onPressed: () {
                _googleMapController!.animateCamera(_info != null
                    ? CameraUpdate.newLatLngBounds(_info!.bounds, 100.0)
                    : CameraUpdate.newCameraPosition(initialPosition));
              },
              tooltip: 'Increment',
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
