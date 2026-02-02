import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bodega_pwa/screens/pedidos_form.dart';

class ListaProductosScreen extends StatefulWidget {
  const ListaProductosScreen({super.key});

  @override
  State<ListaProductosScreen> createState() => _ListaProductosScreenState();
}

class _ListaProductosScreenState extends State<ListaProductosScreen> {
  List<Map<String, dynamic>> carrito = [];
  String rolActivo = "Cliente";
  int _clickCount = 0;
  String filtroNombre = "";
  String categoriaSeleccionada = "Todos";

  final List<String> categorias = [
    "Todos",
    "Bebidas",
    "Granos",
    "Limpieza",
    "Snacks",
    "Otros",
  ];

  final TextEditingController _nombreClienteController =
      TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();

  final String hashAdmin =
      "b74b7e3fcb623d805dacf98db27530f845760c47e3b0faa702b84e9ff3902c37"; /*3030*/
  final String hashStaff =
      "73a2af8864fc500fa49048bf3003776c19938f360e56bd03663866fb3087884a"; /*2020*/

  String _generarHash(String texto) =>
      sha256.convert(utf8.encode(texto)).toString();

  void _dialogoProducto({DocumentSnapshot? doc}) {
    final Map<String, dynamic>? dataOriginal =
        doc?.data() as Map<String, dynamic>?;

    final nom = TextEditingController(
      text: dataOriginal != null ? dataOriginal['nombre'] : "",
    );
    final pre = TextEditingController(
      text: dataOriginal != null ? dataOriginal['precio'].toString() : "",
    );
    final sto = TextEditingController(
      text: dataOriginal != null ? dataOriginal['stock'].toString() : "",
    );
    String cat = dataOriginal != null ? dataOriginal['categoria'] : "Otros";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(doc == null ? "Nuevo Producto" : "Editar Producto"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nom,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: pre,
                decoration: const InputDecoration(labelText: "Precio"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: sto,
                decoration: const InputDecoration(labelText: "Stock"),
                keyboardType: TextInputType.number,
              ),
              StatefulBuilder(
                builder: (context, setDropState) => DropdownButton<String>(
                  value: cat,
                  isExpanded: true,
                  items: categorias
                      .where((c) => c != "Todos")
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setDropState(() => cat = v!),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              final dataMap = {
                'nombre': nom.text,
                'precio': double.tryParse(pre.text) ?? 0.0,
                'stock': int.tryParse(sto.text) ?? 0,
                'categoria': cat,
              };
              if (doc == null) {
                FirebaseFirestore.instance.collection('productos').add(dataMap);
              } else {
                doc.reference.update(dataMap);
              }
              Navigator.pop(ctx);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  Future<void> _enviarPedido() async {
    if (carrito.isEmpty) return;
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (var item in carrito) {
        batch.update(
          FirebaseFirestore.instance.collection('productos').doc(item['id']),
          {'stock': FieldValue.increment(-item['cantidad'])},
        );
      }
      await FirebaseFirestore.instance.collection('pedidos').add({
        'cliente': _nombreClienteController.text,
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text,
        'items': carrito,
        'total': carrito.fold(
          0.0,
          (acc, item) => acc + (item['precio'] * item['cantidad']),
        ),
        'estado': 'Pendiente',
        'fecha': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      if (!mounted) return;
      setState(() {
        carrito.clear();
        _nombreClienteController.clear();
        _telefonoController.clear();
        _direccionController.clear();
      });
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("✅ ¡Pedido enviado!")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  void _mostrarLogin() {
    TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Acceso Administrativo"),
        content: TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(labelText: "Contraseña"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              String inputHash = _generarHash(passController.text);
              if (inputHash == hashAdmin) {
                setState(() => rolActivo = "Admin");
              } else if (inputHash == hashStaff) {
                setState(() => rolActivo = "Trabajador");
              }
              Navigator.pop(ctx);
            },
            child: const Text("Entrar"),
          ),
        ],
      ),
    );
  }

  void _mostrarCarritoCliente() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 15,
            right: 15,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Tu Pedido",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.4,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: carrito.length,
                  itemBuilder: (context, index) {
                    final item = carrito[index];
                    return ListTile(
                      title: Text(item['nombre']),
                      subtitle: Text(
                        "Subtotal: L. ${item['precio'] * item['cantidad']}",
                      ),
                      trailing: SizedBox(
                        width: 60,
                        child: TextField(
                          decoration: const InputDecoration(labelText: "Cant."),
                          keyboardType: TextInputType.number,
                          onChanged: (v) {
                            int nuevaCant = int.tryParse(v) ?? 1;
                            setState(() => item['cantidad'] = nuevaCant);
                            setModalState(() {});
                          },
                          controller:
                              TextEditingController(
                                  text: item['cantidad'].toString(),
                                )
                                ..selection = TextSelection.collapsed(
                                  offset: item['cantidad'].toString().length,
                                ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              Text(
                "TOTAL: L. ${carrito.fold(0.0, (a, b) => a + (b['precio'] * b['cantidad']))}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              TextField(
                controller: _nombreClienteController,
                decoration: const InputDecoration(labelText: "Tu Nombre"),
              ),
              TextField(
                controller: _telefonoController,
                decoration: const InputDecoration(labelText: "Teléfono"),
              ),
              TextField(
                controller: _direccionController,
                decoration: const InputDecoration(labelText: "Dirección"),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _enviarPedido,
                  child: const Text("Confirmar y Enviar Pedido"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[900],
        title: GestureDetector(
          onTap: () {
            setState(() {
              _clickCount++;
              if (_clickCount >= 3) {
                _clickCount = 0;
                _mostrarLogin();
              }
            });
          },
          child: Text(
            "Bodega: $rolActivo",
            style: const TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          if (rolActivo == "Admin")
            IconButton(
              icon: const Icon(Icons.add_box, color: Colors.white),
              onPressed: () => _dialogoProducto(),
            ),
          if (carrito.isNotEmpty && rolActivo == "Cliente")
            IconButton(
              icon: const Icon(Icons.shopping_cart, color: Colors.white),
              onPressed: _mostrarCarritoCliente,
            ),
          if (rolActivo != "Cliente")
            IconButton(
              icon: const Icon(Icons.receipt_long, color: Colors.white),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (ctx) => PedidosForm(rol: rolActivo),
                ),
              ),
            ),
          if (rolActivo != "Cliente")
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => setState(() => rolActivo = "Cliente"),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Buscar producto...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => filtroNombre = v.toLowerCase()),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: categorias
                  .map(
                    (cat) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: categoriaSeleccionada == cat,
                        onSelected: (s) =>
                            setState(() => categoriaSeleccionada = cat),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('productos')
                  .snapshots(),
              builder: (ctx, AsyncSnapshot<QuerySnapshot> snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                var docs = snap.data!.docs.where((d) {
                  var p = d.data() as Map<String, dynamic>;
                  return p['nombre'].toString().toLowerCase().contains(
                        filtroNombre,
                      ) &&
                      (categoriaSeleccionada == "Todos" ||
                          p['categoria'] == categoriaSeleccionada);
                }).toList();

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    var p = docs[i].data() as Map<String, dynamic>;
                    int stock = p['stock'] ?? 0;
                    return ListTile(
                      title: Text(p['nombre']),
                      subtitle: Text(
                        "L. ${p['precio']} | Stock: $stock",
                        style: TextStyle(
                          color: stock <= 0 ? Colors.red : Colors.black54,
                        ),
                      ),
                      trailing: rolActivo == "Admin"
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () =>
                                      _dialogoProducto(doc: docs[i]),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () => docs[i].reference.delete(),
                                ),
                              ],
                            )
                          : IconButton(
                              icon: const Icon(Icons.add_shopping_cart),
                              color: stock <= 0 ? Colors.grey : Colors.green,
                              onPressed: stock <= 0
                                  ? null
                                  : () {
                                      setState(() {
                                        int idx = carrito.indexWhere(
                                          (e) => e['id'] == docs[i].id,
                                        );
                                        if (idx != -1) {
                                          carrito[idx]['cantidad']++;
                                        } else {
                                          carrito.add({
                                            'id': docs[i].id,
                                            'nombre': p['nombre'],
                                            'precio': p['precio'],
                                            'cantidad': 1,
                                            'unidad': 'Unidad',
                                          });
                                        }
                                      });
                                    },
                            ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            height: 38,
            decoration: BoxDecoration(
              color: Colors.orange[900],
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 6,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: const MarqueeWidget(
              text: "🚀 Desarrollado por: articdash-2 ✨ ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MarqueeWidget extends StatefulWidget {
  final String text;
  final TextStyle style;
  const MarqueeWidget({super.key, required this.text, required this.style});

  @override
  State<MarqueeWidget> createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScrolling());
  }

  void _startScrolling() async {
    while (_scrollController.hasClients) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (_scrollController.hasClients) {
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(seconds: 60),
          curve: Curves.linear,
        );
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 30,
      itemBuilder: (ctx, i) => Center(
        child: Padding(
          padding: const EdgeInsets.only(right: 30),
          child: Text(widget.text, style: widget.style),
        ),
      ),
    );
  }
}
