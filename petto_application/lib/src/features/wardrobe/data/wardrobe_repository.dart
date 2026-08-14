import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';

class WardrobeItemData {
  const WardrobeItemData({required this.accessoryId, required this.isEquipped});

  final String accessoryId;
  final bool isEquipped;

  factory WardrobeItemData.fromJson(Map<String, dynamic> json) =>
      WardrobeItemData(
        accessoryId: json['accessory_id'] as String,
        isEquipped: json['equipped_at'] != null,
      );
}

abstract class WardrobeRepository {
  Future<List<WardrobeItemData>> listItems(int petId);
  Future<void> equip(int petId, String accessoryId);
  Future<void> unequip(int petId);
}

class WardrobeRepositoryImpl implements WardrobeRepository {
  WardrobeRepositoryImpl({Dio? dio}) : _dio = dio ?? ApiClient.dio;

  final Dio _dio;

  @override
  Future<List<WardrobeItemData>> listItems(int petId) async {
    final response = await _dio.get(
      '${AppConfig.apiPrefix}/pets/$petId/wardrobe-items',
    );
    return (response.data as List<dynamic>)
        .map(
          (item) =>
              WardrobeItemData.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
  }

  @override
  Future<void> equip(int petId, String accessoryId) async {
    await _dio.put(
      '${AppConfig.apiPrefix}/pets/$petId/wardrobe-items/$accessoryId/equip',
    );
  }

  @override
  Future<void> unequip(int petId) async {
    await _dio.delete(
      '${AppConfig.apiPrefix}/pets/$petId/wardrobe-items/equipped',
    );
  }
}
