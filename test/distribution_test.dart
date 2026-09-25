import 'package:flutter_test/flutter_test.dart';
import 'package:osea/tools/distribution_tool.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute(
      'CREATE TABLE distributions (species TEXT, worldid INTEGER)',
    );
    await db.execute(
      'CREATE TABLE places (worldid INTEGER, south REAL, north REAL, west REAL, east REAL)',
    );
    await db.execute('CREATE TABLE sp_cls_map (species TEXT, cls INTEGER)');
    await db.insert('places', {
      'worldid': 1,
      'south': 12.19,
      'north': 12.96,
      'west': -87,
      'east': -86,
    });
    for (final species in ['known', 'unmapped', 'null_class']) {
      await db.insert('distributions', {'species': species, 'worldid': 1});
    }
    await db.insert('sp_cls_map', {'species': 'known', 'cls': 7});
    await db.insert('sp_cls_map', {'species': 'null_class', 'cls': null});
  });
  tearDown(() => db.close());

  test(
    'unmapped species do not break an otherwise valid regional result',
    () async {
      expect(await Distribution.queryDatabase(db, 12.5, -86.5), [7]);
    },
  );
  test(
    'region edges are inclusive and outside locations return no matches',
    () async {
      expect(await Distribution.queryDatabase(db, 12.19, -87), [7]);
      expect(await Distribution.queryDatabase(db, 12.96, -86), [7]);
      expect(await Distribution.queryDatabase(db, 0, 0), isEmpty);
    },
  );
}
