import 'qc_item.dart';

class QCReportEntry {
  final int id;
  final int qcItemId;
  final QCItem? qcItem;
  final int quantity;
  final String? process;
  final String? size;
  final String? sjoNumber;
  final String? checkedByName;
  final String? uom;

  QCReportEntry({
    required this.id,
    required this.qcItemId,
    this.qcItem,
    required this.quantity,
    this.process,
    this.size,
    this.sjoNumber,
    this.checkedByName,
    this.uom,
  });

  factory QCReportEntry.fromJson(Map<String, dynamic> json) {
    return QCReportEntry(
      id: json['id'],
      qcItemId: json['qcItemId'],
      qcItem: json['qcItem'] != null ? QCItem.fromJson(json['qcItem']) : null,
      quantity: json['quantity'],
      process: json['process'],
      size: json['size'],
      sjoNumber: json['sjoNumber'],
      checkedByName: json['checkedByName'],
      uom: json['uom'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemCode': qcItem?.itemCode,
      'quantity': quantity,
      'process': process,
      'size': size,
      'sjoNumber': sjoNumber,
      'checkedByName': checkedByName,
      'uom': uom,
    };
  }
}

class QCDailyLog {
  final int id;
  final int userId;
  final DateTime date;
  final List<QCReportEntry> entries;

  QCDailyLog({
    required this.id,
    required this.userId,
    required this.date,
    required this.entries,
  });

  factory QCDailyLog.fromJson(Map<String, dynamic> json) {
    var list = json['entries'] as List? ?? [];
    List<QCReportEntry> entriesList = list.map((i) => QCReportEntry.fromJson(i)).toList();
    
    return QCDailyLog(
      id: json['id'],
      userId: json['userId'],
      date: DateTime.parse(json['date']),
      entries: entriesList,
    );
  }
}
