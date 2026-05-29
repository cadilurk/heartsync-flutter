import 'package:mongo_dart/mongo_dart.dart';

class MongoService {
  static late Db db;

  static Future<void> connect() async {
    db = await Db.create(
      'mongodb+srv://heartsync1402_db_user:PuqKrnsOsb6ZZTWB@cluster0.ybdv7qi.mongodb.net/?appName=Cluster0',
    );

    await db.open();

    print('✅ MongoDB Connected');
  }

  static Future<void> testInsert() async {
    final collection = db.collection('test_data');

    await collection.insertOne({
      'name': 'Kiet',
      'age': 20,
      'city': 'Nha Trang',
      'createdAt': DateTime.now().toIso8601String(),
    });

    print('✅ Insert Success');
  }
}