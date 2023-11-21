import 'package:broutine_app/collections/category.dart';
import 'package:broutine_app/collections/product.dart';
import 'package:broutine_app/collections/routine.dart';
import 'package:broutine_app/config.dart';
import 'package:broutine_app/rest_api/https_server.dart';
import 'package:broutine_app/screens/create_routine.dart';
import 'package:broutine_app/screens/update_routine.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final dir = await getApplicationSupportDirectory();
  if (dir.existsSync()) {
    final isar = await Isar.open([RoutineSchema, CategorySchema, ProductSchema],
        directory: dir.path);
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
  HttpService httpService = HttpService();

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
            icon: const Icon(Icons.add),
          ),
          IconButton(
            onPressed: () {
              _apitoisar();
            },
            icon: const Icon(Icons.download),
          ),
          IconButton(
            onPressed: () {
              _isartoapi();
            },
            icon: const Icon(Icons.upload),
          ),
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
            FutureBuilder<List<Product>>(
                future: generateProducts(),
                builder: ((context, snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data!.isNotEmpty) {
                      return GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const ScrollPhysics(),
                          children:
                              List.generate(snapshot.data!.length, (index) {
                            return Card(
                              elevation: 4.0,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.4,
                                        height: 90,
                                        child: Image.network(
                                          snapshot.data![index].image!,
                                          fit: BoxFit.fitHeight,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          snapshot.data![index].title!,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      ElevatedButton(
                                          onPressed: () {},
                                          child: const Text("View"))
                                    ]),
                              ),
                            );
                          }));
                    } else {
                      return const SizedBox();
                    }
                  } else {
                    return const SizedBox();
                  }
                }))
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

  _apitoisar() async {
    httpService
        .init(BaseOptions(baseUrl: baseUrl, contentType: "application/json"));
    final response = await httpService.request(
        endpoint: "products?limit=9", method: Method.GET);

    List<Map<String, dynamic>>? products = (response.data as List)
        .map((item) => item as Map<String, dynamic>)
        .toList();
    await widget.isar.writeTxn(() async {
      await widget.isar.products.clear();
      await widget.isar.products.importJson(products);
    });
  }

  Future<List<Product>> generateProducts() async {
    List<Product> getProducts = await widget.isar.products.where().findAll();
    return getProducts;
  }

  _isartoapi() async {
    final prodt = await widget.isar.products.where().findAll();
    List<Map<String, dynamic>>? listProducts =
        prodt.map((e) => e.toJson()).toList();
    httpService.init(BaseOptions(baseUrl: serverUrl));
    Map<String, dynamic> params = {'products': listProducts};
    final response = await httpService.request(
        endpoint: "/products", method: Method.POST, params: params);
    Logger().i(response);
  }
}
