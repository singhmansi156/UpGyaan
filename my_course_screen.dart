import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:skill_development_app/services/api_service.dart';
import 'package:animate_do/animate_do.dart';

class MyCourseScreen extends StatefulWidget {
  final List<dynamic> enrolledCourses;

  const MyCourseScreen({super.key, required this.enrolledCourses});

  @override
  State<MyCourseScreen> createState() => _MyCourseScreenState();
}

class _MyCourseScreenState extends State<MyCourseScreen> {
  late List<dynamic> enrolledCourses;

  @override
  void initState() {
    super.initState();
    enrolledCourses = widget.enrolledCourses;
  }

  String formatDate(dynamic dateStr) {
    try {
      final inputFormat = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
      final parsedDate = inputFormat.parseUtc(dateStr.toString());
      return DateFormat('d-MMM-yyyy h:mm a').format(parsedDate.toLocal());
    } catch (e) {
      print('Error parsing date: $e');
      return 'Invalid Date';
    }
  }

  void onContinuePressed(dynamic course) async {
    final courseId = course['id'];
    final courseName = course['course_name'];
    final apiService = ApiService();
    final content = await apiService.getCourseContent(courseName);
    context.push(
      '/course-lessons',
      extra: {
        'courseId': courseId, 
        'courseName': courseName,
        'courseContent': content,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar:  AppBar(
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
      'My Courses',
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
      body: enrolledCourses.isEmpty
          ? const Center(
              child: Text(
                "You haven't enrolled in any courses yet.",
                style: TextStyle(fontSize: 18),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWideScreen ? 2 : 1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 3,
                ),
                itemCount: enrolledCourses.length,
                itemBuilder: (context, index) {
                  final course = enrolledCourses[index];
                  final formattedDate = formatDate(course['enrolled_at']);

                  return FadeInUp(
                    duration: Duration(milliseconds: 500),
                    child: Material(
                      elevation: 3,
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                           colors: [
                                                Colors.teal.shade200,
                                                Colors.teal.shade100,
                                              ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course['course_name'],
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enrolled on: $formattedDate',
                              style: TextStyle(color: Colors.black),
                            ),
                            const Spacer(),
                            Expanded(
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: BounceInUp(
                                  duration: Duration(milliseconds: 800),
                                  child: ElevatedButton.icon(
                                    onPressed: () => onContinuePressed(course),
                                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                                    label: const Text("Continue"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade600,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
