import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class ResumenPedidoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> productos;
  const ResumenPedidoScreen({super.key, required this.productos});

  @override
  State<ResumenPedidoScreen> createState() => _ResumenPedidoScreenState();
}

class _ResumenPedidoScreenState extends State<ResumenPedidoScreen> {
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();

  @override
  void dispose() {
    nombreController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  // FUNCIÓN GPS: Genera link directo para Google Maps
  Future<void> _obtenerUbicacion() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      direccionController.text =
          "https://www.google.com/maps?q=${position.latitude},${position.longitude}";
    });
  }

  void _enviarPedido() async {
    if (nombreController.text.isEmpty || direccionController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Faltan datos')));
      return;
    }

    double total = widget.productos.fold(
      0.0,
      (acumulado, item) => acumulado + (item['precio'] as num).toDouble(),
    );

    // PROCESO BATCH: Descuenta stock y crea pedido al mismo tiempo
    WriteBatch batch = FirebaseFirestore.instance.batch();

    try {
      for (var item in widget.productos) {
        var query = await FirebaseFirestore.instance
            .collection('productos')
            .where('nombre', isEqualTo: item['nombre'])
            .get();

        if (query.docs.isNotEmpty) {
          batch.update(query.docs.first.reference, {
            'stock': FieldValue.increment(-1),
          });
        }
      }

      DocumentReference pedidoRef = FirebaseFirestore.instance
          .collection('pedidos')
          .doc();
      batch.set(pedidoRef, {
        'cliente': nombreController.text,
        'direccion': direccionController.text,
        'productos': widget.productos,
        'total': total,
        'fecha': DateTime.now(),
      });

      await batch.commit();
      if (!mounted) return;
      Navigator.pop(context, true); // Regresa true para limpiar el carrito
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmar Pedido'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.productos.length,
              itemBuilder: (context, i) => ListTile(
                title: Text(widget.productos[i]['nombre']),
                trailing: Text("L. ${widget.productos[i]['precio']}"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  TextField(
                    controller: nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección o Link GPS',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.location_on, color: Colors.blue),
                        onPressed: _obtenerUbicacion,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _enviarPedido,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 60),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'ENVIAR Y DESCONTAR STOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
