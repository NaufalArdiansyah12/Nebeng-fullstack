import 'package:flutter/material.dart';

class Service {
  final int id;
  final String name;
  final IconData icon;
  final String description;

  Service({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      name: json['name'],
      icon: json['icon'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
    };
  }
}
