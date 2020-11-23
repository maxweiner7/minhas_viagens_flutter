import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class Mapa extends StatefulWidget {

  String idViagem;
  Mapa( {this.idViagem} );


  @override
  _MapaState createState() => _MapaState();
}

class _MapaState extends State<Mapa> {



  FirebaseFirestore _db = FirebaseFirestore.instance;
  Set<Marker> _marcadores = {};
  Completer<GoogleMapController> _controller = Completer();


  CameraPosition _posicaoCamera =
      CameraPosition(target: LatLng(-18.917743, -48.277387), zoom: 16);

  _onMapCreated(GoogleMapController googleMapController) {
    _controller.complete(googleMapController);
  }

  getMyLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _posicaoCamera = CameraPosition(
          target: LatLng(position.latitude, position.longitude), zoom: 17);
    });
  }

  _adicionarMarcador(LatLng latLng) async {

    List<Placemark> listaEnderecos = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);

    if(listaEnderecos != null && listaEnderecos.length > 0) {

      Placemark endereco = listaEnderecos[0];
      String rua = endereco.thoroughfare;

      Marker _marcadorUsuario = Marker(
          markerId: MarkerId("marcador-${latLng.latitude}-${latLng.longitude}"),
          position: latLng,
          infoWindow: InfoWindow(title: rua));
      setState(() {
        _marcadores.add(_marcadorUsuario);

        //salvar no firebase

       Map<String, dynamic> viagem = Map();
        viagem["titulo"] = rua;
        viagem["latitude"] = latLng.latitude;
        viagem["longetude"] = latLng.longitude;

        _db.collection("viagens")
        .add( viagem );
      });
    }


  }

  _adicionarListenerLocalizacao() {
    var geolocator = Geolocator.getPositionStream(
            desiredAccuracy: LocationAccuracy.high, distanceFilter: 10)
        .listen((Position position) {
      Marker _marcadorUsuario = Marker(
          markerId: MarkerId("marcadorUsuario"),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(title: "Meu local"),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          onTap: () {
            print("Meu Local atual");
          });

      setState(() {
        _marcadores.add(_marcadorUsuario);
        _posicaoCamera = CameraPosition(target: LatLng(position.latitude, position.longitude),
        zoom: 18);
        _movimentarCamera();
      });
    });
  }

  _movimentarCamera() async {

    GoogleMapController googleMapController = await _controller.future;
    googleMapController.animateCamera(
      CameraUpdate.newCameraPosition(_posicaoCamera)
    );

  }
  _recuperaViagemPeloID (String idViagem) async {

    if(idViagem != null) {

      //exibir marcador para id viagem
      DocumentSnapshot documentSnapshot = await _db
          .collection("viagens")
          .doc( idViagem )
          .get();

      var dados = documentSnapshot.data();
      String titulo = dados["title"];
      LatLng latLng = LatLng(
          dados["latitude"],
          dados["longetude"]
      );
      setState(() {
        Marker marcador = Marker(
            markerId: MarkerId("marcador-${latLng.latitude}-${latLng.longitude}"),
            position: latLng,
            infoWindow: InfoWindow(title: titulo));

        _marcadores.add( marcador );
        _posicaoCamera = CameraPosition(target: latLng,
        zoom: 18
        );
        _movimentarCamera();

      });


    }else{
      _adicionarListenerLocalizacao();

    }

  }


  @override
  void initState() {
    super.initState();
    _recuperaViagemPeloID ( widget.idViagem );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Maps"),
        ),
        body: Container(
          child: GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: _posicaoCamera,
            myLocationEnabled: true,
            onMapCreated: _onMapCreated,
            onLongPress: _adicionarMarcador,
            markers: _marcadores,
          ),
        ));
  }
}
