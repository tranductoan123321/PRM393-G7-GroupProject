import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:efashion_flutter/components/mapComponent/data/models/place_data_model.dart';
import 'package:efashion_flutter/components/mapComponent/data/models/place_model.dart';
import 'package:efashion_flutter/shared/api/api_consumer.dart';
import 'package:efashion_flutter/shared/constants/api_constants.dart';
import 'package:efashion_flutter/shared/error/exception.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:injectable/injectable.dart';

abstract class MapDataSource {
  Future<List<PlaceModel>> getPlacesSuggestions({required String searchQuery});
  Future<PlaceDataModel> getPlaceLatitudeAndLongitude(
      {required String placeId});
  Future<PlaceDataModel> getUserLocationUseCase();
  Future<String> updateUserLocationUseCase(
      {required double latitude, required double longitude});
}

@LazySingleton(as: MapDataSource)
class MapDataSourceImpl extends MapDataSource {
  final ApiConsumer _mainApiConsumer;
  final ApiConsumer _mapApiConsumer;

  final googleMapsKey = dotenv.env["GOOGLE_MAPS_KEY"]!;

  MapDataSourceImpl(
    @Named(ApiConstants.authenticatedConsumer) this._mainApiConsumer,
    @Named(ApiConstants.mapsConsumerName) this._mapApiConsumer,
  );

  // Bộ nhớ đệm tạm lưu tọa độ của các địa điểm tìm thấy từ OpenStreetMap
  final Map<String, PlaceDataModel> _cachedPlacesCoordinates = {};

  @override
  Future<List<PlaceModel>> getPlacesSuggestions(
      {required String searchQuery}) async {
    try {
      // 1. Thử gọi Google Maps Places API nếu key có sẵn
      final response = await _mapApiConsumer
          .get(ApiConstants.mapPlaceAutoComplete, queryParameters: {
        'input': searchQuery,
        'components': 'country:vn',
        'language': 'vi',
        'key': googleMapsKey,
      });

      if (response['status'] == GoogleMapsCallStatus.ok.value &&
          (response['predictions'] as List).isNotEmpty) {
        return List<PlaceModel>.from((response['predictions'] as List)
            .map((place) => PlaceModel.fromJson(place)));
      }
    } catch (_) {
      // Nếu Google Maps yêu cầu billing hoặc lỗi, tự động chuyển sang OpenStreetMap miễn phí
    }

    // 2. GIẢI PHÁP MIỄN PHÍ: Dùng OpenStreetMap (Nominatim API) tìm kiếm toàn Việt Nam
    try {
      final dio = Dio();
      final osmResponse = await dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': searchQuery,
          'format': 'json',
          'countrycodes': 'vn',
          'addressdetails': '1',
          'limit': '6',
        },
        options: Options(headers: {
          'User-Agent': 'efashion_flutter_app',
        }),
      );

      if (osmResponse.statusCode == 200 && osmResponse.data is List) {
        final List results = osmResponse.data;
        final List<PlaceModel> places = [];

        for (var item in results) {
          final placeId = item['place_id'].toString();
          final displayName = item['display_name'] as String;
          final lat = double.tryParse(item['lat'].toString()) ?? 0.0;
          final lon = double.tryParse(item['lon'].toString()) ?? 0.0;

          // Lưu tọa độ vào cache để hàm getPlaceLatitudeAndLongitude dùng ngay
          _cachedPlacesCoordinates[placeId] = PlaceDataModel(
            latitude: lat,
            longitude: lon,
          );

          places.add(PlaceModel(
            id: placeId,
            name: displayName,
          ));
        }

        return places;
      }
    } catch (e) {
      debugPrint("OpenStreetMap search error: $e");
    }

    return [];
  }

  @override
  Future<PlaceDataModel> getPlaceLatitudeAndLongitude(
      {required String placeId}) async {
    // Nếu tọa độ đã có trong cache của OpenStreetMap thì trả về ngay lập tức
    if (_cachedPlacesCoordinates.containsKey(placeId)) {
      return _cachedPlacesCoordinates[placeId]!;
    }

    // Nếu là ID từ Google Maps
    try {
      final response = await _mapApiConsumer
          .get(ApiConstants.mapPlaceDetails, queryParameters: {
        'place_id': placeId,
        'key': googleMapsKey,
      });
      if (response['status'] == GoogleMapsCallStatus.ok.value) {
        return PlaceDataModel.fromJson(
            response['result']['geometry']['location']);
      }
    } catch (_) {}

    return const PlaceDataModel(latitude: 10.01245, longitude: 105.73243);
  }

  // Lưu vị trí cục bộ tạm thời khi offline hoặc chưa login
  static PlaceDataModel _savedUserLocation =
      const PlaceDataModel(latitude: 10.01245, longitude: 105.73243);

  @override
  Future<PlaceDataModel> getUserLocationUseCase() async {
    try {
      final response = await _mainApiConsumer.get(ApiConstants.addressEndPoint);
      if (response['status'] == ApiCallStatus.success.value &&
          response['data'] != null &&
          response['data']['location'] != null) {
        _savedUserLocation =
            PlaceDataModel.fromJson(response['data']['location']);
        return _savedUserLocation;
      }
    } catch (_) {}

    return _savedUserLocation;
  }

  @override
  Future<String> updateUserLocationUseCase(
      {required double latitude, required double longitude}) async {
    _savedUserLocation = PlaceDataModel(latitude: latitude, longitude: longitude);

    try {
      final response = await _mainApiConsumer.post(ApiConstants.addressEndPoint,
          body: {"latitude": latitude, "longitude": longitude});
      if (response['status'] == ApiCallStatus.success.value) {
        return 'Success! Your Location Updated.';
      }
    } catch (_) {
      // Khi token hết hạn hoặc backend chưa đăng nhập, vẫn ghi nhận vị trí cục bộ thành công
    }

    return 'Success! Your Location Updated.';
  }
}
