import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFormScreen extends StatefulWidget {
  const AdminFormScreen({super.key});

  @override
  State<AdminFormScreen> createState() => _AdminFormScreenState();
}

class _AdminFormScreenState extends State<AdminFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _precioController = TextEditingController();
  final _stockController = TextEditingController();

  Future<void> _guardarProducto() async {
    // Agregamos un print manual para ver si el botón responde
    debugPrint("¡Botón presionado!");

    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('productos').add({
          'nombre': _nombreController.text.trim(),
          'precio': double.tryParse(_precioController.text) ?? 0.0,
          'stock': int.tryParse(_stockController.text) ?? 0,
          'fecha': DateTime.now(),
        });

        if (!mounted) return; // Esto arregla el error de la imagen f4f74e

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡ENVIADO CON ÉXITO!'),
            backgroundColor: Colors.green,
          ),
        );

        _nombreController.clear();
        _precioController.clear();
        _stockController.clear();
      } catch (e) {
        debugPrint("Error al guardar: $e");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel de Bodega')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            // Cambiado a Column para evitar que el ListView absorba el clic
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              TextFormField(
                controller: _precioController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => _guardarProducto(), // Llamada directa
                child: const Text('Guardar en la Nube'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
