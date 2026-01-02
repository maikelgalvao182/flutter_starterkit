import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/home/data/models/event_model.dart';
import 'package:intl/intl.dart';

class EventsTableScreen extends StatelessWidget {
  const EventsTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Eventos'),
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
            return Center(child: Text('Erro: ${snapshot.error}'));
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
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Título')),
                  DataColumn(label: Text('Criado Por')),
                  DataColumn(label: Text('Data')),
                  DataColumn(label: Text('Status')),
                ],
                rows: events.map((event) {
                  return DataRow(cells: [
                    DataCell(Text(event.id.substring(0, 8))),
                    DataCell(Text('${event.emoji} ${event.title}')),
                    DataCell(Text(event.creatorFullName ?? event.createdBy)),
                    DataCell(Text(event.scheduleDate != null 
                      ? DateFormat('dd/MM/yyyy HH:mm').format(event.scheduleDate!) 
                      : 'Sem data')),
                    DataCell(Text(event.isAvailable ? 'Disponível' : 'Indisponível')),
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
