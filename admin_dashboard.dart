import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_development_app/services/api_service.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _menuFormKey = GlobalKey<FormState>();
  final _courseFormKey = GlobalKey<FormState>();
  final _contentFormKey = GlobalKey<FormState>();
  final _jobsFormKey = GlobalKey<FormState>();

  final courseNameController = TextEditingController();
  final catController = TextEditingController();
  final typeController = TextEditingController();
  final statusController = TextEditingController();

  final TextEditingController _courseNameController = TextEditingController();
  final TextEditingController _quizTitleController = TextEditingController();
  final List<Map<String, dynamic>> _questions = [];
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _optionAController = TextEditingController();
  final TextEditingController _optionBController = TextEditingController();
  final TextEditingController _optionCController = TextEditingController();
  final TextEditingController _optionDController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  final courseName2Controller = TextEditingController();
  final durationController = TextEditingController();
  final status2Controller = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final jobTitleController = TextEditingController();
  final companyController = TextEditingController();
  final locationController = TextEditingController();
  final jobTypeController = TextEditingController();
  final applyLinkController = TextEditingController();
  String? selectedJobStatus;

  List<String> categories = [];
  List<String> type = [];
  String userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchUserDetails(); // Fetch user details when the widget is initialized
    _fetchCategories(); // Fetch categories when the widget is initialized
  }

  Future<void> fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString("email") ?? "No email found";
    });
  }

  // Fetch categories and types from API
  Future<void> _fetchCategories() async {
    try {
      // Fetch categories
      List<String> fetchedCategories = await ApiService.fetchCategories();
      setState(() {
        categories = fetchedCategories;
      });

      // If a category is selected, fetch its types
      if (selectedCategory != null) {
        _fetchTypesForCategory(selectedCategory!);
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> _fetchTypesForCategory(String category) async {
    try {
      // Fetch types for the selected category
      List<String> fetchedTypes = await ApiService.fetchTypesForCategory(
        category,
      );

      // ✅ Convert to Set to remove duplicates, then back to List
      List<String> uniqueTypes = fetchedTypes.toSet().toList();

      setState(() {
        type = uniqueTypes; // <-- assign unique list
        selectedType = null; // Reset selected type
      });
    } catch (e) {
      print("Error fetching types for $category: $e");
    }
  }

  List<String> statusOptions = ['True', 'False'];
  String? selectedCategory;
  String? selectedType;
  String? selectedStatus;
  String? selectedStatus2;
  String? selectedCourseForContent;

  List<Map<String, TextEditingController>> courseTopics = [
    {
      'topic_title': TextEditingController(),
      'video_url': TextEditingController(),
    },
  ];

  final String backendBaseUrl = "http://127.0.0.1:5000";

  Future<void> submitMenuData() async {
    final url = Uri.parse("$backendBaseUrl/menus");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "category": selectedCategory,
          "type": selectedType,
          "course_name": courseNameController.text.trim(),
          "status": selectedStatus,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Menu added successfully!")));
      } else {
        print("Menu Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Menu Exception: $e");
    }
  }

  Future<void> submitCourseData() async {
    final url = Uri.parse("$backendBaseUrl/courses");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "course_name": courseName2Controller.text.trim(),
          "title": titleController.text.trim(),
          "description": descriptionController.text.trim(),
          "status": selectedStatus2,
          "duration": durationController.text.trim(),
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Course added successfully!")));
      } else {
        print("Course Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Course Exception: $e");
    }
  }

  Future<void> submitCourseContent() async {
    final url = Uri.parse("$backendBaseUrl/submit_course_content");

    // Convert topic controllers to a clean list
    List<Map<String, String>> topics =
        courseTopics.map((topic) {
          return {
            "topic_title": topic['topic_title']!.text.trim(),
            "video_url": topic['video_url']!.text.trim(),
          };
        }).toList();

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "course_name":
              selectedCourseForContent, // ✅ send it separately, not inside each topic
          "topics": topics,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Course content added successfully!")),
        );
        setState(() {
          // Reset form
          courseTopics = [
            {
              'topic_title': TextEditingController(),
              'video_url': TextEditingController(),
            },
          ];
        });
      } else {
        print("Content Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Content Exception: $e");
    }
  }

  Future<void> submitJobData() async {
    final url = Uri.parse("$backendBaseUrl/jobs");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: json.encode({
          "job_title": jobTitleController.text.trim(),
          "company_name": companyController.text.trim(),
          "job_location": locationController.text.trim(),
          "job_type": jobTypeController.text.trim(),
          "apply_link": applyLinkController.text.trim(),
          "status": selectedJobStatus,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Job added successfully!")));
        _jobsFormKey.currentState?.reset();
      } else {
        print("Job Error: ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      print("Job Exception: $e");
    }
  }

  String? validate(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return "Please enter $fieldName";
    }
    return null;
  }

Future<void> _submitQuiz() async {
  final String courseName = _courseNameController.text.trim();
  final String quizTitle = _quizTitleController.text.trim();

  // 🛡️ Check if fields are filled
  if (courseName.isEmpty || quizTitle.isEmpty || _questions.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please fill all fields and add questions.")),
    );
    return;
  }

  try {
    final response = await http.post(
      Uri.parse("$backendBaseUrl/add_quiz"), // 🔁 Replace with your PC's IP address
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "course_name": courseName,
        "quiz_title": quizTitle,
        "questions": _questions,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Quiz added successfully!")),
      );
      _courseNameController.clear();
      _quizTitleController.clear();
      _questions.clear();
      setState(() {}); // Refresh UI if needed
    } else {
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add quiz: ${response.body}")),
      );
    }
  } catch (e) {
    print("Exception: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  void _addQuestion() {
    if (_questionController.text.isEmpty ||
        _optionAController.text.isEmpty ||
        _optionBController.text.isEmpty ||
        _optionCController.text.isEmpty ||
        _optionDController.text.isEmpty ||
        _answerController.text.isEmpty) {
      return;
    }

    _questions.add({
      "question": _questionController.text.trim(),
      "options": [
        _optionAController.text.trim(),
        _optionBController.text.trim(),
        _optionCController.text.trim(),
        _optionDController.text.trim(),
      ],
      "answer": _answerController.text.trim(),
    });

    _questionController.clear();
    _optionAController.clear();
    _optionBController.clear();
    _optionCController.clear();
    _optionDController.clear();
    _answerController.clear();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 8,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromARGB(255, 19, 105, 97),
                Color.fromARGB(255, 13, 94, 86),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/logo2.png',
              height: 80,
              width: 80,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text("Welcome!"),
              accountEmail: Text(userEmail),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  color: const Color.fromARGB(255, 19, 105, 97),
                  size: 32,
                ),
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
            ),
            ListTile(
              leading: Icon(
                Icons.settings,
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
              title: Text("Course Setting", style: TextStyle(fontSize: 16)),
              onTap: () {
                context.push('/manage-course-content');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.category_rounded,
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
              title: Text("Category Setting", style: TextStyle(fontSize: 16)),
              onTap: () {
                context.push('/manage-category-type');
              },
            ),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
              title: Text("Logout", style: TextStyle(fontSize: 16)),
              onTap: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                context.go('/login');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Logged out successfully!")),
                );
              },
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// MENU FORM
                Text(
                  "Menu Category Form",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 19, 105, 97),
                  ),
                ),
                SizedBox(height: 12),
                Form(
                  key: _menuFormKey,
                  child: Column(
                    children: [
                      // ✅ Category Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            categories
                                .map(
                                  (cat) => DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(cat),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) async {
                          setState(() {
                            selectedCategory = value;
                            selectedType = null;
                            type = []; // Reset types
                          });
                          if (value != null) {
                            await _fetchTypesForCategory(value);
                          }
                        },
                        validator:
                            (value) =>
                                value == null
                                    ? 'Please select a category'
                                    : null,
                      ),

                      SizedBox(height: 12),

                      // Type Dropdown
                      DropdownButtonFormField<String>(
                        value:
                            type.contains(selectedType) ? selectedType : null,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            type
                                .map(
                                  (type) => DropdownMenuItem<String>(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged:
                            type.isNotEmpty
                                ? (value) {
                                  setState(() {
                                    selectedType = value;
                                  });
                                }
                                : null,
                        validator:
                            (value) =>
                                value == null ? 'Please select a type' : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: courseNameController,
                        decoration: InputDecoration(
                          labelText: 'Course Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Course Name'),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            statusOptions
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value;
                          });
                        },
                        validator:
                            (value) =>
                                value == null ? 'Please select a status' : null,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_menuFormKey.currentState!.validate()) {
                            submitMenuData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            19,
                            105,
                            97,
                          ),
                        ),
                        child: Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                /// COURSE FORM
                SizedBox(height: 30),
                Text(
                  "Courses Form",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 19, 105, 97),
                  ),
                ),
                SizedBox(height: 12),
                Form(
                  key: _courseFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: courseName2Controller,
                        decoration: InputDecoration(
                          labelText: 'Course Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Course Name'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: durationController,
                        decoration: InputDecoration(
                          labelText: 'Duration',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Duration'),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedStatus2,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            statusOptions
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus2 = value;
                          });
                        },
                        validator:
                            (value) =>
                                value == null ? 'Please select a status' : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Title'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (val) => validate(val, 'Description'),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_courseFormKey.currentState!.validate()) {
                            submitCourseData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            19,
                            105,
                            97,
                          ),
                        ),
                        child: Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                /// COURSE CONTENT FORM
                SizedBox(height: 30),
                Text(
                  "Course Content Form",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 19, 105, 97),
                  ),
                ),
                SizedBox(height: 12),
                Form(
                  key: _contentFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedCourseForContent,
                        decoration: InputDecoration(
                          labelText: 'Select Course',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            [courseName2Controller.text.trim()]
                                .where((name) => name.isNotEmpty)
                                .map(
                                  (name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCourseForContent = value;
                          });
                        },
                        validator:
                            (val) =>
                                val == null || val.isEmpty
                                    ? 'Please select a course'
                                    : null,
                      ),
                      SizedBox(height: 16),
                      ...courseTopics.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, TextEditingController> topic = entry.value;
                        return Column(
                          children: [
                            TextFormField(
                              controller: topic['topic_title'],
                              decoration: InputDecoration(
                                labelText: 'Topic Title ${index + 1}',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => validate(val, 'Topic Title'),
                            ),
                            SizedBox(height: 8),
                            TextFormField(
                              controller: topic['video_url'],
                              decoration: InputDecoration(
                                labelText: 'Video URL ${index + 1}',
                                border: OutlineInputBorder(),
                              ),
                              validator: (val) => validate(val, 'Video URL'),
                            ),
                            SizedBox(height: 16),
                          ],
                        );
                      }),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                courseTopics.add({
                                  'topic_title': TextEditingController(),
                                  'video_url': TextEditingController(),
                                });
                              });
                            },
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text(
                              "Add Topic",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                19,
                                105,
                                97,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (_contentFormKey.currentState!.validate()) {
                                submitCourseContent();
                              }
                            },
                            child: Text(
                              "Submit Content",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                19,
                                105,
                                97,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                const Text(
                  "Add Quiz",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _courseNameController,
                  decoration: const InputDecoration(labelText: "Course Name"),
                ),
                TextField(
                  controller: _quizTitleController,
                  decoration: const InputDecoration(labelText: "Quiz Title"),
                ),
                const SizedBox(height: 16),
                const Text("Add Questions", style: TextStyle(fontSize: 18)),
                TextField(
                  controller: _questionController,
                  decoration: const InputDecoration(labelText: "Question"),
                ),
                TextField(
                  controller: _optionAController,
                  decoration: const InputDecoration(labelText: "Option A"),
                ),
                TextField(
                  controller: _optionBController,
                  decoration: const InputDecoration(labelText: "Option B"),
                ),
                TextField(
                  controller: _optionCController,
                  decoration: const InputDecoration(labelText: "Option C"),
                ),
                TextField(
                  controller: _optionDController,
                  decoration: const InputDecoration(labelText: "Option D"),
                ),
                TextField(
                  controller: _answerController,
                  decoration: const InputDecoration(
                    labelText: "Correct Answer (e.g., Option A)",
                  ),
                ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _addQuestion,
                  style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            19,
                            105,
                            97,
                          ),
                        ),
                  child: const Text("Add Question", style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(height: 16),
                Text("Questions Added: ${_questions.length}"),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submitQuiz,
                  style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            19,
                            105,
                            97,
                          ),
                        ),
                  child: const Text("Submit Quiz", style: TextStyle(color: Colors.white)),
                ),
                SizedBox(height: 30),

                Text(
                  "Jobs Form",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 19, 105, 97),
                  ),
                ),
                SizedBox(height: 12),
                Form(
                  key: _jobsFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: jobTitleController,
                        decoration: InputDecoration(
                          labelText: 'Job Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Job Title'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: companyController,
                        decoration: InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Company'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: locationController,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Location'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: jobTypeController,
                        decoration: InputDecoration(
                          labelText: 'Job Type (e.g., Full-time, Part-time)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Job Type'),
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        controller: applyLinkController,
                        decoration: InputDecoration(
                          labelText: 'Apply Link',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) => validate(val, 'Apply Link'),
                      ),
                      SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedJobStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            statusOptions
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedJobStatus = value;
                          });
                        },
                        validator:
                            (value) =>
                                value == null ? 'Please select a status' : null,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (_jobsFormKey.currentState!.validate()) {
                            submitJobData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(
                            255,
                            19,
                            105,
                            97,
                          ),
                        ),
                        child: Text(
                          "Submit",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
