class QCItem {
  final int id;
  final String itemCode;
  final String description;
  final String? uom;
  final String category;
  final String? hsnCode;

  QCItem({
    required this.id,
    required this.itemCode,
    required this.description,
    this.uom,
    required this.category,
    this.hsnCode,
  });

  factory QCItem.fromJson(Map<String, dynamic> json) {
    return QCItem(
      id: json['id'],
      itemCode: json['itemCode'],
      description: json['description'],
      uom: json['uom'],
      category: json['category'],
      hsnCode: json['hsnCode'],
    );
  }
}
