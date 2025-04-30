import 'dart:convert';

class LoyaltyCard {
  final String id;
  final String name;
  final String issuer;
  final String cardNumber;
  final String barcode;
  final String barcodeType; // QR, CODE128, etc.
  final String cardColor;
  final String? logoPath;
  final DateTime? expiryDate;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoyaltyCard({
    required this.id,
    required this.name,
    required this.issuer,
    required this.cardNumber,
    required this.barcode,
    required this.barcodeType,
    required this.cardColor,
    this.logoPath,
    this.expiryDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  LoyaltyCard copyWith({
    String? id,
    String? name,
    String? issuer,
    String? cardNumber,
    String? barcode,
    String? barcodeType,
    String? cardColor,
    String? logoPath,
    DateTime? expiryDate,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoyaltyCard(
      id: id ?? this.id,
      name: name ?? this.name,
      issuer: issuer ?? this.issuer,
      cardNumber: cardNumber ?? this.cardNumber,
      barcode: barcode ?? this.barcode,
      barcodeType: barcodeType ?? this.barcodeType,
      cardColor: cardColor ?? this.cardColor,
      logoPath: logoPath ?? this.logoPath,
      expiryDate: expiryDate ?? this.expiryDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'issuer': issuer,
      'cardNumber': cardNumber,
      'barcode': barcode,
      'barcodeType': barcodeType,
      'cardColor': cardColor,
      'logoPath': logoPath,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory LoyaltyCard.fromMap(Map<String, dynamic> map) {
    return LoyaltyCard(
      id: map['id'],
      name: map['name'],
      issuer: map['issuer'],
      cardNumber: map['cardNumber'],
      barcode: map['barcode'],
      barcodeType: map['barcodeType'],
      cardColor: map['cardColor'],
      logoPath: map['logoPath'],
      expiryDate: map['expiryDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['expiryDate'])
          : null,
      notes: map['notes'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }

  String toJson() => json.encode(toMap());

  factory LoyaltyCard.fromJson(String source) =>
      LoyaltyCard.fromMap(json.decode(source));

  @override
  String toString() {
    return 'LoyaltyCard(id: $id, name: $name, issuer: $issuer, cardNumber: $cardNumber, barcode: $barcode, barcodeType: $barcodeType, cardColor: $cardColor, logoPath: $logoPath, expiryDate: $expiryDate, notes: $notes, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
} 