import 'package:broutine_app/collections/category.dart';
import 'package:isar/isar.dart';

part 'routine.g.dart';

@Collection()
class Routine {
  Id id = Isar.autoIncrement;

  @Index()
  String? title;

  @Index()
  String? startTime;

  @Index(caseSensitive: false)
  String? day;

  @Index(composite: [CompositeIndex('title')])
  final category = IsarLink<Category>();
}
