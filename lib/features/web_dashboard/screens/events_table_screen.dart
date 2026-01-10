import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/home/data/models/event_model.dart';
import 'package:intl/intl.dart';
import 'package:partiu/core/utils/app_localizations.dart';

class EventsTableScreen extends StatelessWidget {
  const EventsTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(i18n.translate('web_dashboard_events_management_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('${i18n.translate('error')}: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          
          final events = docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return EventModel.fromMap(data, doc.id);
          }).toList();

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: [
                  DataColumn(label: Text(i18n.translate('web_dashboard_column_id'))),
                  DataColumn(label: Text(i18n.translate('web_dashboard_column_title'))),
                  DataColumn(label: Text(i18n.translate('web_dashboard_column_created_by'))),
                  DataColumn(label: Text(i18n.translate('web_dashboard_column_date'))),
                  DataColumn(label: Text(i18n.translate('web_dashboard_column_status'))),
                ],
                rows: events.map((event) {
                  return DataRow(cells: [
                    DataCell(Text(event.id.substring(0, 8))),
                    DataCell(Text('${event.emoji} ${event.title}')),
                    DataCell(Text(event.creatorFullName ?? event.createdBy)),
                    DataCell(Text(event.scheduleDate != null 
                      ? DateFormat('dd/MM/yyyy HH:mm').format(event.scheduleDate!) 
                      : i18n.translate('web_dashboard_no_date'))),
                    DataCell(Text(event.isAvailable
                        ? i18n.translate('web_dashboard_status_available')
                        : i18n.translate('web_dashboard_status_unavailable'))),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
