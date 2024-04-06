import "package:path/path.dart";
import 'package:sqflite/sqflite.dart';
import "dart:io" as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_simple_dependency_injection/injector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data_models.dart';

class DB {
  static final DB _instance = new DB.internal();

  factory DB() => _instance;
  static Database _db;
  SharedPreferences prefs;

  String CREATE_TABLE_STUDENT = "CREATE TABLE student(code INTEGER PRIMARY KEY, last_name TEXT, first_name TEXT, sex TEXT, class TEXT, count INTEGER)";
  String CREATE_TABLE_PRESENCE = "CREATE TABLE presence(id INTEGER PRIMARY KEY AUTOINCREMENT, date TEXT, time TEXT, student INTEGER, FOREIGN KEY(student) REFERENCES student(code) ON DELETE CASCADE)";


  DB.internal();

  initDb() async {
    prefs = await SharedPreferences.getInstance();
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "cem.db");
    _db = await openDatabase(path, version: 3, onCreate: _onCreate,onConfigure: _onConfigure);
  }

  Database get db {
    return _db;
  }

  void _onCreate(Database db, int version) async {
    // When creating the db, create the table
    await db.execute(this.CREATE_TABLE_STUDENT);
    await db.execute(this.CREATE_TABLE_PRESENCE);
    prefs.setInt("count", 0);
  }

  void _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }


  Future<int> insertNewStudent(Student student) async {
    Map m = student.toMap();
    int value = prefs.getInt("count") + 1;
    m['count'] = value;
    prefs.setInt("count", value);
    return await DB().db.insert("student", m);
  }


  Future<int> removeStudent(int code) async{
    return await DB().db.delete("student",where: "code = ?",whereArgs: [code]);
  }

  Future<int> updateStudent(Student student) async{
    return await DB().db.update("student",student.toMap(),where:"code = ?",whereArgs: [student.code]);
  }


  Future<List<Student>> getAllStudents() async {
    //databaseHelper has been injected in the class
    List<Map> list = await _instance.db.rawQuery(
        "Select * from student ORDER BY count DESC", []);
    List<Student> result = [];
    for (int i = 0; i < list.length; i++) {
      result.add(new Student(code: list[i]['code'],
          lastName: list[i]['last_name'],
          firstName: list[i]['first_name'],
          sex: list[i]['sex'],
          classe: stringToClasse(list[i]['class'])));
    }
    return result;
  }

  Future<List<Student>> getStudentsByFullName(String fullName) async {
    //databaseHelper has been injected in the class WHERE FullName like '%$fullName%    || \" \" || last_name
    List<Map> list = await _instance.db.rawQuery(
        "SELECT *,first_name || ' ' || last_name AS FullName FROM student WHERE FullName like '%$fullName%'",
        []);
    List<Student> result = [];
    for (int i = 0; i < list.length; i++) {
      result.add(new Student(code: list[i]['code'],
          lastName: list[i]['last_name'],
          firstName: list[i]['first_name'],
          sex: list[i]['sex'],
          classe: stringToClasse(list[i]['class'])));
    }
    return result;
  }

  //SELECT first_name || ' ' || last_name AS FullName FROM student WHERE FullName like "%‎%"
  Future<void> clearStudentTable() async {
    //databaseHelper has been injected in the class
    //await _instance.db.rawQuery("DELETE FROM student", []);
    await DB().db.delete("student");
    prefs.setInt("count", 0);
    //await _instance.db.delete("student",where:"",whereArgs: []);
  }

  Future<bool> isStudentPresentInDay(int studentCode, String day) async {
    List<Map> list = await _instance.db.rawQuery(
        "SELECT * FROM presence WHERE presence.student == $studentCode AND presence.date == '$day'",
        []);
    if (list.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  Future<bool> isStudentCodeExists(int studentCode) async {
    List<Map> list = await _instance.db.rawQuery(
        "SELECT * FROM student WHERE code == $studentCode", []);
    if (list.isEmpty) {
      return false;
    } else {
      return true;
    }
  }

  Future<int> insertNewPresence(Presence presence) async {
    return await DB().db.insert("presence", presence.toMap());
  }

  Future<List<Presence>> getTodaysPresenceList() async {
    String date = dateToString(DateTime.now());

    //databaseHelper has been injected in the class
    List<Map> list = await _instance.db.rawQuery("SELECT presence.id,"
        "presence.date,"
        "presence.time,"
        "presence.student as studentCode,"
        "student.last_name || ' ' || student.first_name AS fullName,"
        "student.class,"
        "student.sex "
        "FROM presence "
        "INNER JOIN student ON presence.student = student.code "
        "WHERE presence.date == '$date'"
        "ORDER BY id DESC", []);
    List<Presence> result = [];
    for (int i = 0; i < list.length; i++) {
      result.add(new Presence(stringToDateTime(list[i]['date'], list[i]['time']),list[i]['studentCode'],
          id: list[i]['id'],
          fullName: list[i]['fullName'],
          sex: list[i]['sex'],
          classe: stringToClasse(list[i]['class'])
      )
      );
    }
    return result;
  }

  Future<List<Presence>> getPresenceListByDate(DateTime date) async {
    String stringDate = dateToString(date);

    //databaseHelper has been injected in the class
    //SELECT * FROM student JOIN presence ON student.code = presence.student AND date = '7/3/2021'
    //SELECT
    // id,code,last_name,first_name,sex,class,date,time
    // FROM student JOIN presence ON student.code = presence.student AND date = '7/3/2021'
    List<Map> list = await _instance.db.rawQuery("SELECT id, date, time, student as studentCode, last_name || ' ' || first_name AS fullName, class, sex "
        "FROM student JOIN presence ON presence.student = student.code "
        "AND date == '$stringDate' "
        "ORDER BY id DESC", []);
    List<Presence> result = [];
    for (int i = 0; i < list.length; i++) {
      result.add(new Presence(stringToDateTime(list[i]['date'], list[i]['time']),list[i]['studentCode'],
          id: list[i]['id'],
          fullName: list[i]['fullName'],
          sex: list[i]['sex'],
          classe: stringToClasse(list[i]['class'])
      )
      );
    }
    return result;
  }

  Future<List<Student>> getAbsenceListByDate(DateTime date) async {
    String stringDate = dateToString(date);

    //databaseHelper has been injected in the class
    //SELECT * FROM student JOIN presence ON student.code = presence.student AND date = '7/3/2021'
    //SELECT
    // id,code,last_name,first_name,sex,class,date,time
    // FROM student JOIN presence ON student.code = presence.student AND date = '7/3/2021'
    List<Map> list = await _instance.db.rawQuery("SELECT * FROM student "
        "WHERE student.code NOT IN "
        "(SELECT presence.student AS code FROM presence WHERE date = '$stringDate')", []);
    List<Student> result = [];
    for (int i = 0; i < list.length; i++) {
      result.add(new Student(code: list[i]['code'],
          lastName: list[i]['last_name'],
          firstName: list[i]['first_name'],
          sex: list[i]['sex'],
          classe: stringToClasse(list[i]['class'])
      )
      );
    }
    return result;
  }
}



class Injection {
  static DB _db = DB();
  static Injector injector;

  static Future initInjection() async {
    await _db.initDb();

    injector = Injector.getInjector();


    injector.map<DB>((i) => _db,
        isSingleton: true);
  }
}