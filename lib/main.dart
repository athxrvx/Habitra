import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(HabitTrackerApp());

class HabitTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.white),
      ),
      home: HomeScreen(),
    );
  }
}

class Habit {
  String name;
  int count;
  IconData icon;
  Habit(this.name, this.count, this.icon);
}

class Task {
  String name;
  DateTime due;
  int importance;
  Color status;
  Task(this.name, this.due, this.importance, this.status);
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<List<bool>> grid = List.generate(3, (_) => List.generate(10, (_) => false));
  List<Habit> habits = [
    Habit("HABIT 1", 0, Icons.language),
    Habit("HABIT 2", 0, Icons.play_circle_outline),
    Habit("HABIT 3", 0, Icons.build),
    Habit("HABIT 4", 0, Icons.headset),
  ];
  List<Task> tasks = [];

  void toggleGrid(int r, int c) {
    setState(() => grid[r][c] = !grid[r][c]);
  }

  void incrementHabit(int i) {
    setState(() => habits[i].count++);
  }

  void updateTask(Task t, Color c) {
    setState(() {
      t.status = c;
      _sortTasks();
    });
  }

  void _sortTasks() {
    tasks.sort((a, b) {
      int rank(Color s) {
        if (s == Colors.white) return 0;
        if (s == Colors.red) return 1;
        return 2;
      }
      return rank(a.status).compareTo(rank(b.status));
    });
  }

  Future<void> addTask() async {
    String name = "";
    DateTime? due;
    int imp = 1;

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text("New Task", style: TextStyle(fontSize: 20)),
            SizedBox(height: 12),
            TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: TextStyle(color: Colors.grey),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              onChanged: (v) => name = v,
            ),
            SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                DateTime? d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => due = d);
              },
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey)),
                ),
                child: Text(
                  due == null ? "Select due date..." : "${due!.day}/${due!.month}/${due!.year}",
                  style: TextStyle(color: due == null ? Colors.grey : Colors.white),
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Importance (1–5)",
                labelStyle: TextStyle(color: Colors.grey),
                border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
              ),
              keyboardType: TextInputType.number,
              onChanged: (v) => imp = int.tryParse(v) ?? 1,
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF2A2A2A)),
                onPressed: () {
                  if (name.isNotEmpty && due != null) {
                    tasks.add(Task(name, due!, imp, Colors.white));
                    _sortTasks();
                  }
                  Navigator.pop(context);
                },
                child: Text("Add"),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> exportMD() async {
    final sb = StringBuffer("# Habit Tracker Export\n\n");

    sb.writeln("## Grid");
    for (final row in grid) {
      sb.write("| ");
      for (final b in row) sb.write("${b ? "✅" : "⬜"} | ");
      sb.writeln();
    }
    sb.writeln("\n## Habits");
    for (final h in habits) sb.writeln("- ${h.name}: ${h.count} days");
    sb.writeln("\n## Tasks");
    for (final t in tasks) {
      sb.writeln(
          "- ${t.name} (Due: ${t.due.toIso8601String().split('T')[0]}, Importance: ${t.importance}) – ${t.status == Colors.green ? "✅" : t.status == Colors.red ? "❌" : "🟡"}");
    }

    if (await Permission.storage.request().isGranted) {
      final dir = await getApplicationDocumentsDirectory();
      final file = File("${dir.path}/export.md");
      await file.writeAsString(sb.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Exported to ${file.path}")));
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: List.generate(3, (r) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(10, (c) {
                          bool active = grid[r][c];
                          return GestureDetector(
                            onTap: () => toggleGrid(r, c),
                            child: AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              margin: EdgeInsets.all(4),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: active ? Color(0xFF61E379) : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.5,
                    physics: NeverScrollableScrollPhysics(),
                    children: List.generate(habits.length, (i) {
                      final h = habits[i];
                      return GestureDetector(
                        onTap: () => incrementHabit(i),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Color(0xFF1E1E1E),
                                child: Icon(h.icon, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h.name, style: TextStyle(fontSize: 14)),
                                  Text("${h.count} DAYS",
                                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 24),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text("TASKS", style: TextStyle(fontSize: 18))),
                SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: tasks.isEmpty
                        ? Center(child: Text("No tasks yet", style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            itemCount: tasks.length,
                            separatorBuilder: (_, __) => SizedBox(height: 12),
                            itemBuilder: (_, i) {
                              final t = tasks[i];
                              return Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text("Task : ${t.name}",
                                              style: TextStyle(fontSize: 14)),
                                          Text(
                                              "Due Date : ${t.due.day}/${t.due.month}/${t.due.year}",
                                              style: TextStyle(fontSize: 12)),
                                          Text("Importance: level ${t.importance}",
                                              style: TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => updateTask(t, Colors.green),
                                      onDoubleTap: () => updateTask(t, Colors.red),
                                      onLongPress: () => updateTask(t, Colors.white),
                                      child: AnimatedContainer(
                                        duration: Duration(milliseconds: 200),
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: t.status,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Stack(children: [
        Positioned(
          bottom: 24,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              backgroundColor: Color(0xFF2A2A2A),
              child: Icon(Icons.add, size: 32),
              onPressed: addTask,
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton.extended(
            backgroundColor: Color(0xFF2A2A2A),
            label: Text("export"),
            icon: Icon(Icons.download, size: 20),
            onPressed: exportMD,
          ),
        ),
      ]),
    );
  }
}
