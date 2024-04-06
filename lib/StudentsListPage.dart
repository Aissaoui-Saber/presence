import 'dart:developer';
import 'dart:ui';


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:presence/data_models.dart';

import 'database.dart';
import 'main.dart';

class StudentsList extends StatefulWidget {
  @override
  _StudentsListState createState() => _StudentsListState();
}

class _StudentsListState extends State<StudentsList> {
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  FloatingActionButton _addFloatingButton;
  Widget _addStudentForm;
  Widget _editStudentForm;
  List<Widget> _studentsList;
  int _selectedLevel = 1;
  int _selectedClassNumber = 1;
  String _firstName = "";
  String _lastName = "";
  Student newStudent;
  Student editStudent;
  Student tappedStudent;
  int _sex = 1;
  StudentListCsvEditor editor;

  _StudentsListState() {
    _addFloatingButton = FloatingActionButton(
      onPressed: () {
        newStudent = new Student(
            code: generateRandomCode(),
            lastName: "",
            firstName: "",
            sex: "ذكر",
            classe: new Classe(level: 1, classeNumber: 1));
        openAddStudentForm();
      },
      child: Icon(Icons.add),
      backgroundColor: Colors.green,
    );
    _studentsList = [];
    getStudentListFromDB();
  }

  void insertNewStudentToDB() async {
    newStudent.firstName = _firstName;
    newStudent.lastName = _lastName;
    if (newStudent.firstName.length > 0 && newStudent.lastName.length > 0) {
      int a = await myDatabase.insertNewStudent(newStudent);
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("تمت الإضافة بنجاح"),
        duration: Duration(seconds: 1),
      ));
      newStudent.code = generateRandomCode();
      closeAddStudentForm();
      getStudentListFromDB();
    } else {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text("يرجى ملأ جميع المعلومات"),
        duration: Duration(seconds: 1),
      ));
    }
  }

  void search(String value) async {
    List<Student> result = await myDatabase.getStudentsByFullName(value);
    List<Widget> widgets = [];
    result.forEach((element) {
      widgets.add(studentsListItem(element));
    });
    setState(() {
      _studentsList = widgets;
    });
  }

  Future<void> getStudentListFromDB() async {
    List<Student> result = await myDatabase.getAllStudents();
    List<Widget> widgets = [];
    result.forEach((element) {
      widgets.add(studentsListItem(element));
    });
    editor = new StudentListCsvEditor(result);
    setState(() {
      _studentsList = widgets;
    });
  }

  Future<bool> removeStudentFromDB(int studentCode) async{
      int rows = await myDatabase.removeStudent(studentCode);
      if (rows == 1){
        return true;
      }else{
        return false;
      }
  }

  Future<bool> updateStudentInDB(Student student) async{
      int rows = await myDatabase.updateStudent(student);
      if (rows == 1){
        return true;
      }else{
        return false;
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

  Color getSexColor(String sex) {
    if (sex.contains("ذكر")) {
      return Colors.blueAccent;
    } else {
      return Colors.pink;
    }
  }

  Color getClassColor(Classe classe){
    if (classe.level == 1){
      return Colors.brown;
    }
    if (classe.level == 2){
      return Colors.blueGrey;
    }
    if (classe.level == 3){
      return Colors.teal;
    }
    if (classe.level == 4){
      return Colors.deepPurpleAccent;
    }

  }

  Widget studentsListItem(Student student) {
    return new ListTile(title: Row(
        children: [
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.fromLTRB(4, 8, 2, 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                child: Text(
                  student.classe.toString(),
                  style: TextStyle(
                      fontFamily: 'HacenTunisiaLT',
                      fontSize: 18,
                      color: Color(0xFFFFFFFF)),
                  textAlign: TextAlign.center,
                ),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: getClassColor(student.classe),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              margin: EdgeInsets.fromLTRB(2, 8, 0, 8),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 2, 8, 2),
                child: Text(
                  student.sex,
                  style: TextStyle(
                      fontFamily: 'HacenTunisiaLT',
                      fontSize: 18,
                      color: Color(0xFFFFFFFF)),
                  textAlign: TextAlign.center,
                ),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: getSexColor(student.sex),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
              child: Text(
                student.fullName,
                style: TextStyle(
                    fontFamily: 'HacenTunisiaLT',
                    fontSize: 20,
                    color: Color(0xFFFFFFFF)),
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ],
      ),
    onTap: (){
      tappedStudent = student;
      editStudent = new Student(code: student.code,lastName:student.lastName,firstName:student.firstName,sex:student.sex,classe: new Classe(level:student.classe.level,classeNumber:student.classe.classeNumber));
      openEditStudentForm(student);
    },);
  }

  void handleSexRadioChanges(value) {
    setState(() {
      _sex = value;
    });
    if (value == 0) {
      newStudent.sex = "أنثى";
    } else if (value == 1) {
      newStudent.sex = "ذكر";
    }
  }

  String remove_LTR_RTL_Marks(String s){
    String f = "";
    for (int i = 0; i <s.length;i++){
      if (s.codeUnitAt(i) != 8206){
        f+=s[i];
      }
    }
    return f;
  }

  bool studentInfoChanged(Student original, Student changed){
    if (original.firstName == changed.firstName){
      if (original.lastName == changed.lastName){
        if (remove_LTR_RTL_Marks(original.sex) == remove_LTR_RTL_Marks(changed.sex)){
          if (original.classe.level == changed.classe.level){
            if(original.classe.classeNumber == changed.classe.classeNumber){
              return false;
            }else{
              return true;
            }
          }else{
            return true;
          }
        }else{
          return true;
        }
      }else{
        return true;
      }
    }else{
      return true;
    }
  }

  void openAddStudentForm() {
    setState(() {
      _addFloatingButton = null;
      _addStudentForm = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 500,
          height: 900,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
                child: Text(
                  "إضافة تلميذ جديد الى القائمة",
                  style: TextStyle(
                      fontFamily: "HacenTunisia",
                      color: Colors.white,
                      fontSize: 25),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 250,
                  height: 60,
                  child: TextFormField(
                    autofocus: false,
                    onChanged: (value) {
                      _lastName = value;
                    },
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'اللقب',
                      hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 18.0,
                          fontFamily: 'HacenTunisia'),
                      filled: true,
                      fillColor: Colors.white38,//Color.fromRGBO(35, 35, 35, 1),
                    ),
                    autocorrect: false,
                    style: TextStyle(
                        color: Colors.black54,
                        fontFamily: "HacenTunisia",
                        decoration: TextDecoration.none,
                        fontSize: 18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 250,
                  height: 60,
                  child: TextFormField(
                    onChanged: (value) {
                      _firstName = value;
                    },
                    textDirection: TextDirection.rtl,
                    autofocus: false,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'الإسم',
                      hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 18.0,
                          fontFamily: 'HacenTunisia'),
                      filled: true,
                      fillColor: Colors.white38,
                    ),
                    autocorrect: false,
                    style: TextStyle(
                        color: Colors.black54,
                        fontFamily: "HacenTunisia",
                        decoration: TextDecoration.none,
                        fontSize: 18),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 60,
                    width: 75,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white38,
                        border: null),
                    alignment: Alignment.center,
                    child: DropdownButtonHideUnderline(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton(
                            dropdownColor: Colors.white38,//Color.fromRGBO(35, 35, 35, 1),
                            style: TextStyle(color: Colors.black54),
                            onTap: () {
                              FocusScopeNode currentFocus =
                                  FocusScope.of(context);
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }
                            },
                            value: _selectedClassNumber,
                            items: [
                              DropdownMenuItem(child: Text("1"), value: 1),
                              DropdownMenuItem(child: Text("2"), value: 2),
                              DropdownMenuItem(child: Text("3"), value: 3),
                              DropdownMenuItem(child: Text("4"), value: 4),
                              DropdownMenuItem(child: Text("5"), value: 5),
                              DropdownMenuItem(child: Text("6"), value: 6),
                              DropdownMenuItem(child: Text("7"), value: 7),
                              DropdownMenuItem(child: Text("8"), value: 8),
                              DropdownMenuItem(child: Text("9"), value: 9),
                              DropdownMenuItem(child: Text("10"), value: 10),
                              DropdownMenuItem(child: Text("11"), value: 11),
                              DropdownMenuItem(child: Text("12"), value: 12),
                              DropdownMenuItem(child: Text("13"), value: 13),
                              DropdownMenuItem(child: Text("14"), value: 14),
                              DropdownMenuItem(child: Text("15"), value: 15),
                              DropdownMenuItem(child: Text("16"), value: 16),
                              DropdownMenuItem(child: Text("17"), value: 17),
                              DropdownMenuItem(child: Text("18"), value: 18),
                              DropdownMenuItem(child: Text("19"), value: 19),
                              DropdownMenuItem(child: Text("20"), value: 20),
                            ],
                            onChanged: (value) {
                              newStudent.getClasse.setClasseNumber(value);
                              setState(() {
                                _selectedClassNumber = value;
                              });
                            }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "م",
                      style: TextStyle(
                          fontFamily: "HacenTunisia",
                          color: Colors.white,
                          fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: 60,
                    width: 75,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white38,
                        border: null),
                    alignment: Alignment.center,
                    child: DropdownButtonHideUnderline(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton(
                            dropdownColor: Colors.white38,
                            style: TextStyle(color: Colors.black54),
                            onTap: () {
                              FocusScopeNode currentFocus =
                                  FocusScope.of(context);
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }
                            },
                            value: _selectedLevel,
                            items: [
                              DropdownMenuItem(child: Text("1"), value: 1),
                              DropdownMenuItem(child: Text("2"), value: 2),
                              DropdownMenuItem(child: Text("3"), value: 3),
                              DropdownMenuItem(child: Text("4"), value: 4)
                            ],
                            onChanged: (value) {
                              newStudent.getClasse.setLevel(value);
                              setState(() {
                                _selectedLevel = value;
                              });
                            }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: Text(
                      ":القسم ",
                      style: TextStyle(
                          fontFamily: "HacenTunisia",
                          color: Colors.white,
                          fontSize: 22),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              Container(
                width: 200,
                margin: EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "أنثى",
                            style: TextStyle(
                                fontFamily: "HacenTunisia",
                                color: Colors.white,
                                fontSize: 18),
                            textAlign: TextAlign.right,
                          ),
                          Radio(
                            groupValue: _sex,
                            value: 0,
                            onChanged: (value) {
                              handleSexRadioChanges(value);
                            },
                          )
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "ذكر",
                          style: TextStyle(
                              fontFamily: "HacenTunisia",
                              color: Colors.white,
                              fontSize: 18),
                          textAlign: TextAlign.right,
                        ),
                        Radio(
                          groupValue: _sex,
                          value: 1,
                          onChanged: (value) {
                            handleSexRadioChanges(value);
                          },
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 50,
                      child: RaisedButton(
                        onPressed: () => {closeAddStudentForm()},
                        child: Text(
                          'إلغاء',
                          style: TextStyle(
                              fontFamily: 'HacenTunisiaLT',
                              fontSize: 18,
                              color: Color(0xFFFFFFFF)),
                          textAlign: TextAlign.center,
                        ),
                        color: Color.fromRGBO(143, 25, 11, 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0)),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      height: 50,
                      child: RaisedButton(
                        onPressed: () => {insertNewStudentToDB()},
                        child: Text(
                          'أضف',
                          style: TextStyle(
                              fontFamily: 'HacenTunisiaLT',
                              fontSize: 18,
                              color: Color(0xFFFFFFFF)),
                          textAlign: TextAlign.center,
                        ),
                        color: Color.fromRGBO(0, 110, 207, 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0)),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          color: Color.fromRGBO(0, 0, 0, 0.3),
        ),
      );
    });
  }

  void closeAddStudentForm() {
    setState(() {
      _addFloatingButton = FloatingActionButton(
        onPressed: () {
          newStudent = new Student(
              code: generateRandomCode(),
              lastName: "",
              firstName: "",
              sex: "ذكر",
              classe: new Classe(level: 1, classeNumber: 1));
          openAddStudentForm();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      );
      newStudent = null;
      //newStudent.sex = "ذكر";
      _selectedClassNumber = 1;
      _selectedLevel = 1;
      _sex = 1;
      _firstName = "";
      _lastName = "";
      _addStudentForm = null;
    });
  }

  void openEditStudentForm(Student student) {
    setState(() {
      _addFloatingButton = null;
      _editStudentForm = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: 500,
          height: 900,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 250,
                  height: 60,
                  child: TextFormField(
                    autofocus: false,
                    initialValue: student.lastName,
                    onChanged: (value) {
                      editStudent.lastName = value;
                    },
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'اللقب',
                      hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 18.0,
                          fontFamily: 'HacenTunisia'),
                      filled: true,
                      fillColor: Colors.white38,
                    ),
                    autocorrect: false,
                    style: TextStyle(
                        color: Colors.black54,
                        fontFamily: "HacenTunisia",
                        decoration: TextDecoration.none,
                        fontSize: 18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 250,
                  height: 60,
                  child: TextFormField(
                    onChanged: (value) {
                      editStudent.firstName = value;
                    },
                    textDirection: TextDirection.rtl,
                    autofocus: false,
                    textAlign: TextAlign.right,
                    initialValue: student.firstName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        borderSide: BorderSide.none,
                      ),
                      hintText: 'الإسم',
                      hintStyle: TextStyle(
                          color: Colors.black38,
                          fontSize: 18.0,
                          fontFamily: 'HacenTunisia'),
                      filled: true,
                      fillColor: Colors.white38,
                    ),
                    autocorrect: false,
                    style: TextStyle(
                        color: Colors.black54,
                        fontFamily: "HacenTunisia",
                        decoration: TextDecoration.none,
                        fontSize: 18),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 60,
                    width: 75,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white38,
                        border: null),
                    alignment: Alignment.center,
                    child: DropdownButtonHideUnderline(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton(
                            dropdownColor: Colors.white,
                            style: TextStyle(color: Colors.black54),
                            onTap: () {
                              FocusScopeNode currentFocus =
                              FocusScope.of(context);
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }
                            },
                            value: editStudent.classe.classeNumber,
                            items: [
                              DropdownMenuItem(child: Text("1"), value: 1),
                              DropdownMenuItem(child: Text("2"), value: 2),
                              DropdownMenuItem(child: Text("3"), value: 3),
                              DropdownMenuItem(child: Text("4"), value: 4),
                              DropdownMenuItem(child: Text("5"), value: 5),
                              DropdownMenuItem(child: Text("6"), value: 6),
                              DropdownMenuItem(child: Text("7"), value: 7),
                              DropdownMenuItem(child: Text("8"), value: 8),
                              DropdownMenuItem(child: Text("9"), value: 9),
                              DropdownMenuItem(child: Text("10"), value: 10),
                              DropdownMenuItem(child: Text("11"), value: 11),
                              DropdownMenuItem(child: Text("12"), value: 12),
                              DropdownMenuItem(child: Text("13"), value: 13),
                              DropdownMenuItem(child: Text("14"), value: 14),
                              DropdownMenuItem(child: Text("15"), value: 15),
                              DropdownMenuItem(child: Text("16"), value: 16),
                              DropdownMenuItem(child: Text("17"), value: 17),
                              DropdownMenuItem(child: Text("18"), value: 18),
                              DropdownMenuItem(child: Text("19"), value: 19),
                              DropdownMenuItem(child: Text("20"), value: 20),
                            ],
                            onChanged: (value) {
                              setState(() {
                                editStudent.classe.classeNumber = value;
                              });
                            }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "م",
                      style: TextStyle(
                          fontFamily: "HacenTunisia",
                          color: Colors.white,
                          fontSize: 22),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    height: 60,
                    width: 75,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.0),
                        color: Colors.white38,
                        border: null),
                    alignment: Alignment.center,
                    child: DropdownButtonHideUnderline(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownButton(
                            dropdownColor: Colors.white,
                            style: TextStyle(color: Colors.black54),
                            onTap: () {
                              FocusScopeNode currentFocus =
                              FocusScope.of(context);
                              if (!currentFocus.hasPrimaryFocus) {
                                currentFocus.unfocus();
                              }
                            },
                            value: editStudent.classe.level,
                            items: [
                              DropdownMenuItem(child: Text("1"), value: 1),
                              DropdownMenuItem(child: Text("2"), value: 2),
                              DropdownMenuItem(child: Text("3"), value: 3),
                              DropdownMenuItem(child: Text("4"), value: 4)
                            ],
                            onChanged: (value) {
                              setState(() {
                                editStudent.classe.level = value;
                              });
                            }),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
                    child: Text(
                      ":القسم ",
                      style: TextStyle(
                          fontFamily: "HacenTunisia",
                          color: Colors.white,
                          fontSize: 22),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
              Container(
                width: 200,
                margin: EdgeInsets.all(18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 0, 0, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            "أنثى",
                            style: TextStyle(
                                fontFamily: "HacenTunisia",
                                color: Colors.white,
                                fontSize: 18),
                            textAlign: TextAlign.right,
                          ),
                          Radio(
                            groupValue: remove_LTR_RTL_Marks(editStudent.sex) == remove_LTR_RTL_Marks("ذكر") ? 1 : 0,
                            value: 0,
                            onChanged: (value) {
                              setState(() {
                                if (value == 0) {
                                  editStudent.sex = "أنثى";
                                } else if (value == 1) {
                                  editStudent.sex = "ذكر";
                                }
                              });
                            },
                          )
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "ذكر",
                          style: TextStyle(
                              fontFamily: "HacenTunisia",
                              color: Colors.white,
                              fontSize: 18),
                          textAlign: TextAlign.right,
                        ),
                        Radio(
                          groupValue: remove_LTR_RTL_Marks(editStudent.sex) == remove_LTR_RTL_Marks("ذكر") ? 1 : 0,
                          value: 1,
                          onChanged: (value) {
                            setState(() {
                              if (value == 0) {
                                editStudent.sex = "أنثى";
                              } else if (value == 1) {
                                editStudent.sex = "ذكر";
                              }
                            });
                          },
                        )
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(
                width: 300,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 50,
                      child: RaisedButton(
                        onPressed: () async {
                          if (await removeStudentFromDB(student.code)){
                            closeEditStudentForm();
                            getStudentListFromDB();
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("تم الحذف بنجاح"),
                              duration: Duration(seconds: 1),
                            ));
                          }else{
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("عذرا, لم يتم حذف التلميذ بسبب خطأ تقني"),
                              duration: Duration(seconds: 3),
                            ));
                          }
                        },
                        child: Text(
                          'حذف',
                          style: TextStyle(
                              fontFamily: 'HacenTunisiaLT',
                              fontSize: 18,
                              color: Color(0xFFFFFFFF)),
                          textAlign: TextAlign.center,
                        ),
                        color: Color.fromRGBO(143, 25, 11, 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0)),
                      ),
                    ),
                    SizedBox(
                      width: 120,
                      height: 50,
                      child: RaisedButton(
                        onPressed: () async {
                          if (await updateStudentInDB(editStudent)){
                            closeEditStudentForm();
                            getStudentListFromDB();
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("تم تعديل المعلومات بنجاح"),
                              duration: Duration(seconds: 1),
                            ));
                          }else{
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("عذرا, لم يتم تعديل المعلومات بسبب خطأ تقني"),
                              duration: Duration(seconds: 3),
                            ));
                          }

                          if (studentInfoChanged(tappedStudent, editStudent)){
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("changed"),
                              duration: Duration(seconds: 3),
                            ));
                          }else{
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text("no Changes"),
                              duration: Duration(seconds: 3),
                            ));
                          }
                        },
                        child: Text(
                          'تعديل',
                          style: TextStyle(
                              fontFamily: 'HacenTunisiaLT',
                              fontSize: 18,
                              color: Color(0xFFFFFFFF)),
                          textAlign: TextAlign.center,
                        ),
                        color: Color.fromRGBO(0, 110, 207, 1),
                        shape: RoundedRectangleBorder(
                            borderRadius: new BorderRadius.circular(10.0)),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: FlatButton(
                  onPressed: ()=>{closeEditStudentForm()},
                  child: Text("إلغاء",style: TextStyle(color: Colors.grey,fontSize: 22,fontFamily: "HacenTunisiaLT"),),
                  color: Colors.black38,
                  shape: RoundedRectangleBorder(
                      borderRadius: new BorderRadius.circular(10.0)),
                ),
              )
            ],
          ),
          color: Color.fromRGBO(0, 0, 0, 0.3),
        ),
      );
    });
  }

  void closeEditStudentForm() {
    setState(() {
      _addFloatingButton = FloatingActionButton(
        onPressed: () {
          openAddStudentForm();
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.green,
      );

      tappedStudent = null;
      editStudent = null;
      _editStudentForm = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_addStudentForm != null) {
      openAddStudentForm();
    }
    if (_editStudentForm != null) {
      openEditStudentForm(tappedStudent);
    }
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Color.fromRGBO(22, 57, 68, 1),
      body: SafeArea(
          child: Stack(
        children: [
          Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: SizedBox(
                      height: 80,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          key: _formKey,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          onChanged: (value) async {
                            await search(value);
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'بحث',
                            hintStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 18.0,
                                fontFamily: 'HacenTunisiaLT'),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.white,
                            ),
                            filled: true,
                            fillColor: Color.fromRGBO(35, 35, 35, 1),
                          ),
                          autocorrect: false,
                          style: TextStyle(
                              color: Colors.white,
                              fontFamily: "HacenTunisiaLT",
                              decoration: TextDecoration.none,
                              fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: PopupMenuButton(
                      icon: new Icon(
                        Icons.list,
                        color: Colors.white,
                        size: 35,
                      ),
                      onSelected: (value) async {
                        if(value == 3){
                          await myDatabase.clearStudentTable();
                          getStudentListFromDB();
                          _scaffoldKey.currentState.showSnackBar(SnackBar(
                            content: Text("تم حذف القائمة بنجاح"),
                            duration: Duration(seconds: 2),
                          ));
                        }else{
                          if (await _requestPermission(Permission.storage)) {
                            if (value == 1) {
                              if (_studentsList.length > 0) {
                                if (await editor.saveFile()) {
                                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                                    content: Text("تم حفظ القائمة في ملف بنجاح"),
                                    duration: Duration(seconds: 3),
                                  ));
                                }
                              } else {
                                _scaffoldKey.currentState.showSnackBar(SnackBar(
                                  content: Text("القائمة فارغة"),
                                  duration: Duration(seconds: 3),
                                ));
                              }
                            } else if(value == 2){
                              List<Student> s = await editor.loadFile();
                              await myDatabase.clearStudentTable();
                              for (int i = s.length - 1; i >= 0; i--) {
                                await myDatabase.insertNewStudent(s.elementAt(i));
                              }
                              await getStudentListFromDB();
                              _scaffoldKey.currentState.showSnackBar(SnackBar(
                                content: Text("تم ملأ القائمة بنجاح"),
                                duration: Duration(seconds: 3),
                              ));
                            }
                          } else {
                            _scaffoldKey.currentState.showSnackBar(SnackBar(
                              content: Text(
                                  "يرجى السماح للتطبيق بتخزين الملفات في الذاكرة"),
                              duration: Duration(seconds: 2),
                            ));
                          }
                        }
                      },
                      itemBuilder: (context) {
                        var list = List<PopupMenuEntry<Object>>();
                        list.add(
                          PopupMenuItem(
                            child: SizedBox(
                              width: 135,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "حفظ القائمة في ملف",
                                      style: TextStyle(
                                        fontFamily: 'HacenTunisia',
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    flex: 9,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.save,
                                        color: Colors.black,
                                      ),
                                    ),
                                    flex: 1,
                                  )
                                ],
                              ),
                            ),
                            value: 1,
                          ),
                        );
                        list.add(
                          PopupMenuItem(
                            child: SizedBox(
                              width: 135,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "ملأ القائمة من ملف",
                                      style: TextStyle(
                                        fontFamily: 'HacenTunisia',
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    flex: 9,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.folder_open_outlined,
                                        color: Colors.black,
                                      ),
                                    ),
                                    flex: 1,
                                  )
                                ],
                              ),
                            ),
                            value: 2,
                          ),
                        );
                        list.add(
                          PopupMenuItem(
                            child: SizedBox(
                              width: 135,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "حذف القائمة",
                                      style: TextStyle(
                                        fontFamily: 'HacenTunisia',
                                      ),
                                      textAlign: TextAlign.right,
                                    ),
                                    flex: 9,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icon(
                                        Icons.delete,
                                        color: Colors.black,
                                      ),
                                    ),
                                    flex: 1,
                                  )
                                ],
                              ),
                            ),
                            value: 3,
                          ),
                        );
                        return list;
                      },
                    ),
                    /*new IconButton(
                icon: new Icon(Icons.list,color: Colors.white),
                onPressed: () { /* Your code */ },
              )*/
                  )
                ],
              ),
              Expanded(
                child:
                    ListView(children: _studentsList //getStudentListFromDB(),
                        ),
              )
            ],
          ),
          Center(
            child: _addStudentForm,
          ),
          Center(
            child: _editStudentForm,
          )
        ],
      )),
      floatingActionButton: _addFloatingButton,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
