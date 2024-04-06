import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:presence/data_models.dart';
import 'package:presence/database.dart';
import 'package:presence/statisticsPage.dart';
import 'StudentsListPage.dart';
import 'package:barras/barras.dart';

DB myDatabase;

void main() async {
  runApp(MyApp());
  //await Injection.initInjection();
  //myDatabase = Injection.injector.get();
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: MyHomePage(title: 'تطبيق'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Widget> _presenceItemsList = [];
  String _numberOfPresenceTitle = "تسجيلات اليوم (0 تلميذ)";

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

  Color getSexColor(String sex) {
    if (sex.contains("ذكر")) {
      return Colors.blueAccent;
    } else {
      return Colors.pink;
    }
  }

  Future<void> markPresent(String scanedCode) async {
    int studentCode = int.parse(scanedCode);
    if (await myDatabase.isStudentCodeExists(studentCode)) {
      if (!await myDatabase.isStudentPresentInDay(
          studentCode, dateToString(DateTime.now()))) {
        await myDatabase
            .insertNewPresence(new Presence(DateTime.now(), studentCode));
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text("تم التسجيل بنجاح",textAlign: TextAlign.center,),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ));
      } else {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            "لا يمكنك تسجيل التلميذ مرة ثانية, لأنه مسجل اليوم",
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.redAccent,
        ));
      }
    } else {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("لم يتم ايجاد هذا التلميذ في القائمة, أعد المحاولة"),
        duration: Duration(seconds: 2),
      ));
    }
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
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

  Future<List<Widget>> getPresenceListWidgets() async {
    List<Presence> list = await myDatabase.getTodaysPresenceList();
    List<Widget> w = [];
    for (int i = 0; i < list.length; i++) {
      w.add(presenceListItem(list.elementAt(i)));
    }
    return w;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    () async {
      await Injection.initInjection();
      myDatabase = Injection.injector.get();
      _presenceItemsList = await getPresenceListWidgets();

      setState(() {
        _numberOfPresenceTitle =
            "تسجيلات اليوم " + "(" + "${_presenceItemsList.length}" + " تلميذ)";
      });
    }();
  }

  @override
  Widget build(BuildContext context) {
    //myDatabase.insertNewStudent(s1);
    String scanData;
    return Scaffold(
      key: _scaffoldKey,
      body: SafeArea(
        child: Column(children: [
          Center(
            child: Text(
              'متوسطة موهوبي بلقاسم',
              style: TextStyle(
                  fontFamily: 'HacenTunisiaLT',
                  fontSize: 22,
                  color: Color(0xFFFFFFFF)),
              textAlign: TextAlign.center,
            ),
          ),
          Center(
            child: Text(
              'نظام تسيير تلاميذ نصف داخلي',
              style: TextStyle(
                  fontFamily: 'HacenTunisiaLT',
                  fontSize: 18,
                  color: Color(0xFFFFFFFF)),
              textAlign: TextAlign.center,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 15, 0, 0),
            child: Row(
              children: [
                SizedBox(
                  width: 180,
                  height: 60,
                  child: RaisedButton(
                    onPressed: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Statistics(),
                        ),
                      )
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'إحصائيات',
                          style: TextStyle(
                              fontFamily: 'HacenTunisiaLT',
                              fontSize: 22,
                              color: Color(0xFFFFFFFF)),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                          child: Image(
                              image: AssetImage("Images/chart.png"),
                              width: 25,
                              height: 25),
                        )
                      ],
                    ),
                    color: Color.fromRGBO(207, 117, 0, 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(10.0)),
                  ),
                ),
                SizedBox(
                  width: 180,
                  height: 60,
                  child: RaisedButton(
                    onPressed: () {
                      {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentsList(),
                          ),
                        ).then((value) async {
                          await getPresenceListWidgets().then((value) {
                            setState(() {
                              _numberOfPresenceTitle = "تسجيلات اليوم " +
                                  "(" +
                                  "${value.length}" +
                                  " تلميذ)";
                              _presenceItemsList = value;
                            });
                          });
                        });
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'قائمة التلاميذ',
                          style: TextStyle(
                              fontFamily: 'HacenTunisiaLT',
                              fontSize: 22,
                              color: Color(0xFFFFFFFF)),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                          child: Image(
                              image: AssetImage("Images/people.png"),
                              width: 25,
                              height: 25),
                        )
                      ],
                    ),
                    color: Color.fromRGBO(0, 110, 207, 1),
                    shape: RoundedRectangleBorder(
                        borderRadius: new BorderRadius.circular(10.0)),
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
          ),
          Container(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _numberOfPresenceTitle,
                style: TextStyle(
                    fontFamily: 'HacenTunisiaLT',
                    fontSize: 22,
                    color: Color(0xFFFFFFFF)),
                textAlign: TextAlign.right,
              ),
            ),
          ),
          Expanded(
              child: ListView(
            children: _presenceItemsList,
          )),
          //presenceListItem(new Presence(id:1,date_time:new DateTime(2021,1,14,12,13,22),Student_id:12345678));
          Container(
            margin: EdgeInsets.all(8),
            width: 200,
            height: 60,
            child: RaisedButton(
              onPressed: () async {
                if (await _requestPermission(Permission.camera)) {
                  scanData = await Barras.scan(
                    context,
                    viewfinderHeight: 150,
                    viewfinderWidth: 250,
                    borderRadius: 24,
                    borderStrokeWidth: 2,
                    borderFlashDuration: 250,
                    cancelButtonText: "إلغاء",
                    successBeep: true,
                  );
                  if (scanData != null) {
                    await markPresent(scanData);

                    await getPresenceListWidgets().then((value) {
                      setState(() {
                        _numberOfPresenceTitle = "تسجيلات اليوم " +
                            "(" +
                            "${value.length}" +
                            " تلميذ)";
                        _presenceItemsList = value;
                      });
                    });
                  }
                } else {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text("يرجى السماح للتطبيق استعمال الكاميرا"),
                    duration: Duration(seconds: 1),
                  ));
                }
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'تسجيل',
                    style: TextStyle(
                        fontFamily: 'HacenTunisiaLT',
                        fontSize: 28,
                        color: Color(0xFFFFFFFF)),
                    textAlign: TextAlign.center,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8.0, 0, 0, 0),
                    child: Image(
                        image: AssetImage("Images/scanner.png"),
                        width: 30,
                        height: 30),
                  )
                ],
              ),
              color: Color.fromRGBO(0, 126, 38, 1),
              shape: RoundedRectangleBorder(
                  borderRadius: new BorderRadius.circular(10.0)),
            ),
          ),
        ]),
      ),
      backgroundColor: Color.fromRGBO(22, 57, 68, 1),
    );
  }
}
