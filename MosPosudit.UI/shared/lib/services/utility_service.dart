class UtilityService {
  static String generateImageFileName(String? name) {
    if (name == null || name.isEmpty) return '';
    return name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '') + '.jpg';
  }
}

