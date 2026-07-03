import 'package:flutter/material.dart';

enum VaultDocumentCategory {
  passport('Passport', Icons.flight_outlined),
  drivingLicence('Driving Licence', Icons.badge_outlined),
  insurance('Insurance', Icons.shield_outlined),
  medical('Medical', Icons.medical_services_outlined),
  vehicle('Vehicle', Icons.directions_car_outlined),
  property('Property', Icons.home_work_outlined),
  identity('Identity', Icons.perm_identity_outlined),
  education('Education', Icons.school_outlined),
  financial('Financial', Icons.account_balance_outlined),
  warranty('Warranty', Icons.verified_user_outlined),
  other('Other', Icons.folder_outlined);

  const VaultDocumentCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  String displayLabel(String? custom) {
    if (this == VaultDocumentCategory.other &&
        custom != null &&
        custom.trim().isNotEmpty) {
      return custom.trim();
    }
    return label;
  }
}

enum VaultFileType {
  image('Images'),
  pdf('PDF'),
  document('Documents');

  const VaultFileType(this.label);
  final String label;

  static VaultFileType fromPath(String path, {bool isImage = false}) {
    if (isImage) return VaultFileType.image;
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return VaultFileType.pdf;
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return VaultFileType.image;
    }
    return VaultFileType.document;
  }
}

enum VaultStorageBackend {
  local('Stored Locally'),
  googleDrive('Backed up to Google Drive');

  const VaultStorageBackend(this.label);
  final String label;
}

enum VaultFilterKind {
  all('All'),
  images('Images'),
  pdf('PDF'),
  documents('Documents'),
  linked('Linked'),
  unlinked('Unlinked');

  const VaultFilterKind(this.label);
  final String label;
}

enum VaultSortOption {
  newest('Newest'),
  oldest('Oldest'),
  alphabetical('Alphabetical'),
  category('Category'),
  size('Size'),
  recentlyViewed('Recently Viewed');

  const VaultSortOption(this.label);
  final String label;
}
