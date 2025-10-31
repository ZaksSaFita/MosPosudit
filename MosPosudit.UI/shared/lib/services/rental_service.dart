import 'dart:convert';
import '../api/api_client.dart';
import '../models/rental.dart';
import 'auth_service.dart';

class RentalService {
  final ApiClient _api;
  RentalService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  Future<List<RentalModel>> getRentals({Map<String, dynamic>? query}) async {
    try {
      final res = await _api.get('/Rental', query: query);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> data = decoded is List 
            ? decoded 
            : (decoded['value'] ?? []);
        return data.map((e) => RentalModel.fromJson(e)).toList();
      }
      
      throw Exception('Failed to fetch rentals: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in getRentals: $e');
      rethrow;
    }
  }

  Future<RentalModel?> getById(int id) async {
    try {
      final res = await _api.get('/Rental/$id');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return RentalModel.fromJson(decoded);
      }
      
      return null;
    } catch (e) {
      print('Error in getById: $e');
      return null;
    }
  }

  Future<RentalModel> createRental({
    required DateTime startDate,
    required DateTime endDate,
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final body = {
        'userId': userId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'items': items,
        if (notes != null) 'notes': notes,
      };

      final res = await _api.post('/Rental', body: body);
      
      if (res.statusCode == 201 || res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return RentalModel.fromJson(decoded);
      }
      
      throw Exception('Failed to create rental: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in createRental: $e');
      rethrow;
    }
  }

  Future<List<RentalModel>> getMyRentals() async {
    try {
      final userId = await AuthService.getUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final res = await _api.get('/Rental/user/$userId');
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> data = decoded is List 
            ? decoded 
            : (decoded['value'] ?? []);
        return data.map((e) => RentalModel.fromJson(e)).toList();
      }
      
      throw Exception('Failed to fetch my rentals: ${res.statusCode} - ${res.body}');
    } catch (e) {
      print('Error in getMyRentals: $e');
      rethrow;
    }
  }

  Future<bool> checkAvailability({
    required int toolId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final query = {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      };
      
      final res = await _api.get('/Rental/availability/$toolId', query: query);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        return decoded['isAvailable'] ?? false;
      }
      
      return false;
    } catch (e) {
      print('Error in checkAvailability: $e');
      return false;
    }
  }

  Future<List<DateTime>> getBookedDates({
    required int toolId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final query = <String, String>{};
      if (startDate != null) {
        query['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        query['endDate'] = endDate.toIso8601String();
      }
      
      final res = await _api.get('/Rental/booked-dates/$toolId', query: query);
      
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List<dynamic> dates = decoded is List ? decoded : (decoded['value'] ?? []);
        return dates.map((d) => DateTime.parse(d)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error in getBookedDates: $e');
      return [];
    }
  }

  Future<List<DateTime>> getAllBookedDatesForTools({
    required List<int> toolIds,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get booked dates for all tools and combine them
      final allBookedDates = <DateTime>[];
      
      for (final toolId in toolIds) {
        final dates = await getBookedDates(
          toolId: toolId,
          startDate: startDate,
          endDate: endDate,
        );
        allBookedDates.addAll(dates);
      }
      
      return allBookedDates.toSet().toList()..sort();
    } catch (e) {
      print('Error in getAllBookedDatesForTools: $e');
      return [];
    }
  }
}

