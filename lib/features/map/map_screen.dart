import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/report_service.dart';
import '../../shared/barangay_data.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  // Center of Mangaldan, Pangasinan
  static const LatLng _mangaldanCenter = LatLng(16.0718, 120.4013);

  @override
  Widget build(BuildContext context) {
    final reportsAsync = ref.watch(reportStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(LucideIcons.mapPin, size: 24),
            SizedBox(width: 8),
            Text('Outage Map', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: _mangaldanCenter,
              initialZoom: 13.5,
              maxZoom: 18.0,
              minZoom: 12.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.kuryente_check',
              ),
              reportsAsync.when(
                data: (snapshot) {
                  final markers = <Marker>[];

                  for (var doc in snapshot.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final barangay = data['barangay'] as String?;
                    final issueType = data['issueType'] as String?;
                    final status = data['status'] as String? ?? 'Pending';
                    final timestamp = data['timestamp'] as Timestamp?;

                    if (barangay != null &&
                        barangayCoordinates.containsKey(barangay)) {
                      final coords = barangayCoordinates[barangay]!;

                      // Add deterministic jitter so markers don't overlap perfectly
                      // distinct reports will stay at the same "random" spot
                      final random = Random(doc.id.hashCode);
                      final double latOffset =
                          (random.nextDouble() - 0.5) * 0.004; // ~400m spread
                      final double lngOffset =
                          (random.nextDouble() - 0.5) * 0.004;

                      // Base color on issue type
                      Color color = Colors.orange;
                      IconData icon = LucideIcons.alertCircle;
                      if (issueType == 'Total Blackout') {
                        color = Colors.red;
                        icon = LucideIcons.zapOff;
                      } else if (issueType == 'Low Voltage') {
                        color = Colors.amber;
                        icon = LucideIcons.activity;
                      } else if (issueType == 'Flickering Lights') {
                        color = Colors.yellow.shade800;
                        icon = LucideIcons.zap;
                      }

                      // If resolved, maybe show green or hide? keeping strictly outage map, maybe grey out resolved
                      if (status == 'Resolved') {
                        color = Colors.green;
                      }

                      markers.add(
                        Marker(
                          point: LatLng(
                            coords.$1 + latOffset,
                            coords.$2 + lngOffset,
                          ),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => _showReportDetails(
                              context,
                              barangay,
                              issueType ?? 'Unknown Issue',
                              data['notes'] ?? '',
                              status,
                              timestamp,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(icon, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      );
                    }
                  }
                  return MarkerLayer(markers: markers);
                },
                loading: () => const MarkerLayer(markers: []),
                error: (e, s) => const MarkerLayer(markers: []),
              ),
            ],
          ),
          // Legend Overlay
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendItem(color: Colors.red, label: 'Blackout'),
                    const SizedBox(width: 12),
                    _LegendItem(color: Colors.amber, label: 'Low Voltage'),
                    const SizedBox(width: 12),
                    _LegendItem(
                      color: Colors.yellow.shade800,
                      label: 'Flickering',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(
    BuildContext context,
    String barangay,
    String issueType,
    String notes,
    String status,
    Timestamp? timestamp,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    issueType,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: status == 'Resolved'
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: status == 'Resolved'
                            ? Colors.green.shade800
                            : Colors.orange.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(LucideIcons.mapPin, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Barangay $barangay',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              if (timestamp != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat.yMMMd().add_jm().format(timestamp.toDate()),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(notes),
              ],
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }
}
