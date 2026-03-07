// ─── User ──────────────────────────────────────────────
class UserModel {
  final String? id;
  final String username;
  final String email;
  final String? phone;
  final String? role;
  final String? gender;
  final String? DOB;

  UserModel({
    this.id,
    required this.username,
    required this.email,
    this.phone,
    this.role,
    this.gender,
    this.DOB,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
    id: j['_id'] ?? j['id'],
    username: j['username'] ?? '',
    email: j['email'] ?? '',
    phone: j['phone'],
    role: j['role'],
    gender: j['gender'],
    DOB: j['DOB'],
  );

  String get fullName => '$username'.trim();
  String get initial => username.isNotEmpty ? username[0].toUpperCase() : '?';
}

// ─── Shift ────────────────────────────────────────────
class ShiftModel {
  final String id;
  final String name;
  final String fromDate;
  final String toDate;
  final String? createdAt;

  ShiftModel({
    required this.id,
    required this.name,
    required this.fromDate,
    required this.toDate,
    this.createdAt,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> j) => ShiftModel(
    id: j['_id'] ?? j['id'] ?? '',
    name: j['name'] ?? '',
    fromDate: j['fromDate'] ?? '',
    toDate: j['toDate'] ?? '',
    createdAt: j['createdAt'],
  );
}

// ─── Person ───────────────────────────────────────────
class PersonModel {
  final String id;
  final String name;
  final int credit;
  final int expenses;
  final String? title;

  PersonModel({
    required this.id,
    required this.name,
    required this.credit,
    required this.expenses,
    this.title,
  });

  factory PersonModel.fromJson(Map<String, dynamic> j) => PersonModel(
    id: j['_id'] ?? j['id'] ?? '',
    name: j['name'] ?? '',
    credit: (j['credit'] ?? 0) is int
        ? j['credit']
        : (j['credit'] as num).toInt(),
    expenses: (j['expenses'] ?? 0) is int
        ? j['expenses']
        : (j['expenses'] as num).toInt(),
    title: j['title'],
  );

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
  String get displayName =>
      title != null && title!.isNotEmpty ? '$name ($title)' : name;
}

// ─── Item ─────────────────────────────────────────────
// ─── Item ─────────────────────────────────────────────
class ItemModel {
  final String id;
  final String name;
  final int quantity;
  final double cost;
  final String? note;
  final String? date;
  final ItemShiftRef? shiftId;
  final ItemPersonRef? personId;
  bool checked;

  ItemModel({
    required this.id,
    required this.name,
    required this.quantity,
    required this.cost,
    this.note,
    this.date,
    this.shiftId,
    this.personId,
    required this.checked,
  });

  factory ItemModel.fromJson(Map<String, dynamic> j) => ItemModel(
    id: j['_id'] ?? j['id'] ?? '',
    name: j['name'] ?? '',
    quantity: (j['quantity'] ?? 0) is int
        ? j['quantity']
        : (j['quantity'] as num).toInt(),
    cost: (j['cost'] ?? 0) is double
        ? j['cost']
        : (j['cost'] as num).toDouble(),
    note: j['note'],
    date: j['date'],
    shiftId: j['shiftId'] is Map
        ? ItemShiftRef.fromJson(j['shiftId'])
        : j['shiftId'] is String
        ? ItemShiftRef(id: j['shiftId'], name: null)
        : null,
    personId: j['personId'] is Map
        ? ItemPersonRef.fromJson(j['personId'])
        : j['personId'] is String
        ? ItemPersonRef(id: j['personId'], name: null)
        : null,
    checked: j['checked'] ?? false,
  );

  double get total => cost * quantity;

  //checked setter
  bool settedChecked(bool value) {
    this.checked = value;
    return this.checked;
  }
}

class ItemShiftRef {
  final String id;
  final String? name;

  ItemShiftRef({required this.id, this.name});

  factory ItemShiftRef.fromJson(Map<String, dynamic> j) =>
      ItemShiftRef(id: j['_id'] ?? '', name: j['name']);
}

class ItemPersonRef {
  final String id;
  final String? name;

  ItemPersonRef({required this.id, this.name});

  factory ItemPersonRef.fromJson(Map<String, dynamic> j) =>
      ItemPersonRef(id: j['_id'] ?? '', name: j['name']);
}

// ─── Transaction ──────────────────────────────────────
class TransactionModel {
  final String id;
  final String? description;
  final double amount;
  final PersonModel? fromPersonId;
  final String? shiftId;
  final String? shiftName;

  TransactionModel({
    required this.id,
    this.description,
    required this.amount,
    this.fromPersonId,
    this.shiftId,
    this.shiftName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> j) => TransactionModel(
    id: j['_id'] ?? j['id'] ?? '',
    description: j['description'],
    amount: (j['amount'] ?? 0) is double
        ? j['amount']
        : (j['amount'] as num).toDouble(),
    fromPersonId: j['fromPersonId'] is Map
        ? PersonModel.fromJson(j['fromPersonId'])
        : null,
    shiftId: j['shiftId'] is String ? j['shiftId'] : j['shiftId']?['_id'],
    shiftName: j['shiftId'] is Map ? j['shiftId']['name'] : null,
  );
}
