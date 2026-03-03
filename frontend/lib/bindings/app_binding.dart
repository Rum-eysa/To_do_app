import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/todo_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<TodoController>(() => TodoController());
  }
}
