import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class BibleVerse {
  int _id;
  int _book;
  int _chapter;
  int _verse;
  String _text;

  static final columns = ["id", "b", "c", "v", "t"];

  int get id => _id;
  int get book => _book;
  int get chapter => _chapter;
  int get verse => _verse;
  String get text => _text;

  BibleVerse.fromMap(Map<String, dynamic> map) {
    this._id = map['id'];
    this._book = map['b'];
    this._chapter = map['c'];
    this._verse = map['v'];
    this._text = map['t'];
  }

  Map<String, dynamic> toMap() {
    var map = new Map<String, dynamic>();
    map['id'] = _id;
    map['b'] = _book;
    map['c'] = _chapter;
    map['v'] = _verse;
    map['t'] = _text;
    return map;
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = new DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  final String tableBible = 't_asv';

  static Database _db;

  DatabaseHelper.internal();

  Future<Database> get db async {
    return await initDb();
  }

  initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "bible.db");

    if (FileSystemEntity.typeSync(path) == FileSystemEntityType.notFound) {
      ByteData data = await rootBundle.load(join('db', 'bible.db'));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await new File(path).writeAsBytes(bytes, flush: true);
    }
    _db = await openDatabase(path);
  }

  Future<List<Map>> fetchBooks() async {
    await db;
    List<Map> results = await _db.rawQuery('SELECT * FROM key_english');
    return results;
  }

  Future close() async {
    var dbClient = await db;
    return dbClient.close();
  }
}
