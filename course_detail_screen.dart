import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_development_app/services/api_service.dart';
import 'package:animate_do/animate_do.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseName;

  CourseDetailScreen({required this.courseName});

  @override
  _CourseDetailScreenState createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  Map<String, dynamic>? courseDetails;
  List<dynamic> courseContents = [];
  bool isLoading = true;
  bool isEnrolled = false;

  @override
  void initState() {
    super.initState();
    fetchCourseData();
  }

  Future<void> fetchCourseData() async {
    final details = await ApiService.getCourseDetail(widget.courseName);
    final apiService = ApiService();
    final content = await apiService.getCourseContent(widget.courseName);
    final email = await getUserEmail();

    bool enrolled = false;
    if (email != null) {
      final enrollmentResponse = await ApiService.checkEnrollment(email, widget.courseName);
      enrolled = enrollmentResponse['isEnrolled'] ?? false;
    }

    setState(() {
      courseDetails = details;
      courseContents = content;
      isEnrolled = enrolled;
      isLoading = false;
    });
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F5FC),
      appBar: AppBar(
    automaticallyImplyLeading: false,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF136961),
            Color(0xFF28BABA),
          ],
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
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(25),
      ),
    ),
    elevation: 5,
    centerTitle: true,
    title: const Text(
      'Course Details',
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
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Course Image
                  ZoomIn(
                    duration: Duration(milliseconds: 1000),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Center(
                          child: Image.asset(
                            'assets/course.png',
                            height: 250,
                            width: 600,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Course Name
                  FadeInDown(
                    duration: Duration(milliseconds: 800),
                    child: Center(
                      child: Text(
                        courseDetails?["course_name"] ?? "N/A",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 19, 105, 97),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Course Info Box
                  FadeInLeft(
                    duration: Duration(milliseconds: 900),
                    child: Center(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.white]),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 5))],
                        ),
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${courseDetails?["title"] ?? "N/A"}",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                            SizedBox(height: 10),
                            Text("📝 Description: ${courseDetails?["description"] ?? "N/A"}"),
                            SizedBox(height: 10),
                            Text("⏳ Duration: ${courseDetails?["duration"] ?? "N/A"}"),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 40),

                  // Course Content Header
                  FadeInUp(
                    duration: Duration(milliseconds: 900),
                    child: Center(
                      child: Text(
                        "📚Course Content : ",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromARGB(255, 19, 105, 97),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),

                  // Course Topics List
                  SlideInUp(
                    duration: Duration(milliseconds: 900),
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Topics covered in this course:",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Divider(thickness: 1.2),
                          Column(
                            children: courseContents.map((content) {
                              return ListTile(
                                leading: Icon(Icons.play_circle_fill, color: const Color.fromARGB(255, 19, 105, 97)),
                                title: Text(content["topic_title"] ?? "N/A", style: TextStyle(fontSize: 17)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Enroll Button
                  ZoomIn(
                    duration: Duration(milliseconds: 1000),
                    child: Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (isEnrolled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('You are already enrolled in this course.')),
                            );
                            return;
                          }

                          final userEmail = await getUserEmail();
                          if (userEmail == null || userEmail.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('User email not found.')),
                            );
                            return;
                          }

                          final response = await ApiService.enrollInCourse(userEmail, widget.courseName);

                          if (response['status'] == 'success') {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Enrolled successfully!')),
                            );
                            setState(() {
                              isEnrolled = true;
                            });
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Enrollment failed!')),
                            );
                          }
                        },
                        icon: Icon(Icons.school, color: Colors.white),
                        label: Text(
                          isEnrolled ? "Already Enrolled" : "Enroll Now",
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEnrolled ? const Color.fromARGB(255, 65, 163, 153) : const Color.fromARGB(255, 19, 105, 97),
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 30),

                  // Happy Learning Message
                  FadeIn(
                    duration: Duration(milliseconds: 800),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.indigoAccent.shade100,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(color: const Color.fromARGB(255, 19, 105, 97), blurRadius: 10, offset: Offset(0, 5)),
                          ],
                        ),
                        child: Text(
                          "🌟 Happy Learning! 😊",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.normal,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 40),

                  // Certificate Info Box
                  FadeInUp(
                    duration: Duration(milliseconds: 900),
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.white]),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "After completing the course of ${courseDetails?["course_name"] ?? "this course"}, you will be able to generate a certificate of completion!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 19, 105, 97),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  

                  // Certificate Image
                  BounceInUp(
                    duration: Duration(milliseconds: 1200),
                    child: Center(
                      child: Image.asset(
                        'assets/certificate.png',
                        height: 400,
                        width: 400,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
