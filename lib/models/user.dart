
import 'package:flutter/material.dart';

class User {
  final int? id;
  final String username;
  final String password;
  final bool biometricEnabled;

  User({
    this.id,
    required this.username,
    required this.password,
    this.biometricEnabled = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'biometric_enabled': biometricEnabled ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      biometricEnabled: map['biometric_enabled'] == 1,
    );
  }

  User copyWith({
    int? id,
    String? username,
    String? password,
    bool? biometricEnabled,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
    );
  }
}
