import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:path_provider/path_provider.dart';
import 'package:presence/StudentsListPage.dart';

generateRandomCode() {
  Random r = new Random();
  return 10000000 + r.nextInt(99999999 - 10000000);
}

class Student {
  int code;
  String lastName;
  String firstName;
  String sex;
  Classe classe;

  Student({this.code, this.lastName, this.firstName, this.sex, this.classe});

  get getClasse => this.classe;

  get fullName => this.firstName + " " + this.lastName;

  toCSVLine() {
    return "$code, \u200E$lastName, \u200E$firstName, \u200E$sex, \u200E" +
        classe.toString() +
        "\n";
  }

  toMap() {
    return {
      'code': this.code,
      'last_name': this.lastName,
      'first_name': this.firstName,
      'sex': this.sex,
      'class': this.classe.toString()
    };
  }
}

class StudentListCsvEditor {
  String attributes =
      "\"الكود\",\"اللقب\",\"الإسم\",\"الجنس\",\"القسم\"" + "\n";
  String csv = "";

  StudentListCsvEditor(List<Student> list) {
    csv += this.attributes;
    for (int i = 0; i < list.length; i++) {
      csv += list.elementAt(i).toCSVLine();
    }
  }

  void printCsv() {
    print(csv);
  }

  Future<bool> saveFile() async {
    Directory directory;
    try {
      directory = await getExternalStorageDirectory();
      String newPath = "";
      List<String> paths = directory.path.split("/");
      for (int x = 1; x < paths.length; x++) {
        String folder = paths[x];
        if (folder != "Android") {
          newPath += "/" + folder;
        } else {
          break;
        }
      }
      newPath = newPath + "/";
      directory = Directory(newPath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        File saveFile = File(directory.path + "قائمة التلاميذ" + ".csv");
        await saveFile.writeAsString(csv, encoding: utf8);
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<List<Student>> loadFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File file = File(result.files.single.path);
      String str = await file.readAsString(encoding: utf8);
      List<String> stringList = str.split("\n");
      stringList.removeAt(0);
      stringList.removeLast();

      List<Student> studentsList = [];

      for (int i = 0; i < stringList.length; i++) {
        Student s = csvStringToStudent(stringList.elementAt(i));
        studentsList.add(s);
      }
      return studentsList;
    } else {
      // User canceled the picker
      return [];
    }
  }
}
class PresenceCsvEditor {
  String presenceAttributes =
      "\"الكود\",\"الإسم و اللقب\",\"الجنس\",\"القسم\",\"الوقت\"" + "\n";
  String absenceAttributes =
      "\"الكود\",\"اللقب\",\"الإسم\",\"الجنس\",\"القسم\"" + "\n";
  String absenceCSV = "";
  String presenceCSV = "";

  DateTime date;

  PresenceCsvEditor.presenceConst(List<Presence> list,DateTime d) {
    presenceCSV += this.presenceAttributes;
    for (int i = 0; i < list.length; i++) {
      presenceCSV += list.elementAt(i).toCSVLine();
    }
    date = d;
  }
  PresenceCsvEditor.absenceConst(List<Student> list, DateTime d) {
    absenceCSV += this.absenceAttributes;
    for (int i = 0; i < list.length; i++) {
      absenceCSV += list.elementAt(i).toCSVLine();
    }
    date = d;
  }


  Future<bool> savePresenceFile() async {
    Directory directory;
    try {
      directory = await getExternalStorageDirectory();
      String newPath = "";
      List<String> paths = directory.path.split("/");
      for (int x = 1; x < paths.length; x++) {
        String folder = paths[x];
        if (folder != "Android") {
          newPath += "/" + folder;
        } else {
          break;
        }
      }
      newPath = newPath + "/";
      directory = Directory(newPath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        String ddd = date.year.toString() + "-" + date.month.toString() + "-" + date.day.toString();
        File saveFile = File(directory.path + "قائمة الحضور $ddd" + ".csv");
        await saveFile.writeAsString(presenceCSV, encoding: utf8);
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }

  Future<bool> saveAbsenceFile() async {
    Directory directory;
    try {
      directory = await getExternalStorageDirectory();
      String newPath = "";
      List<String> paths = directory.path.split("/");
      for (int x = 1; x < paths.length; x++) {
        String folder = paths[x];
        if (folder != "Android") {
          newPath += "/" + folder;
        } else {
          break;
        }
      }
      newPath = newPath + "/";
      directory = Directory(newPath);

      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      if (await directory.exists()) {
        String ddd = date.year.toString() + "-" + date.month.toString() + "-" + date.day.toString();
        File saveFile = File(directory.path + "قائمة الغياب $ddd" + ".csv");
        await saveFile.writeAsString(absenceCSV, encoding: utf8);
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }
}

Student csvStringToStudent(String s) {
  List<String> l = s.split(", ");
  int code = int.parse(l.elementAt(0));
  String lastName = l.elementAt(1);
  String firstName = l.elementAt(2);
  String sex = l.elementAt(3);
  Classe classe = new Classe(
      level: int.parse(l.elementAt(4)[2]),
      classeNumber: int.parse(l.elementAt(4).substring(5)));
  Student ss = new Student(
      code: code,
      lastName: lastName,
      firstName: firstName,
      sex: sex,
      classe: classe);
  return ss;
}

Classe stringToClasse(String s) {
  /*List<String> l = [];
  for (int i = 0; i< s.length;i++){
    l.add(s[i]);
  }*/
  int level = int.parse(s[1]);
  int classNum = int.parse(s.substring(4));
  return new Classe(level: level, classeNumber: classNum);
}

class Classe {
  int level;
  int classeNumber;

  Classe({this.level, this.classeNumber});

  toString() {
    return "\u202E$level" + "م" + "\u202E$classeNumber";
    //return "1m2";
  }

  getLevel() {
    return this.level;
  }

  getClasseNumber() {
    return this.classeNumber;
  }

  setLevel(int value) {
    this.level = value;
  }

  setClasseNumber(int value) {
    this.classeNumber = value;
  }
}

String dateToString(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}

String timeToString(DateTime time) {
  String h = time.hour < 10 ? "0${time.hour}" : "${time.hour}";
  String m = time.minute < 10 ? "0${time.minute}" : "${time.minute}";
  String s = time.second < 10 ? "0${time.second}" : "${time.second}";
  return h+":"+m+":"+s;
}

DateTime stringToTime(String time) {
  List<String> data = time.split(":");
  int hour = int.parse(data[0]);
  int minute = int.parse(data[1]);
  int second = int.parse(data[2]);
  return new DateTime(0,0,0,hour,minute,second,0,0);
}

DateTime stringToDate(String date) {
  List<String> data = date.split("/");
  int day = int.parse(data[0]);
  int month = int.parse(data[1]);
  int year = int.parse(data[2]);
  return new DateTime(year,month,day,0,0,0,0,0);
}

DateTime stringToDateTime(String date, String time) {
  List<String> data1 = time.split(":");
  List<String> data2 = date.split("/");


  int hour = int.parse(data1[0]);
  int minute = int.parse(data1[1]);
  int second = int.parse(data1[2]);

  int day = int.parse(data2[0]);
  int month = int.parse(data2[1]);
  int year = int.parse(data2[2]);

  return new DateTime(year,month,day,hour,minute,second,0,0);
}

class Presence {
  int id;
  int Student_id;
  DateTime date_time;
  String fullName;
  Classe classe;
  String sex;

  Presence(this.date_time, this.Student_id, {this.id, this.fullName, this.classe, this.sex});

  String getDateString(){
    return dateToString(this.date_time);
  }
  toMap(){
    return {
      'date': dateToString(this.date_time),
      'time': timeToString(this.date_time),
      'student': this.Student_id
    };
  }

  toCSVLine() {
    return "$Student_id, \u200E$fullName, \u200E$sex, \u200E" +
        classe.toString() +", "+ timeToString(date_time) +
        "\n";
  }
}
