@Deprecated('Mobile apps must not connect directly to MongoDB. Use ApiClient instead.')
class MongoService {
  MongoService._();

  static Future<void> connect() {
    throw UnsupportedError(
      'Direct MongoDB access from Flutter is disabled. Configure a backend API and use ApiClient.',
    );
  }
}
