import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          // Placeholder Map Background
          Container(
            color: Colors.blue.shade50.withValues(alpha: 0.3),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.mapPin, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Interactive Map',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Map will display reported issues across all\nbarangays in Mangaldan',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
              ),
            ),
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
                    _LegendItem(color: Colors.red, label: 'Poblacion'),
                    const SizedBox(width: 12),
                    _LegendItem(color: Colors.orange, label: 'Macayug'),
                    const SizedBox(width: 12),
                    _LegendItem(color: Colors.amber, label: 'Bantayan'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
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
