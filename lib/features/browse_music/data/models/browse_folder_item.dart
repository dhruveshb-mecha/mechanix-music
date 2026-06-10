import 'package:flutter/material.dart';

/// Represents a single entry in the browse-music folder list.
///
/// Used for both the quick-access shortcuts (Home, Recents, Downloads,
/// Documents) and for mounted drive partitions.
class BrowseFolderItem {
  const BrowseFolderItem({
    required this.icon,
    required this.title,
    required this.path,
  });

  final IconData icon;
  final String title;
  final String path;
}
