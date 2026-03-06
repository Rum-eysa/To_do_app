import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/todo_controller.dart';
import '../services/api_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ApiService>(() => ApiService());
    Get.lazyPut<AuthController>(() => AuthController());
    Get.lazyPut<TodoController>(() => TodoController());
  }
}
