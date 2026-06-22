class AopSummaryModel {
  final List<String> categories;
  final List<String> months;
  final Map<String, List<int>> targets;
  final Map<String, List<int>> actuals;
  final List<bool> isMTD;

  AopSummaryModel({
    required this.categories,
    required this.months,
    required this.targets,
    required this.actuals,
    required this.isMTD,
  });

  factory AopSummaryModel.fromJson(Map<String, dynamic> json) {
    return AopSummaryModel(
      categories: List<String>.from(json['categories']),
      months: List<String>.from(json['months']),
      targets: (json['targets'] as Map<String, dynamic>).map((k, v) => MapEntry(k, List<int>.from(v))),
      actuals: (json['actuals'] as Map<String, dynamic>).map((k, v) => MapEntry(k, List<int>.from(v))),
      isMTD: List<bool>.from(json['isMTD']),
    );
  }
}

class AopMonthlyRow {
  final String category;
  final int target;
  final int actual;
  final int shortfall;
  final int achievementPct;
  final String status;

  AopMonthlyRow({
    required this.category,
    required this.target,
    required this.actual,
    required this.shortfall,
    required this.achievementPct,
    required this.status,
  });

  factory AopMonthlyRow.fromJson(Map<String, dynamic> json) {
    return AopMonthlyRow(
      category: json['category'],
      target: json['target'],
      actual: json['actual'],
      shortfall: json['shortfall'],
      achievementPct: json['achievementPct'],
      status: json['status'],
    );
  }
}

class AopMonthlyModel {
  final String month;
  final int monthIndex;
  final bool isMTD;
  final List<AopMonthlyRow> rows;
  final AopMonthlyRow totals;

  AopMonthlyModel({
    required this.month,
    required this.monthIndex,
    required this.isMTD,
    required this.rows,
    required this.totals,
  });

  factory AopMonthlyModel.fromJson(Map<String, dynamic> json) {
    return AopMonthlyModel(
      month: json['month'],
      monthIndex: json['monthIndex'],
      isMTD: json['isMTD'],
      rows: (json['rows'] as List).map((r) => AopMonthlyRow.fromJson(r)).toList(),
      totals: AopMonthlyRow.fromJson(json['totals']),
    );
  }
}

class AopSpec {
  final String specCode;
  final String specFull;
  final int totalQty;
  final int sharePct;
  final String firstDate;
  final String lastDate;
  final int dispatchCount;

  AopSpec({
    required this.specCode,
    required this.specFull,
    required this.totalQty,
    required this.sharePct,
    required this.firstDate,
    required this.lastDate,
    required this.dispatchCount,
  });

  factory AopSpec.fromJson(Map<String, dynamic> json) {
    return AopSpec(
      specCode: json['specCode'],
      specFull: json['specFull'],
      totalQty: json['totalQty'],
      sharePct: json['sharePct'],
      firstDate: json['firstDate'],
      lastDate: json['lastDate'],
      dispatchCount: json['dispatchCount'],
    );
  }
}

class AopDrilldownModel {
  final String category;
  final String month;
  final int target;
  final int actual;
  final List<AopSpec> specs;

  AopDrilldownModel({
    required this.category,
    required this.month,
    required this.target,
    required this.actual,
    required this.specs,
  });

  factory AopDrilldownModel.fromJson(Map<String, dynamic> json) {
    return AopDrilldownModel(
      category: json['category'],
      month: json['month'],
      target: json['target'],
      actual: json['actual'],
      specs: (json['specs'] as List).map((s) => AopSpec.fromJson(s)).toList(),
    );
  }
}

class AopTransaction {
  final int id;
  final String dispatchDate;
  final String category;
  final String specification;
  final int quantity;
  final String uom;

  AopTransaction({
    required this.id,
    required this.dispatchDate,
    required this.category,
    required this.specification,
    required this.quantity,
    required this.uom,
  });

  factory AopTransaction.fromJson(Map<String, dynamic> json) {
    return AopTransaction(
      id: json['id'],
      dispatchDate: json['dispatchDate'],
      category: json['category'],
      specification: json['specification'],
      quantity: json['quantity'],
      uom: json['uom'],
    );
  }
}
