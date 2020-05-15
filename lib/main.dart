import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'bible.dart';
import 'datePicker.dart';
import 'nextButton.dart';

const String BOOKS_SELECTED = "BOOKS_SELECTED";
const String DATE_SELECTED = "DATE_SELECTED";

const String BOOK_NAME_KEY = 'n';

void main() {
  debugPaintSizeEnabled = true;
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Bible Challenge',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => new HomePage(),
        '/selectBook': (context) => new SelectBookPage(),
        '/selectDate': (context) => new SelectDatePage(),
      }
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            Expanded(
              child: Text('Hello'),
            ),
            Align(
              alignment: FractionalOffset.bottomCenter,
              child: NextButton(
                text: 'Create new challenge!',
                next: '/selectBook',
              ),
            )
          ]
        )
      )
    );
  }
}

class SelectBookPage extends StatefulWidget {
  @override
  _SelectBookState createState() => new _SelectBookState();
}

class _SelectBookState extends State<SelectBookPage> {
  List<String> bookNames = new List();
  HashSet<String> bookChecked = new HashSet<String>();
  DatabaseHelper db = new DatabaseHelper();

  @override
  void initState() {
    super.initState();
    db.fetchBooks().then((books) {
      setState(() {
        books.forEach((book) {
          bookNames.add(book[BOOK_NAME_KEY]);
        });
      });
    });
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        if (prefs.getStringList(BOOKS_SELECTED) != null) {
          bookChecked.addAll(prefs.getStringList(BOOKS_SELECTED));
        }
      });
    });
  }

  void toggleBook(String book) {
    setState(() {
      if (bookChecked.contains(book)) {
        bookChecked.remove(book);
      } else {
        bookChecked.add(book);
      }
      SharedPreferences.getInstance().then((prefs) {
        prefs.setStringList(BOOKS_SELECTED, bookChecked.toList());
      });
    });
  }

  Widget bookListItem(BuildContext context, int index) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        print('Row tapped');
        toggleBook(bookNames[index]);
      },
      child: Row(
        children: <Widget>[
          Checkbox(
            value: bookChecked.contains(bookNames[index]),
          ),
          Text('${bookNames[index]}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose which books to read'),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Expanded(
            child: ListView.builder(
                itemCount: bookNames.length,
                padding: const EdgeInsets.all(5.0),
                itemBuilder: bookListItem,
            ),
          ),
          Align(
            alignment: FractionalOffset.bottomCenter,
            child: NextButton(
              next: '/selectDate'
            ),
          )
        ],
      ),
    );
  }
}

class SelectDatePage extends StatefulWidget {
  SelectDatePage({Key key}) : super(key: key);
  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  @override
  _SelectDateState createState() => new _SelectDateState();
}

class _SelectDateState extends State<SelectDatePage> {
  DateTime _finishDate = DateTime.now();

  void getFinishDate() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String date = prefs.getString(DATE_SELECTED);
    DateTime finishDate = DateTime.now();
    if (date != '') {
      finishDate = DateTime.parse(date);
    }
    setState(() {
      _finishDate = finishDate;
    });
  }

  @override
  Widget build(BuildContext context) {
    getFinishDate();
    return new Scaffold(
      appBar: AppBar(
        title: Text('Schedule finish date'),
      ),
      body: new Center(
        child: new Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(
              child: Center(
                child: DropdownButtonHideUnderline(
                  child: DatePicker(
                  labelText: '',
                    selectedDate: _finishDate,
                    selectDate: (DateTime date) {
                      SharedPreferences.getInstance().then((prefs) {
                        prefs.setString(DATE_SELECTED, date.toString());
                        getFinishDate();
                      });
                    },
                  ),
                ),
              )
            ),
            Align(
              alignment: FractionalOffset.bottomCenter,
              child: NextButton(
                text: 'Finish',
                next: '/',
              ),
            )
          ]
        ),
      ),
    );
  }
}
