import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:muserpol_pvt/components/containers.dart';
import 'package:muserpol_pvt/components/table_row.dart';
import 'package:muserpol_pvt/model/contacts_model.dart';
import 'package:url_launcher/url_launcher.dart' as urlauncher;

class CardContact extends StatefulWidget {
  final City city;
  const CardContact({super.key, required this.city});

  @override
  State<CardContact> createState() => _CardContactState();
}

class _CardContactState extends State<CardContact> {
  ValueNotifier<bool> isDialOpen = ValueNotifier(false);
  SupportedMap? itemSelect;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: ContainerComponent(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.city.name!),
            const SizedBox(height: 20),
            Table(
                columnWidths: const {
                  0: FlexColumnWidth(3.5),
                  1: FlexColumnWidth(0.5),
                  2: FlexColumnWidth(6),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  tableInfo(
                      'Dirección:',
                      GestureDetector(
                        onTap: () => openMapsSheet(context, widget.city.latitude!, widget.city.longitude!, widget.city.companyAddress!),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on),
                            Flexible(
                                child: Text(
                              widget.city.companyAddress!,
                              style: const TextStyle(color: Color(0xff439CAB)),
                            ))
                          ],
                        ),
                      )),
                  if (json.decode(widget.city.companyPhones!).length > 0)
                    tableInfo(
                        'Teléfonos:',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var item in json.decode(widget.city.companyPhones!))
                              GestureDetector(
                                onTap: () => urlauncher.launchUrl(Uri(scheme: 'tel', path: '$item')),
                                child: Text('$item', style: const TextStyle(color: Color(0xff439CAB))),
                              )
                          ],
                        )),
                  if (json.decode(widget.city.companyCellphones!).length > 0)
                    tableInfo(
                        'Celulares:',
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var item in json.decode(widget.city.companyCellphones!))
                              GestureDetector(
                                onTap: () => urlauncher.launchUrl(Uri(scheme: 'tel', path: '$item')),
                                child: Text('$item', style: const TextStyle(color: Color(0xff439CAB))),
                              )
                          ],
                        )),
                ])
          ],
        ),
      ),
    );
  }

    Future<void> openMapsSheet(BuildContext context, double lat, double lng, String title) async {
    debugPrint('🗺️ Coordenadas recibidas - Lat: $lat, Lng: $lng, Título: $title');

    try {
      final candidates = <MapApp>[
        MapApp.google,
        MapApp.apple,
        MapApp.waze,
        MapApp.here,
        MapApp.yandexMaps,
        MapApp.osmand, // <- si el usuario tiene OsmAnd, aparecerá aquí solo
      ];

      final request = MapLauncher.marker(
        LocationCoords(lat, lng, title: title.isEmpty ? 'Ubicación' : title),
      );
      final supportedMaps = await request.getSupportedMaps(candidates);
      final availableMaps =
          supportedMaps.where((map) => map.isInstalled).toList();

      const osmUrl =
          'https://www.openstreetmap.org/?mlat=%LAT%&mlon=%LON%#map=16/%LAT%/%LON%';

      if (!context.mounted) return;
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (availableMaps.isEmpty)
                    const ListTile(
                      leading: Icon(Icons.map, size: 30.0),
                      title: Text('No se detectaron aplicaciones de mapas'),
                    ),
                  for (final map in availableMaps)
                    ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        map.show();
                      },
                      title: Text('Abrir: ${map.name}'),
                      leading: SizedBox(
                        height: 30.0,
                        width: 30.0,
                        child: Image.memory(map.iconBytes),
                      ),
                    ),
                  // OpenStreetMap web: siempre disponible, sin ambigüedad de chooser
                  ListTile(
                    leading: const Icon(Icons.public, size: 30.0, color: Color(0xff439CAB)),
                    title: const Text('Abrir: OpenStreetMap (web)'),
                    subtitle: const Text('Se abre en el navegador'),
                    onTap: () async {
                      Navigator.pop(context);
                      final url = osmUrl
                          .replaceAll('%LAT%', lat.toString())
                          .replaceAll('%LON%', lng.toString());
                      await urlauncher.launchUrl(
                        Uri.parse(url),
                        mode: urlauncher.LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('❌ Error al abrir mapas: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}