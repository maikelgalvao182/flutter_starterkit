import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:partiu/core/services/auth_sync_service.dart';

/// Widget de debug para monitorar o estado de autenticação
/// Útil para diagnosticar problemas de perda de sessão
class AuthDebugWidget extends StatelessWidget {
  const AuthDebugWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthSyncService>(
      builder: (context, authSync, child) {
        return Container(
          padding: const EdgeInsets.all(6),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'DEBUG',
                style: TextStyle(
                  color: Colors.yellow,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
              SizedBox(height: 2),
              _buildCompactRow('Init', authSync.initialized ? '✓' : '✗', 
                authSync.initialized ? Colors.green : Colors.red),
              _buildCompactRow('Auth', authSync.isLoggedIn ? '✓' : '✗', 
                authSync.isLoggedIn ? Colors.green : Colors.red),
              _buildCompactRow('User', authSync.appUser?.userId != null ? '✓' : '✗', 
                authSync.appUser != null ? Colors.green : Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(color: Colors.white70, fontSize: 8),
          ),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}