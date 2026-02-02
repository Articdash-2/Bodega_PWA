class Producto {
  final String id;
  final String nombre;
  final double precio;
  final int stock;
  final String imagenUrl;
  final String categoria;

  Producto({
    required this.id,
    required this.nombre,
    required this.precio,
    required this.stock,
    required this.imagenUrl,
    required this.categoria,
  });

  // Este método será útil cuando conectemos Firebase
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'precio': precio,
      'stock': stock,
      'imagenUrl': imagenUrl,
      'categoria': categoria,
    };
  }
}
