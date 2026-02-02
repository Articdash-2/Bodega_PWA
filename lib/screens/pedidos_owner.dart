import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PedidosOwnerScreen extends StatelessWidget {
  const PedidosOwnerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos Recibidos'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String fechaStr = data['fecha'] != null
                  ? DateFormat(
                      'dd/MM hh:mm a',
                    ).format((data['fecha'] as Timestamp).toDate())
                  : "S/F";

              return Card(
                child: ExpansionTile(
                  title: Text('Pedido: L. ${data['total']}'),
                  subtitle: Text('Fecha: $fechaStr'),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.map, color: Colors.blue),
                      title: const Text("Ver Ubicación GPS"),
                      onTap: () async {
                        // SE CAMBIÓ onPressed POR onTap
                        final Uri url = Uri.parse(data['direccion'] ?? "");
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                    ),
                    TextButton.icon(
                      onPressed: () => doc.reference.delete(),
                      icon: const Icon(Icons.check, color: Colors.green),
                      label: const Text("Entregado"),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
