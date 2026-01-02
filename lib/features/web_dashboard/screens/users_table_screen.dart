import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/shared/models/user_model.dart';

class UsersTableScreen extends StatelessWidget {
  const UsersTableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciamento de Usuários'),
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
            return Center(child: Text('Erro: ${snapshot.error}'));
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
                  'Total de usuários: ${users.length}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Foto')),
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Tipo')),
                        DataColumn(label: Text('Cidade')),
                        DataColumn(label: Text('Estado')),
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
                          DataCell(Text(user.fullName ?? 'Sem nome')),
                          DataCell(Text(user.email ?? 'Sem email')),
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
