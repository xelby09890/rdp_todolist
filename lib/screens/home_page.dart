import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseFirestore db = FirebaseFirestore.instance;
//List of stored tasks
  final List<String> tasks = <String>[];

//Checkboxes for tasks completed; true if tasks completed, false if not completed.
  final List<bool> checkboxes = List.generate(8, (index) => false);

//nameController captures user input from text field and returns the result
  TextEditingController nameController = TextEditingController();

  bool ischecked = false;

//addItemToList function to check the current item
  void addItemToList() async {
//Getting the actual text value
    final String taskName = nameController.text;

//Passing collection to the function where name is from nameController
    await db.collection('task').add({
      'name': taskName,
      'completed': false,
      'timestamp': FieldValue.serverTimestamp(),
    });
    setState(() {
      tasks.insert(0, taskName);
      checkboxes.insert(0, false);
    });
  }

  //removeItem function to remove the current item
  void removeItem(int index) async {
    //Get the task to be removed
    String taskToBeRemoved = tasks[index];

    //Remove the task from Firestore
    QuerySnapshot querySnapshot = await db
        .collection('tasks')
        .where('name', isEqualTo: taskToBeRemoved)
        .get();

    if (querySnapshot.size > 0) {
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];
      await documentSnapshot.reference.delete();
    }
    setState(() {
      tasks.removeAt(index);
      checkboxes.removeAt(index);
    });
  }

  Future<void> fetchTasksFromFirestore() async {
    //Get a reference to the 'tasks' collection from Firestore
    CollectionReference taskCollection = db.collection('tasks');

    //Fetch the documents (tasks) from the collection
    QuerySnapshot querySnapshot = await taskCollection.get();

    //Create an empty list to store the fetched task names
    List<String> fetchedTasks = [];

    //Look through each doc (tasks) in the querySnapshot object
    for (QueryDocumentSnapshot docSnapshot in querySnapshot.docs) {
      //Get the task name from the data
      String taskName = docSnapshot.get('name');

      //Get the completion status from the data
      bool completed = docSnapshot.get('completed');

      //Add the tasks to the fetched tasks
      fetchedTasks.add(taskName);
    }
    setState(() {
      tasks.clear();
      tasks.addAll(fetchedTasks);
    });
  }

  Future<void> updateTaskCompletionStatus(
      String taskName, bool completed) async {
    //Get a reference to the 'tasks collection from Firestore
    CollectionReference tasksCollection = db.collection('tasks');

    //Query firestore for tasks with the given task name
    QuerySnapshot querySnapshot =
        await tasksCollection.where('name', isEqualTo: taskName).get();

    //if matching document is found
    if (querySnapshot.size > 0) {
      //Getting a reference to the first matching document
      DocumentSnapshot documentSnapshot = querySnapshot.docs[0];

      await documentSnapshot.reference.update({'completed': true});
    }

    setState(() {
      //find the index of the task in the task list
      int taskIndex = tasks.indexWhere((task) => task == taskName);
      //Update the corresponding checkbox value in the checkbox list
      checkboxes[taskIndex] = completed;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTasksFromFirestore();
  }

  void clearInput() {
    setState(() {
      nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              height: 80,
              child: Image.asset('assets/rdplogo.png'),
            ),
            const Text(
              'Daily Planner',
              style: TextStyle(fontFamily: 'Caveat', fontSize: 32),
            ),
          ],
        ),
      ),
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TableCalendar(
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(color: Colors.blue),
                  weekNumberTextStyle: const TextStyle(color: Colors.red),
                  weekendTextStyle: const TextStyle(color: Colors.pink),
                  outsideDecoration: const BoxDecoration(color: Colors.blue),
                  tableBorder: TableBorder.all(
                      color: Theme.of(context).colorScheme.primaryContainer),
                ),
                calendarFormat: CalendarFormat.month,
                headerVisible: true,
                headerStyle: HeaderStyle(
                    decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.4),
                )),
                focusedDay: DateTime.now(),
                firstDay: DateTime(2023),
                lastDay: DateTime(2025),
              ),
              Container(
                height: 250,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (BuildContext context, int index) {
                    return SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.only(top: 3.0),
                        decoration: BoxDecoration(
                          color: checkboxes[index]
                              ? Colors.green.withOpacity(0.7)
                              : Colors.blue.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                    size: 44,
                                    !checkboxes[index]
                                        ? Icons.manage_history
                                        : Icons.playlist_add_check_circle),
                                const SizedBox(width: 18),
                                Expanded(
                                  child: Text(
                                    '${tasks[index]}',
                                    style: checkboxes[index]
                                        ? TextStyle(
                                            decoration:
                                                TextDecoration.lineThrough,
                                            fontSize: 25,
                                            color:
                                                Colors.black.withOpacity(0.5))
                                        : const TextStyle(fontSize: 25),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Transform.scale(
                                      scale: 1.3,
                                      child: Checkbox(
                                        value: checkboxes[index],
                                        onChanged: (newValue) {
                                          setState(
                                            () {
                                              checkboxes[index] = newValue!;
                                            },
                                          );
                                          updateTaskCompletionStatus(
                                              tasks[index], newValue!);
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      color: Colors.black,
                                      iconSize: 30,
                                      icon: const Icon(Icons.delete),
                                      onPressed: () {
                                        removeItem(index);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      child: TextField(
                        controller: nameController,
                        maxLength: 20,
                        decoration: InputDecoration(
                          labelText: 'Add To-Do List Item',
                          hintText: 'Enter your task here',
                          hintStyle:
                              TextStyle(color: Colors.grey.withOpacity(0.5)),
                          labelStyle: TextStyle(
                            fontSize: 18,
                            color: Colors.blue.withOpacity(0.5),
                          ),
                          contentPadding: const EdgeInsets.all(23),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: null,
                    //To-do create a cleatTextField()
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(3.0),
                child: ElevatedButton(
                  style: const ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.green)),
                  onPressed: () {
                    addItemToList();
                    clearInput();
                  },
                  child: const Text(
                    'Add To-Do List Item',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
