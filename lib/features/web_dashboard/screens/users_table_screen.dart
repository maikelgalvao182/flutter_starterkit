import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/shared/models/user_model.dart';
import 'package:partiu/core/utils/app_localizations.dart';

class UsersTableScreen extends StatelessWidget {
  const UsersTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.translate('web_dashboard_users_management_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {}, // StreamBuilder updates automatically, but good for UI
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('Users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${i18n.translate('error')}: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          
          // Convert docs to UserModels
          final users = docs.map((doc) => UserModel.fromFirestore(doc)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${i18n.translate('web_dashboard_total_users_prefix')}: ${users.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text(i18n.translate('photo'))),
                        DataColumn(label: Text(i18n.translate('web_dashboard_column_id'))),
                        DataColumn(label: Text(i18n.translate('web_dashboard_column_name'))),
                        DataColumn(label: Text(i18n.translate('web_dashboard_column_email'))),
                        DataColumn(label: Text(i18n.translate('web_dashboard_column_type'))),
                        DataColumn(label: Text(i18n.translate('web_dashboard_column_city'))),
                        DataColumn(label: Text(i18n.translate('web_dashboard_column_state'))),
                      ],
                      rows: users.map((user) {
                        return DataRow(cells: [
                          DataCell(
                            user.photoUrl != null
                                ? CircleAvatar(
                                    radius: 15,
                                    backgroundImage: NetworkImage(user.photoUrl!),
                                  )
                                : const CircleAvatar(
                                    radius: 15,
                                    child: Icon(Icons.person, size: 15),
                                  ),
                          ),
                          DataCell(Text(user.userId.substring(0, 8))), // Shorten ID
                          DataCell(Text(user.fullName ?? i18n.translate('web_dashboard_no_name'))),
                          DataCell(Text(user.email ?? i18n.translate('web_dashboard_no_email'))),
                          DataCell(Text(user.userType)),
                          DataCell(Text(user.locality ?? '-')),
                          DataCell(Text(user.state ?? '-')),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
