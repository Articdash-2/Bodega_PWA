import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PedidosForm extends StatelessWidget {
  final String rol;
  const PedidosForm({super.key, required this.rol});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hoja de Pedidos"),
        backgroundColor: Colors.orange[900],
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('pedidos')
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (ctx, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No hay pedidos registrados"));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (ctx, i) {
              var doc = snapshot.data!.docs[i];
              var ped = doc.data() as Map<String, dynamic>;
              String estado = ped['estado'] ?? 'Pendiente';
              Color colorEst = estado == 'Finalizado'
                  ? Colors.green
                  : (estado == 'En Camino' ? Colors.blue : Colors.orange);

              return Card(
                elevation: 3,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: colorEst,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(
                    ped['cliente'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Total: L. ${ped['total']} - $estado"),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("📞 Teléfono: ${ped['telefono']}"),
                          Text("🏠 Dirección: ${ped['direccion']}"),
                          const Divider(),
                          const Text(
                            "DETALLE:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...(ped['items'] as List).map(
                            (it) => Text(
                              "• ${it['cantidad']} ${it['unidad']} - ${it['nombre']} (L. ${it['precio'] * it['cantidad']})",
                            ),
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              if (estado == 'Pendiente')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                  ),
                                  onPressed: () => doc.reference.update({
                                    'estado': 'En Camino',
                                  }),
                                  child: const Text(
                                    "DESPACHAR",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              if (estado == 'En Camino')
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () => doc.reference.update({
                                    'estado': 'Finalizado',
                                  }),
                                  child: const Text(
                                    "ENTREGADO",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              if (rol == "Dueno")
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_forever,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => _borrar(ctx, doc.id),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _borrar(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar pedido?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('pedidos').doc(id).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
