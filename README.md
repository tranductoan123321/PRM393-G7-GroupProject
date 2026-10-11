# Project App (Home-only)

This is a standalone Flutter project containing only the Home screen and the
API/data code it needs. It loads collections, categories, discounted products,
brands, and each brand's products from the E-Fashion backend. Category and
gender selections can be applied to the product requests.

The Dart code follows the original app's feature-oriented layout while keeping
only Home-related modules:

```text
lib/
  components/
    collectionComponent/
    productComponent/
  presentation/
    product/
      bloc/home_bloc/
      components/home/
      screens/
    shared/widgets/
  shared/
    api/
    constants/
```

Models, entities, repositories, and Home use cases are separated from the
screen and its collection/category/offer/brand widgets. Search, product detail,
cart, and other non-Home features are intentionally excluded.

The default API is `https://efashion-backend.onrender.com/api`. Override it at
run time if using another backend:

```powershell
flutter run --dart-define=API_BASE_URL=https://your-backend.example/api
```

The Home list and collection endpoints are public on the default backend. If
your backend requires a bearer token for its product endpoints, provide one
without adding it to source control:

```powershell
flutter run --dart-define=API_ACCESS_TOKEN=your-access-token
```

`API_ACCESS_TOKEN` is optional and is sent only as an Authorization bearer
header when provided. A failed API request is shown on screen with a retry
button; there is no sample-data fallback.

Run checks from this directory:

```powershell
flutter pub get
flutter analyze
flutter test
flutter run
```

Search, notifications, product details, favorites, cart, and other application
features are intentionally outside this project.
