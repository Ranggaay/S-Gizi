import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum DashboardErrorType {
  offline,
  serverUnreachable,
  timeout,
  api,
  parsing,
  unknown,
}

class DashboardErrorInfo {
  const DashboardErrorInfo({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.color,
  });

  final DashboardErrorType type;
  final String title;
  final String message;
  final IconData icon;
  final Color color;
}

DashboardErrorInfo dashboardErrorInfo(Object? error) {
  final raw = error.toString().toLowerCase();

  if (error is TimeoutException || raw.contains('timeout')) {
    return const DashboardErrorInfo(
      type: DashboardErrorType.timeout,
      title: 'Koneksi terlalu lama merespons',
      message: 'Coba lagi beberapa saat lagi atau periksa koneksi Anda.',
      icon: LucideIcons.timerOff,
      color: Color(0xFFF59E0B),
    );
  }

  if (error is FormatException ||
      raw.contains('format response') ||
      raw.contains('format data') ||
      raw.contains('json')) {
    return const DashboardErrorInfo(
      type: DashboardErrorType.parsing,
      title: 'Data dashboard belum sesuai',
      message: 'Aplikasi menerima format data yang belum dapat dibaca.',
      icon: LucideIcons.fileWarning,
      color: Color(0xFFE89B5B),
    );
  }

  if (raw.contains('failed host lookup') ||
      raw.contains('network is unreachable') ||
      raw.contains('no address associated') ||
      raw.contains('xmlhttprequest error') ||
      raw.contains('internet')) {
    return const DashboardErrorInfo(
      type: DashboardErrorType.offline,
      title: 'Tidak dapat terhubung ke internet',
      message: 'Periksa koneksi WiFi atau data seluler Anda.',
      icon: LucideIcons.cloudOff,
      color: Color(0xFF4B8E96),
    );
  }

  if (raw.contains('connection refused') ||
      raw.contains('connection failed') ||
      raw.contains('connection reset') ||
      raw.contains('software caused connection abort')) {
    return const DashboardErrorInfo(
      type: DashboardErrorType.serverUnreachable,
      title: 'Server tidak dapat dijangkau',
      message: 'Pastikan server Laravel sedang berjalan.',
      icon: LucideIcons.serverOff,
      color: Color(0xFFE25555),
    );
  }

  if (raw.contains('status code') ||
      raw.contains('statuscode') ||
      raw.contains('gagal mengambil') ||
      raw.contains('gagal memuat') ||
      raw.contains('api')) {
    return const DashboardErrorInfo(
      type: DashboardErrorType.api,
      title: 'Data dashboard tidak dapat dimuat',
      message: 'Periksa koneksi internet Anda lalu coba lagi.',
      icon: LucideIcons.alertCircle,
      color: Color(0xFFE89B5B),
    );
  }

  return const DashboardErrorInfo(
    type: DashboardErrorType.unknown,
    title: 'Data dashboard tidak dapat dimuat',
    message: 'Coba muat ulang dashboard dalam beberapa saat.',
    icon: LucideIcons.refreshCcw,
    color: Color(0xFF4B8E96),
  );
}
