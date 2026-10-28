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
        'input': searchQuery,
        'key': googleMapsKey,
      });
      }
  }

  @override
        'place_id': placeId,
        'key': googleMapsKey,
      });
      if (response['status'] == GoogleMapsCallStatus.ok.value) {
      }
  }

  // Lưu vị trí cục bộ tạm thời khi offline hoặc chưa login
  static PlaceDataModel _savedUserLocation =
      const PlaceDataModel(latitude: 10.01245, longitude: 105.73243);

  @override
  Future<PlaceDataModel> getUserLocationUseCase() async {
      final response = await _mainApiConsumer.get(ApiConstants.addressEndPoint);
      }
  }

  @override
      final response = await _mainApiConsumer.post(ApiConstants.addressEndPoint,
      if (response['status'] == ApiCallStatus.success.value) {
        return 'Success! Your Location Updated.';
      }
  }
}
