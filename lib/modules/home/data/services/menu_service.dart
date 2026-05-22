import 'package:sport_platform/core/network/api_endpoints.dart';
import 'package:sport_platform/core/network/dio_client.dart';
import 'package:sport_platform/modules/home/data/models/menu_item_model.dart';

class MenuService {
  final DioClient _client = DioClient();

  Future<List<MenuItemModel>> getMenu() async {
    final response = await _client.get(ApiEndpoints.menu);
    final List<dynamic> data = response.data as List<dynamic>;

    // La API ya devuelve la jerarquía anidada; solo ordenamos los padres
    final items = data
        .map((e) => MenuItemModel.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return items;
  }
}
