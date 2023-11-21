import 'package:broutine_app/collections/category.dart';
import 'package:broutine_app/collections/routine.dart';
import 'package:broutine_app/screens/create_routine.dart';
import 'package:broutine_app/screens/update_routine.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  if (dir.existsSync()) {
    final isar =
        await Isar.open([RoutineSchema, CategorySchema], directory: dir.path);
    runApp(MyApp(isar: isar));
  }
}

class MyApp extends StatelessWidget {
  final Isar isar;
  const MyApp({
    super.key,
    required this.isar,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BRoutine App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MainPage(
        isar: isar,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  final Isar isar;
  const MainPage({
    super.key,
    required this.isar,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  List<Routine>? routines;
  final TextEditingController _searchController = TextEditingController();
  bool searching = false;
  String feedback = "";
  MaterialColor feedbackColor = Colors.blue;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Routine"),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => CreateRoutine(
                              isar: widget.isar,
                            )));
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                  onChanged: searchRoutineByName,
                  controller: _searchController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(
                          borderSide: BorderSide(style: BorderStyle.solid)),
                      hintText: "Search routine",
                      hintStyle: TextStyle(fontStyle: FontStyle.italic))),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                feedback,
                style: TextStyle(
                    color: feedbackColor, fontStyle: FontStyle.italic),
              ),
            ),
            FutureBuilder(
              future: _buildWidgets(),
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                if (snapshot.hasData) {
                  return Column(
                    children: snapshot.data,
                  );
                } else {
                  return Container();
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
            height: 50,
            child: ElevatedButton(
                onPressed: () {
                  clearAll();
                },
                child: const Text("Clear all"))),
      ),
    );
  }

  Future<List<Widget>> _buildWidgets() async {
    createWatcher();
    if (!searching) {
      await _readRoutines();
    }

    List<Widget> x = [];

    for (int i = 0; i < routines!.length; i++) {
      x.add(Card(
        elevation: 4.0,
        child: ListTile(
            onLongPress: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UpdateRoutine(
                    isar: widget.isar,
                    routine: routines![i],
                  ),
                ),
              );
            },
            title:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(top: 5.0, bottom: 2.0),
                child: Text(
                  routines![i].title!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: RichText(
                    text: TextSpan(
                        style: const TextStyle(color: Colors.black),
                        children: [
                      const WidgetSpan(child: Icon(Icons.schedule, size: 16)),
                      TextSpan(text: routines![i].startTime)
                    ])),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: RichText(
                    text: TextSpan(
                        style:
                            const TextStyle(color: Colors.black, fontSize: 12),
                        children: [
                      const WidgetSpan(
                          child: Icon(
                        Icons.calendar_month,
                        size: 16,
                      )),
                      TextSpan(text: routines![i].day)
                    ])),
              )
            ]),
            trailing: const Icon(Icons.keyboard_arrow_right)),
      ));
    }
    return x;
  }

  _readRoutines() async {
    final routineCollection = widget.isar.routines;
    final getRoutines = await routineCollection.where().findAll();
    setState(() {
      routines = getRoutines;
    });
  }

  searchRoutineByName(String searchName) async {
    searching = true;
    final routineCollection = widget.isar.routines;
    final searchResults = await routineCollection
        .filter()
        .titleContains(searchName, caseSensitive: false)
        .findAll();
    setState(() {
      routines = searchResults;
    });
  }

  clearAll() async {
    final routineCollection = widget.isar.routines;
    final getRoutines = await routineCollection.where().findAll();

    await widget.isar.writeTxn(() async {
      for (var routine in getRoutines) {
        routineCollection.delete(routine.id);
      }
    });

    setState(() {});
  }

  createWatcher() {
    Query<Routine> getTasks = widget.isar.routines.where().build();

    Stream<List<Routine>> queryChanged = getTasks.watch(fireImmediately: true);
    queryChanged.listen((routines) {
      if (routines.length > 3) {
        setState(() {
          feedback = "You have more than 3 tasks to do";
          feedbackColor = Colors.red;
        });
      } else {
        feedback = "You are right on track";
        feedbackColor = Colors.blue;
      }
    });
  }
}
