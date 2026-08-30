import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _generateAccountNumber() {
    final r = Random.secure();
    // 10-digit number, first digit non-zero
    final first = r.nextInt(9) + 1;
    final rest = List.generate(9, (_) => r.nextInt(10)).join();
    return '$first$rest';
  }

  /// Register a new user (Firebase Auth + Firestore profile)
  Future<Map<String, dynamic>?> registerUser({
    required String name,
    required String email,
    required String password,
    String accountType = 'parent',
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user == null) return null;

      final accountNumber = _generateAccountNumber();
      await _db.collection('users').doc(user.uid).set({
        'name': name,
        'email': email,
        'phone': '08000000000',
        'username': email.split('@').first,
        'accountType': accountType,
        'accountNumber': accountNumber,
        'balance': 0,
        'emailVerified': user.emailVerified,
        'mobileVerified': false,
        'kycStatus': 'unverified',
        'banned': false,
        'deleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'totals': {
          'addMoney': 0,
          'cashOut': 0,
          'transactions': 0,
          'sendMoney': 0,
          'payment': 0,
          'mobileRecharge': 0,
          'bankTransfer': 0,
          'microfinance': 0,
          'donation': 0,
          'utilityBill': 0,
          'educationFee': 0,
        },
      }, SetOptions(merge: true));

      try {
        await user.sendEmailVerification();
      } catch (_) {}

      return {'uid': user.uid, 'email': user.email, 'name': name, 'accountNumber': accountNumber};
    } catch (e) {
      // ignore: avoid_print
      print("Error: $e");
      return null;
    }
  }

  /// Sign in existing user (Firebase Auth)
  Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
      final user = cred.user;
      if (user == null) return null;

      final snap = await _db.collection('users').doc(user.uid).get();
      return snap.data() ?? {'uid': user.uid, 'email': user.email};
    } catch (e) {
      // ignore: avoid_print
      print("Login Error: $e");
      return null;
    }
  }
}

