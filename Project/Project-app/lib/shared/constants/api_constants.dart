class ApiConstants {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://efashion-backend.onrender.com/api',
  );

  static const accessToken = String.fromEnvironment('API_ACCESS_TOKEN');
}
