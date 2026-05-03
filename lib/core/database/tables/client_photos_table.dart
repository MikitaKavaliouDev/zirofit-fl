import 'package:drift/drift.dart';

class ClientPhotos extends Table {
  TextColumn get id => text()();
  TextColumn get clientId => text()();
  Int64Column get photoDate => int64()();
  TextColumn get imagePath => text()();
  TextColumn get caption => text().nullable()();
  TextColumn get checkInId => text().nullable()();

  Int64Column get createdAt => int64()();
  Int64Column get updatedAt => int64()();
  Int64Column? get deletedAt => int64().nullable()();
  IntColumn get syncStatus => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
