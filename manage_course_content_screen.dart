import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ManageCourseContentScreen extends StatefulWidget {
  const ManageCourseContentScreen({Key? key}) : super(key: key);

  @override
  State<ManageCourseContentScreen> createState() =>
      _ManageCourseContentScreenState();
}

class _ManageCourseContentScreenState extends State<ManageCourseContentScreen> {
  String? selectedCourse;
  List<Map<String, dynamic>> courses = [];
  List<dynamic> courseContent = [];

  final _topicController = TextEditingController();
  final _urlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _typeController = TextEditingController();
  int? editingId;

  @override
  void initState() {
    super.initState();
    fetchAllCourses();
  }

  Future<void> fetchAllCourses() async {
    final result = await ApiService.getCourses();
    setState(() {
      courses = List<Map<String, dynamic>>.from(result);
    });
  }

  Future<void> fetchContent(String courseName) async {
    final apiService = ApiService();
    final result = await apiService.getCourseContent(courseName);
    setState(() {
      courseContent = result;
      final course = courses.firstWhere((c) => c['course_name'] == courseName);
      _categoryController.text = course['category'] ?? '';
      _typeController.text = course['type'] ?? '';
    });
  }

  Future<void> handleDelete(int id) async {
    final success = await ApiService.deleteCourseContent(id);
    if (success == true) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Deleted successfully")));
      if (selectedCourse != null) fetchContent(selectedCourse!);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error deleting course content.")));
    }
  }

  Future<void> handleUpdate() async {
    if (editingId != null &&
        _topicController.text.isNotEmpty &&
        _urlController.text.isNotEmpty) {
      final success = await ApiService.updateCourseContent(
        editingId!,
        _topicController.text,
        _urlController.text,
      );
      if (success == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Updated successfully")));
        _topicController.clear();
        _urlController.clear();
        setState(() => editingId = null);
        if (selectedCourse != null) fetchContent(selectedCourse!);
      }
    }
  }

  Future<void> handleAddContent() async {
    if (_topicController.text.isNotEmpty &&
        _urlController.text.isNotEmpty &&
        selectedCourse != null) {
      final apiService = ApiService();
      final success = await apiService.addCourseContent(
        selectedCourse!,
        _topicController.text,
        _urlController.text,
      );
      if (success == true) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Added successfully")));
        _topicController.clear();
        _urlController.clear();
        fetchContent(selectedCourse!);
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error adding course content.")));
      }
    }
  }

  void showEditDialog(Map<String, dynamic> item) {
    _topicController.text = item['topic_title'];
    _urlController.text = item['video_url'];
    setState(() => editingId = item['id']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF136961), Color(0xFF28BABA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, 3),
                blurRadius: 8,
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
        ),
        elevation: 5,
        centerTitle: true,
        title: const Text(
          'Manage Course Content',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w400,
            fontFamily: 'Roboto', // You can change this to your custom font
            letterSpacing: 1,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.teal),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  hint: Text("Select a Course"),
                  value: selectedCourse,
                  items:
                      courses.map((course) {
                        return DropdownMenuItem<String>(
                          value: course['course_name'],
                          child: Text(course['course_name']),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCourse = value;
                      editingId = null;
                      _topicController.clear();
                      _urlController.clear();
                    });
                    if (value != null) fetchContent(value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

            if (selectedCourse != null && courseContent.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: courseContent.length,
                itemBuilder: (context, index) {
                  final item = courseContent[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 3,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        item['topic_title'] ?? '',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(item['video_url'] ?? ''),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.teal),
                            onPressed: () => showEditDialog(item),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () {
                              final id = item['id'];
                              if (id != null && id is int) {
                                handleDelete(id);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

            const SizedBox(height: 20),

            if (selectedCourse != null) ...[
              Text(
                editingId == null ? "➕ Add New Content" : "✏️ Edit Content",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  labelText: "Topic Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlController,
                decoration: InputDecoration(
                  labelText: "Video URL",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: editingId == null ? handleAddContent : handleUpdate,
                child: Text(
                  editingId == null ? "Add Content" : "Update Content",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      editingId == null ? Colors.teal : Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
