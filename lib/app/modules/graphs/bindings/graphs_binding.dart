import 'package:get/get.dart';

import '../controllers/graphs_controller.dart';

class GraphsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GraphsController>(
      () => GraphsController(),
    );
  }
}
