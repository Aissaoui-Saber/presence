import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:presence/database.dart';
import 'package:presence/main.dart';

import 'data_models.dart';

class Statistics extends StatefulWidget {
  @override
  _StatisticsState createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int selectedTab;
  DateTime selectedDate;
  List<Widget> presentListWidgets;
  List<Widget> absentListWidgets;
  List<Presence> presenceList;
  List<Student> absenceList;
  PresenceCsvEditor PCEpresence;
  PresenceCsvEditor PCEabsence;

  Future<List<Widget>> getPresenceListFromDB(DateTime date) async {
    presenceList = await myDatabase.getPresenceListByDate(date);
    List<Widget> l = new List();
    for (int i = 0; i < presenceList.length; i++) {
      l.add(presenceListItem(presenceList.elementAt(i)));
    }
    return l;
  }
  Future<List<Widget>> getAbsenceListFromDB(DateTime date) async {
    absenceList = await myDatabase.getAbsenceListByDate(date);
    List<Widget> l = new List();
    for (int i = 0; i < absenceList.length; i++) {
      l.add(absenceListItem(absenceList.elementAt(i)));
    }
    return l;
  }

  _selectDate(BuildContext context) async {
    final DateTime picked = await showDatePicker(
      context: context,
      initialDate: selectedDate, // Refer step 1
      firstDate: DateTime(2021),
      lastDate: DateTime(2041),
    );
    if (picked != null && picked != selectedDate){
      presentListWidgets = await getPresenceListFromDB(picked);
      absentListWidgets = await getAbsenceListFromDB(picked);
      setState(() {
        selectedDate = picked;
      });
    }
  }

  void switchTab() {
    setState(() {
      if (selectedTab == 0) {
        selectedTab = 1;
      } else {
        selectedTab = 0;
      }
    });
  }

  @override
  void initState() {
    selectedTab = 1;
    selectedDate = DateTime.now();
    presentListWidgets = new List<Widget>();
    absentListWidgets = new List<Widget>();
    () async {
      presentListWidgets = await getPresenceListFromDB(selectedDate);
      absentListWidgets = await getAbsenceListFromDB(selectedDate);
      setState(() {

      });
    }();

    super.initState();
  }

  Color getSexColor(String sex) {
    if (sex.contains("ذكر")) {
      return Colors.blueAccent;
    } else {
      return Colors.pink;
    }
  }

  Color getClassColor(Classe classe) {
    if (classe.level == 1) {
      return Colors.brown;
    }
    if (classe.level == 2) {
      return Colors.blueGrey;
    }
    if (classe.level == 3) {
      return Colors.teal;
    }
    if (classe.level == 4) {
      return Colors.deepPurpleAccent;
    }
  }

  Widget presenceListItem(Presence presence) {
    return new Container(
      margin: EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(2, 0, 2, 0),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
                    child: Text(
                      timeToString(presence.date_time),
                      style: TextStyle(
                          fontFamily: 'HacenTunisiaLT',
                          fontSize: 16,
                          color: Color(0xFFFFFFFF)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black,
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text(
                      presence.classe.toString(),
                      style: TextStyle(
                          fontFamily: 'HacenTunisiaLT',
                          fontSize: 16,
                          color: Color(0xFFFFFFFF)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: getClassColor(presence.classe),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text(
                      presence.sex,
                      style: TextStyle(
                          fontFamily: 'HacenTunisiaLT',
                          fontSize: 16,
                          color: Color(0xFFFFFFFF)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: getSexColor(presence.sex),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.all(4),
              child: Text(
                presence.fullName,
                style: TextStyle(
                    fontFamily: 'HacenTunisiaLT',
                    fontSize: 20,
                    color: Color(0xFFFFFFFF)),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color.fromRGBO(40, 76, 87, 1),
      ),
    );
  }

  Widget absenceListItem(Student student) {
    return new Container(
      margin: EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  margin: EdgeInsets.all(2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text(
                      student.classe.toString(),
                      style: TextStyle(
                          fontFamily: 'HacenTunisiaLT',
                          fontSize: 16,
                          color: Color(0xFFFFFFFF)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: getClassColor(student.classe),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(2),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                    child: Text(
                      student.sex,
                      style: TextStyle(
                          fontFamily: 'HacenTunisiaLT',
                          fontSize: 16,
                          color: Color(0xFFFFFFFF)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: getSexColor(student.sex),
                  ),
                ),
              ],
            ),
            Container(
              margin: EdgeInsets.all(4),
              child: Text(
                student.fullName,
                style: TextStyle(
                    fontFamily: 'HacenTunisiaLT',
                    fontSize: 20,
                    color: Color(0xFFFFFFFF)),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Color.fromRGBO(40, 76, 87, 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromRGBO(22, 57, 68, 1),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: FlatButton(
                      onPressed: () {
                        switchTab();
                      },
                      child: Text(
                        "الغيابات ("+absentListWidgets.length.toString()+")",
                        style: TextStyle(
                            fontFamily: 'HacenTunisiaLT',
                            fontSize: 22,
                            color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                      color: selectedTab == 0
                          ? Colors.blueGrey
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(24.0)),
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: FlatButton(
                      onPressed: () {
                        switchTab();
                      },
                      child: Text(
                        "الحظور ("+presentListWidgets.length.toString()+")",
                        style: TextStyle(
                            fontFamily: 'HacenTunisiaLT',
                            fontSize: 22,
                            color: Colors.lightGreen),
                        textAlign: TextAlign.center,
                      ),
                      color: selectedTab == 1
                          ? Colors.blueGrey
                          : Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: new BorderRadius.circular(24.0)),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: selectedTab == 1 ? presentListWidgets : absentListWidgets,
              ),
            ),
            Container(
              margin: EdgeInsets.all(16),
              child: SizedBox(
                width: 200,
                child: RaisedButton(
                  onPressed: () {
                    _selectDate(context);
                  },
                  child: Row(
                    children: [
                      Text(
                        dateToString(selectedDate),
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontFamily: "HacenTunisiaLT"),
                      ),
                      Icon(Icons.date_range_rounded, color: Colors.white),
                    ],
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  ),
                  color: Colors.blue,
                  padding: EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(16.0)),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          PCEpresence = new PresenceCsvEditor.presenceConst(presenceList, selectedDate);
          PCEabsence = new PresenceCsvEditor.absenceConst(absenceList, selectedDate);
          if(await PCEpresence.savePresenceFile()){
            if (await PCEabsence.saveAbsenceFile()){
              _scaffoldKey.currentState.showSnackBar(SnackBar(
                content: Text(
                  "تم حفظ الملف بنجاح",
                  textAlign: TextAlign.center,
                ),
                duration: Duration(seconds: 1),
                backgroundColor: Colors.green,
              ));
            }else{
              _scaffoldKey.currentState.showSnackBar(SnackBar(
                content: Text(
                  "عذرا, لم يتم حفظ الملف بسبب خطأ تقني",
                  textAlign: TextAlign.center,
                ),
                duration: Duration(seconds: 3),
                backgroundColor: Colors.redAccent,
              ));
            }
          }else{
            _scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text(
                "عذرا, لم يتم حفظ الملف بسبب خطأ تقني",
                textAlign: TextAlign.center,
              ),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.redAccent,
            ));
          }
          },
        child: Icon(Icons.save_alt),
        backgroundColor: Colors.green,
      ),
    );
  }
}
