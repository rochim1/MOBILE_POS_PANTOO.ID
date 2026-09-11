import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

class PosEmployeeAvatar extends StatelessWidget {
  final Map<String, dynamic>? employee;
  final double radius;
  final Color? fallbackColor;

  const PosEmployeeAvatar({
    super.key,
    required this.employee,
    this.radius = 20,
    this.fallbackColor,
  });

  ImageProvider<Object>? _imageProvider(String value) {
    if (value.isEmpty) return null;
    if (value.startsWith('data:image/')) {
      try {
        return MemoryImage(
          base64Decode(value.substring(value.indexOf(',') + 1)),
        );
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(value);
  }

  @override
  Widget build(BuildContext context) {
    final photoUrl = employee?['photo_url']?.toString().trim() ?? '';
    final name = employee?['name']?.toString().trim() ?? '';
    final username = employee?['username']?.toString().trim() ?? '';
    final displayName = name.isNotEmpty ? name : username;
    final initials = displayName.isEmpty
        ? ''
        : displayName
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    final fallback = initials.isNotEmpty
        ? Text(
            initials,
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: radius * 0.72,
            ),
          )
        : Icon(Icons.person_outline, color: AppColors.primary, size: radius);
    final provider = _imageProvider(photoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          fallbackColor ?? AppColors.primary.withValues(alpha: 0.12),
      child: provider == null
          ? fallback
          : ClipOval(
              child: Image(
                image: provider,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => fallback,
              ),
            ),
    );
  }
}
