import 'package:partiu/plugins/locationpicker/place_picker.dart';
import 'package:flutter/material.dart';

class NearbyPlaceItem extends StatelessWidget {
  const NearbyPlaceItem(
    this.nearbyPlace,
    this.onTap, {
    super.key,
  });

  final NearbyPlace nearbyPlace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: <Widget>[
              // Importante: não baixar imagens do Places aqui (foto/ícone).
              // Mantemos apenas um placeholder local.
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.place, color: Colors.grey[400], size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '${nearbyPlace.name}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
