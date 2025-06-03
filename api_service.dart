import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5000';
    } else if (Platform.isAndroid) {
      return 'http://192.168.29.22:5000';
    } else {
      return 'http://192.168.29.22:5000';
    }
  }

  // Function to handle login and store token and role
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);

        // Directly extract values
        String? token = data['token'];
        String? role = data['role'];
        int? userId = data['user_id'];

        if (token != null && role != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('token', token);
          await prefs.setString('role', role);
          await prefs.setInt('user_id', userId!);

          return {
            'success': true,
            'message': data['message'],
            'token': token,
            'role': role,
            'user_id': userId,
          };
        } else {
          return {'success': false, 'message': 'Token or role missing'};
        }
      } else {
        var errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error during login: $e'};
    }
  }

  // Function to get the authentication token (from local storage or backend)
  Future<String?> getToken() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(
        'token',
      ); // Retrieve the token from shared preferences
    } catch (e) {
      print('Error fetching token: $e');
      return null;
    }
  }

  // Function to get the user role (from local storage or backend)
  Future<String?> getUserRole() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString(
        'role',
      ); // Retrieve the role from shared preferences
    } catch (e) {
      print('Error fetching user role: $e');
      return null;
    }
  }

  // SIGNUP API
  static Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/signup');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        }),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': jsonResponse['message']};
      } else {
        return {'success': false, 'message': jsonResponse['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Signup failed: $e'};
    }
  }

  // FORGOT PASSWORD - Send Reset Link to Email
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/forgot-password');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"email": email}),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': jsonResponse['message']};
      } else {
        return {'success': false, 'message': jsonResponse['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // RESET PASSWORD - User clicks reset link and sets new password
  static Future<Map<String, dynamic>> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/reset-password?token=$token');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"new_password": newPassword}),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200 && jsonResponse['status'] == 'success') {
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Password reset successful',
        };
      } else {
        return {
          'success': false,
          'message': jsonResponse['message'] ?? 'Something went wrong',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error resetting password: $e'};
    }
  }

  // 1️⃣ Add Menu
  static Future<http.Response> addMenu(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/menus');
    return await http.post(
      url,
      body: jsonEncode(data),
      headers: {"Content-Type": "application/json"},
    );
  }

  // 2️⃣ Get Menus
  static Future<List<dynamic>> getMenus() async {
    final url = Uri.parse('$baseUrl/menus');
    final response = await http.get(url);
    return jsonDecode(response.body);
  }

  // 3️⃣ Add Course
  static Future<http.Response> addCourse(Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/courses');
    return await http.post(
      url,
      body: jsonEncode(data),
      headers: {"Content-Type": "application/json"},
    );
  }

  // 4️⃣ Get All Courses
  static Future<List<dynamic>> getCourses() async {
    final url = Uri.parse('$baseUrl/courses');
    final response = await http.get(url);
    return jsonDecode(response.body);
  }

  // 5️⃣ Get Course Details by Course Name
  static Future<Map<String, dynamic>> getCourseDetail(String courseName) async {
    final url = Uri.parse('$baseUrl/course-detail/$courseName');
    final response = await http.get(url);
    return jsonDecode(response.body);
  }

  static Future<bool> updateCourseContent(
    int contentId,
    String topicTitle,
    String videoUrl,
  ) async {
    final url = Uri.parse('$baseUrl/course-content/$contentId');

    try {
      final response = await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'topic_title': topicTitle, 'video_url': videoUrl}),
      );

      if (response.statusCode == 200) {
        print("Update Success: ${response.body}");
        return true;
      } else {
        print("Update Failed: ${response.statusCode} - ${response.body}");
        return false;
      }
    } catch (e) {
      print("Error updating content: $e");
      return false;
    }
  }

  static Future<bool> deleteCourseContent(int contentId) async {
    final url = Uri.parse('$baseUrl/course-content/$contentId');

    try {
      final response = await http.delete(url);

      if (response.statusCode == 200) {
        // Optional: print debug info
        print("Delete response: ${response.body}");
        return true;
      } else {
        print("Failed to delete. Status code: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("Error deleting content: $e");
      return false;
    }
  }

  static Future<String?> generateCertificate(int userId, int courseId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate_certificate'),
      body: jsonEncode({'user_id': userId, 'course_id': courseId}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['certificate_url']; // Must match key from Flask response
    } else {
      print("❌ Failed with status: ${response.statusCode}");
      return null;
    }
  }

  // 9️⃣ Update Course Category and Type
  static Future<Map<String, dynamic>> updateCourseCategoryType(
    String courseName,
    String category,
    String type,
  ) async {
    final url = Uri.parse('$baseUrl/update_course_category_type');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'course_name': courseName,
          'category': category,
          'type': type,
        }),
      );
      final jsonResponse = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': jsonResponse['message'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating course category/type: $e',
      };
    }
  }

  Future<List<dynamic>> getCourseContent(String courseName) async {
    final response = await http.get(
      Uri.parse('$baseUrl/course-content/$courseName'),
    );

    if (response.statusCode == 200) {
      // Parse the JSON response into a list of course content
      List<dynamic> courseContents = json.decode(response.body);
      return courseContents;
    } else {
      throw Exception('Failed to load course content');
    }
  }

  static Future<Map<String, dynamic>> enrollInCourse(
    String userEmail,
    String courseName,
  ) async {
    final url = Uri.parse('$baseUrl/enroll');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_email': userEmail, 'course_name': courseName}),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'status': 'success', 'message': jsonResponse['message']};
      } else {
        return {'status': 'error', 'message': jsonResponse['message']};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Error enrolling in course: $e'};
    }
  }

  // CHECK IF USER IS ENROLLED IN A COURSE
  static Future<Map<String, dynamic>> checkEnrollment(
    String userEmail,
    String courseName,
  ) async {
    final url = Uri.parse('$baseUrl/check_enrollment');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'user_email': userEmail, 'course_name': courseName}),
      );

      final jsonResponse = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'isEnrolled': jsonResponse['enrolled']}; // ✅ fixed key
      } else {
        return {'status': 'error', 'message': jsonResponse['message']};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Error checking enrollment: $e'};
    }
  }

  // GET ENROLLED COURSES API
  static Future<List<dynamic>> getEnrolledCourses(String userEmail) async {
    final url = Uri.parse('$baseUrl/get-enrolled-courses/$userEmail');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load enrolled courses');
    }
  }

  /// MARK TOPIC AS WATCHED
  // MARK TOPIC AS WATCHED
  static Future<bool> markTopicWatched(
    String userEmail,
    String courseName,
    String topicTitle,
  ) async {
    final url = Uri.parse('$baseUrl/mark-watched');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_email': userEmail,
          'course_name': courseName,
          'topic_title': topicTitle,
        }),
      );

      if (response.statusCode == 200) {
        return true; // Just return boolean success
      } else {
        return false;
      }
    } catch (e) {
      print('Error marking topic watched: $e');
      return false;
    }
  }

  /// GET WATCHED TOPICS
  static Future<List<String>> getWatchedTopics(
    String userEmail,
    String courseName,
  ) async {
    final url = Uri.parse(
      '$baseUrl/get-watched-topics?user_email=$userEmail&course_name=$courseName',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        List<dynamic> topics = jsonResponse['watched_topics'];
        return topics
            .map((e) => e.toString())
            .toList(); // Ensure it's a list of Strings
      } else {
        throw Exception(
          'Failed to load watched topics. Status code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error loading watched topics: $e');
    }
  }

  Future<bool> addCourseContent(
    String courseName,
    String topicTitle,
    String videoUrl,
  ) async {
    // Prepare the request body
    final Map<String, dynamic> requestBody = {
      'course_name': courseName,
      'topics': [
        {'topic_title': topicTitle, 'video_url': videoUrl},
      ],
    };

    try {
      // Send POST request to backend
      final response = await http.post(
        Uri.parse('$baseUrl/submit_course_content'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Check for successful response
      if (response.statusCode == 200) {
        // If success, return true
        return true;
      } else {
        // If error, log the error and return false
        print('Error: ${response.body}');
        return false;
      }
    } catch (e) {
      // Handle errors (network issues, etc.)
      print('An error occurred: $e');
      return false;
    }
  }

  Future<int?> fetchCourseIdByName(String courseName) async {
    // Prepare the request body
    final Map<String, dynamic> requestBody = {'course_name': courseName};

    try {
      // Send POST request to backend
      final response = await http.post(
        Uri.parse('$baseUrl/get_course_id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      // Check for successful response
      if (response.statusCode == 200) {
        // If success, return the course ID
        final Map<String, dynamic> data = json.decode(response.body);
        return data['course_id']; // Assuming response contains 'course_id'
      } else {
        // If error, return null and print error message
        print('Error: ${response.body}');
        return null;
      }
    } catch (e) {
      // Handle errors (network issues, etc.)
      print('An error occurred: $e');
      return null;
    }
  }

  // Fetch categories from the backend
  static Future<List<String>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/get_categories'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['categories']);
    } else {
      throw Exception(
        'Failed to load categories. Status Code: ${response.statusCode}',
      );
    }
  }

  static Future<List<String>> fetchTypesForCategory(String category) async {
    final response = await http.get(
      Uri.parse('$baseUrl/get_types_for_category/$category'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<String>.from(data['types'] ?? []);
    } else {
      throw Exception('Failed to load types for category');
    }
  }

  static Future<void> addCategory(String categoryName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add_category'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'category_name': categoryName}),
      );

      if (response.statusCode == 200) {
        return;
      } else {
        throw Exception('Failed to add category: ${response.body}');
      }
    } catch (e) {
      print("Error occurred while adding category: $e");
      throw Exception('Failed to add category: $e');
    }
  }

  static Future<void> addType(String categoryName, String typeName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_type'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'category_name': categoryName, 'type_name': typeName}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add type');
    }
  }

  static Future<Map<String, dynamic>?> fetchQuizByCourseName(
    String courseName,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get_quiz_by_course_name/$courseName'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "quiz_title": data["quiz_title"],
          "questions": List<Map<String, dynamic>>.from(data["questions"]),
        };
      } else {
        print("Failed to fetch quiz: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error in fetchQuizByCourseName: $e");
      return null;
    }
  }
}
