// ignore_for_file: constant_identifier_names

import 'package:afs_task/core/constants/string_constants.dart';
import 'package:afs_task/core/style/style_constants/color_constants.dart';
import 'package:afs_task/data/local_storage.dart';
import 'package:afs_task/models/response.dart';
import 'package:afs_task/models/task.dart';
import 'package:afs_task/modules/tasks/providers/tasks_list_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

enum TasksBottomsheetState {
  INITIALIZING,
  INITIALIZED,
  LOADING,
  FAILED,
  SUCCEEDED
}

class TasksBottomsheetProvider extends ChangeNotifier {
  //make singleton
  TasksBottomsheetProvider._privateConstructor();
  static final TasksBottomsheetProvider _instance =
      TasksBottomsheetProvider._privateConstructor();
  factory TasksBottomsheetProvider() {
    return _instance;
  }

  TasksBottomsheetState state = TasksBottomsheetState.INITIALIZING;

  late TasksBottomsheetProvider tasksBottomsheetProvider;
  late TasksListProvider tasksListProvider;
  var taskTitleController = TextEditingController();
  var taskDescriptionController = TextEditingController();
  var taskFormKey = GlobalKey<FormState>();
  var isCompleteTask = false;
  Task? editedTask;
  Response? latestResponse;
  bool isBottomSheetOpened = false;

  init(BuildContext context) {
    tasksListProvider = Provider.of<TasksListProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback(
        (_) => updateState(TasksBottomsheetState.INITIALIZED));
  }

  setTask() async {
    if (taskFormKey.currentState!.validate()) {
      updateState(TasksBottomsheetState.LOADING);
      if (editedTask == null) {
        // Add New Task
        latestResponse = await LocalStorage.addTask(Task(
            title: taskTitleController.text,
            description: taskDescriptionController.text,
            isCompleted: isCompleteTask));
      } else {
        // Update Task
        editedTask!.title = taskTitleController.text;
        editedTask!.description = taskDescriptionController.text;
        editedTask!.isCompleted = isCompleteTask;
        latestResponse = await LocalStorage.updateTask(editedTask!);
        if (latestResponse!.isOperationSuccessful) {
          isBottomSheetOpened = false;
        }
      }
      if (latestResponse!.isOperationSuccessful) {
        tasksListProvider.updateState(TasksListState.RELOADING);
        updateState(TasksBottomsheetState.SUCCEEDED);
      } else {
        updateState(TasksBottomsheetState.FAILED);
      }
    }
  }

  updateState(TasksBottomsheetState state) {
    this.state = state;
    notifyListeners();
  }

  updateTask()async{

  }

  validateTaskTitle() {
    if (taskTitleController.text.isEmpty) {
      return StringConstants.taskTitleFieldError;
    }
    return null;
  }

  validateTaskDescription() {
    if (taskDescriptionController.text.isEmpty) {
      return StringConstants.taskDescriptionFieldError;
    }
    return null;
  }

  open({Task? task}) {
    _setStateData(task: task);
    isBottomSheetOpened = true;
    notifyListeners();
  }

  edit(Task? task)async{
    _setStateData(task: task);
    isBottomSheetOpened = false;
    editedTask!.isCompleted = true;
    latestResponse = await LocalStorage.updateTask(editedTask!);
    notifyListeners();
  }

  close() {
    isBottomSheetOpened = false;
    _setStateData();
    updateState(TasksBottomsheetState.INITIALIZED);
  }

  toggleBottomSheet() {
    isBottomSheetOpened ? close() : open();
  }

  setUrgentTask(bool? value) {
    if (value != null) {
      isCompleteTask = value;
      notifyListeners();
    }
  }

  _setStateData({Task? task}) {
    editedTask = task;
    if (editedTask != null) {
      taskTitleController.text = editedTask!.title;
      taskDescriptionController.text = editedTask!.description;
      isCompleteTask = editedTask!.isCompleted;
    } else {
      taskTitleController.text = '';
      taskDescriptionController.text = '';
      isCompleteTask = false;
      editedTask = null;
      if (latestResponse != null) {
        latestResponse!.message = '';
      }
    }
  }

  reinitialzeState(BuildContext context) {
    if (latestResponse != null && latestResponse!.message.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: ColorConstants.kPrimaryColor,
          content: Text(latestResponse!.message),
        ));
        _setStateData();
        updateState(TasksBottomsheetState.INITIALIZED);
      });
    }
  }
}
