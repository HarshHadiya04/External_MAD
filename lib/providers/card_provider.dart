import 'package:flutter/material.dart';
import 'package:loyalty_card_wallet/models/loyalty_card.dart';
import 'package:loyalty_card_wallet/services/database_service.dart';
import 'package:uuid/uuid.dart';

class CardProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  List<LoyaltyCard> _cards = [];
  bool _isLoading = false;

  List<LoyaltyCard> get cards => _cards;
  bool get isLoading => _isLoading;

  CardProvider() {
    _fetchCards();
  }

  Future<void> _fetchCards() async {
    _isLoading = true;
    notifyListeners();

    try {
      _cards = await _databaseService.getCards();
    } catch (e) {
      print('Error fetching cards: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCard({
    required String name,
    required String issuer,
    required String cardNumber,
    required String barcode,
    required String barcodeType,
    required String cardColor,
    String? logoPath,
    DateTime? expiryDate,
    String? notes,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final card = LoyaltyCard(
        id: const Uuid().v4(),
        name: name,
        issuer: issuer,
        cardNumber: cardNumber,
        barcode: barcode,
        barcodeType: barcodeType,
        cardColor: cardColor,
        logoPath: logoPath,
        expiryDate: expiryDate,
        notes: notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _databaseService.insertCard(card);
      await _fetchCards();
    } catch (e) {
      print('Error adding card: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateCard(LoyaltyCard card) async {
    _isLoading = true;
    notifyListeners();

    try {
      final updatedCard = card.copyWith(
        updatedAt: DateTime.now(),
      );

      await _databaseService.updateCard(updatedCard);
      await _fetchCards();
    } catch (e) {
      print('Error updating card: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteCard(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _databaseService.deleteCard(id);
      await _fetchCards();
    } catch (e) {
      print('Error deleting card: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<LoyaltyCard?> getCardById(String id) async {
    try {
      return await _databaseService.getCard(id);
    } catch (e) {
      print('Error getting card by ID: $e');
      return null;
    }
  }

  void refreshCards() async {
    await _fetchCards();
  }
} 