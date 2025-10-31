/// Utility service containing helper functions used across the application
class UtilityService {
  /// Generates an image file name from a tool or category name
  /// Converts to lowercase, replaces spaces with underscores, and removes
  /// all non-alphanumeric characters except underscore, then adds .jpg extension
  /// 
  /// Example: "Karcher WD5 Industrial Vacuum" -> "karcher_wd5_industrial_vacuum.jpg"
  static String generateImageFileName(String? name) {
    if (name == null || name.isEmpty) return '';
    // Replace spaces with underscores and remove all non-alphanumeric characters except underscore
    return name.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '') + '.jpg';
  }
}

