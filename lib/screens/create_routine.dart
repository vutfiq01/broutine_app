import 'package:broutine_app/collections/category.dart';
import 'package:broutine_app/collections/routine.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

class CreateRoutine extends StatefulWidget {
  final Isar isar;
  const CreateRoutine({
    super.key,
    required this.isar,
  });

  @override
  State<CreateRoutine> createState() => _CreateRoutineState();
}

class _CreateRoutineState extends State<CreateRoutine> {
  List<Category>? categories;
  Category? dropdownValue;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _newCategoryController = TextEditingController();
  List<String> days = [
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday"
  ];
  String dropdownDay = "monday";
  TimeOfDay selectedTime = TimeOfDay.now();

  @override
  void initState() {
    _readCategory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      appBar: AppBar(title: const Text("Create Routine")),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text(
              "Category",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: DropdownButton(
                    focusColor: const Color(0xffffffff),
                    dropdownColor: const Color(0xffffffff),
                    isExpanded: true,
                    value: dropdownValue,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: categories
                        ?.map<DropdownMenuItem<Category>>((Category nvalue) {
                      return DropdownMenuItem<Category>(
                          value: nvalue, child: Text(nvalue.name));
                    }).toList(),
                    onChanged: (Category? newValue) {
                      setState(() {
                        dropdownValue = newValue!;
                      });
                    },
                  ),
                ),
                IconButton(
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => AlertDialog(
                                title: const Text("New Category"),
                                content: TextFormField(
                                    controller: _newCategoryController),
                                actions: [
                                  ElevatedButton(
                                      onPressed: () {
                                        _addCategory(widget.isar);
                                      },
                                      child: const Text("Add"))
                                ],
                              ));
                    },
                    icon: const Icon(Icons.add))
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child:
                  Text("Title", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            TextFormField(
              controller: _titleController,
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text("Start Time",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.7,
                  child: TextFormField(
                    controller: _timeController,
                    enabled: false,
                  ),
                ),
                IconButton(
                    onPressed: () {
                      _selectedTime(context);
                    },
                    icon: const Icon(Icons.calendar_month))
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 10.0),
              child: Text("Day", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              child: DropdownButton(
                isExpanded: true,
                value: dropdownDay,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: days.map<DropdownMenuItem<String>>((String day) {
                  return DropdownMenuItem<String>(value: day, child: Text(day));
                }).toList(),
                onChanged: (String? newDay) {
                  setState(() {
                    dropdownDay = newDay!;
                  });
                },
              ),
            ),
            Align(
                alignment: Alignment.center,
                child: ElevatedButton(
                    onPressed: () {
                      addRoutine();
                    },
                    child: const Text("Add")))
          ]),
        ),
      ),
    );
  }

  _selectedTime(BuildContext context) async {
    final TimeOfDay? timeOfDay = await showTimePicker(
        context: context,
        initialTime: selectedTime,
        initialEntryMode: TimePickerEntryMode.dial);

    if (timeOfDay != null && timeOfDay != selectedTime) {
      selectedTime = timeOfDay;
      setState(() {
        _timeController.text =
            "${selectedTime.hour.toString()}:${selectedTime.minute.toString()} ${selectedTime.period.name}";
      });
    }
  }

  _addCategory(Isar isar) async {
    final categories = isar.categorys;

    final newCategory = Category()..name = _newCategoryController.text;

    await isar.writeTxn<int>(() async => await categories.put(newCategory));
    _newCategoryController.clear();
    _readCategory();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  _readCategory() async {
    final categoryCollection = widget.isar.categorys;
    final getCategories = await categoryCollection.where().findAll();
    if (getCategories.isNotEmpty) {
      setState(() {
        categories = getCategories;
        dropdownValue = categories!.first; // Set the first category as default
      });
    } else {
      setState(() {
        categories = [];
        dropdownValue = null;
      });
    }
  }

  addRoutine() async {
    final routineCollection = widget.isar.routines;
    final newRoutine = Routine()
      ..title = _titleController.text
      ..startTime = _timeController.text
      ..day = dropdownDay;
    if (dropdownValue != null) {
      newRoutine.category.value = dropdownValue; // Linking the category
      print('not null');
    }

    await widget.isar
        .writeTxn<int>(() async => await routineCollection.put(newRoutine));

    _titleController.clear();
    _timeController.clear();
    dropdownDay = 'monday';
    dropdownValue = null;
    if (mounted) {
      Navigator.pop(context);
    }
  }
}
