import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper{
  static final _databaseName = "mydb.db";
  static final _databaseVersion = 1;

  static final tableName = "mycontact";

  static final columnId = "_id";
  static final columnName = "_name";
  static final columnNumber = "_number";

  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static  Database _database;

  Future<Database> get database async{
    if (_database != null){
      return _database;
    }
    else{
      _database = await _initDatabase();
      return _database;
    }
  }

  _initDatabase() async {
          
          return await openDatabase(join(await getDatabasesPath(),_databaseName),
          version: _databaseVersion,
          onCreate: _onCreate);
  }

  Future _onCreate(Database db , int ver) async{

   await db.execute('''CREATE TABLE $tableName($columnId INTEGER PRIMARY KEY,
   $columnName TEXT NOT NULL,
   $columnNumber TEXT NOT NULL)''');

  }

  Future<int> insert(Map<String,dynamic> map) async{
    Database db = await database;
    return await db.insert(tableName, map);
  }

  Future<List<Map<String,dynamic>>> queryAll() async{
    Database db = await database;
    return await db.query(tableName);
  }

}