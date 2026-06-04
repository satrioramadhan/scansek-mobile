import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/reminders_controller.dart';

class RemindersView extends GetView<RemindersController> {
  const RemindersView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RemindersView'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'RemindersView is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
