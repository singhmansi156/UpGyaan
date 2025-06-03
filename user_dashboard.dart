import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_development_app/services/api_service.dart';
import 'package:animate_do/animate_do.dart'; // Importing the animate_do package

class UserDashboard extends StatefulWidget {
  @override
  _UserDashboardState createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> {
  late Future<List<dynamic>> menusFuture;
  late Future<List<dynamic>> coursesFuture;
  Set<String> expandedCategories = {};
  String userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
    menusFuture = ApiService.getMenus();
    coursesFuture = ApiService.getCourses();
  }

  Future<void> fetchUserDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString("email") ?? "No email found";
    });
  }

  Map<String, List<dynamic>> groupMenusByCategory(List<dynamic> menus) {
    final Map<String, List<dynamic>> grouped = {};
    for (var menu in menus) {
      final category = menu["category"] ?? "Uncategorized";
      if (!grouped.containsKey(category)) {
        grouped[category] = [];
      }
      grouped[category]!.add(menu);
    }
    return grouped;
  }

   Widget ruralImage(String path) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Image.asset(
        path,
        width: 150,
        height: 150,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(25),
        ),
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
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(20),
      ),
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
                  size: 40,
                ),
              ),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
            ),

            ListTile(
              leading: Icon(
                Icons.bookmark,
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
              title: Text("My Courses", style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                final email = prefs.getString('email') ?? '';
                try {
                  final enrolledCourses = await ApiService.getEnrolledCourses(
                    email,
                  );
                  context.push('/my-courses', extra: enrolledCourses);
                } catch (e) {
                  print('Error: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error loading courses")),
                  );
                }
              },
            ),
              ListTile(
              leading: Icon(
                Icons.chat_rounded,
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
              title: Text("AI-Chatbot", style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
              onTap: () {
                context.push('/chatbot-screen');
              },
            ),

            ListTile(
              leading: Icon(
                Icons.work,
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
              title: Text("Jobs", style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
              onTap: () {
                context.push('/jobs');
              },
            ),
           
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: const Color.fromARGB(255, 19, 105, 97),
              ),
              title: Text("Logout", style: TextStyle(fontSize: 14, color: Colors.black, fontWeight: FontWeight.bold)),
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "UpGyaan: Where Rural Youth Meets Opportunity",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Montserrat',

                
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: const Color.fromARGB(255, 16, 121, 111)), // golden tone
              ),
            
            const SizedBox(height: 20),
            Text(
              "We offer free skill development courses, job opportunities and certification — empowering the next generation of rural changemakers.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            // Image grid
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 5,
              runSpacing: 5,
              children: [
                ZoomIn(
                  duration: Duration(milliseconds: 500),
                  child: ruralImage('assets/rural1.jpeg')
                  ),
                ZoomIn(
                  duration: Duration(milliseconds: 700),
                  child: ruralImage('assets/rural2.jpg')
                  ),
                ZoomIn(
                  duration: Duration(milliseconds: 900),
                  child: ruralImage('assets/rural3.jpeg')
                  ),
                ZoomIn(
                  duration: Duration(milliseconds: 1100),
                  child: ruralImage('assets/rural4.jpg')
                  ),
                ZoomIn(
                  duration: Duration(milliseconds: 1300),
                  child: ruralImage('assets/rural5.jpeg')
                  ),
                ZoomIn(
                  duration: Duration(milliseconds: 1500),
                  child: ruralImage('assets/rural6.jpg')
                  ),
                ZoomIn(
                  duration: Duration(milliseconds: 1700),
                  child: ruralImage('assets/rural7.jpeg')
                  ),
               // ruralImage('assets/rural8.jpg'),
              ],
            ),
          
            const SizedBox(height: 30),
          
          
        
            
        
         
              FadeInUp(
                duration: Duration(milliseconds: 500),
                child: Text(
                  "Explore Courses!",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 13, 94, 86),
                  ),
                ),
              ),
              SizedBox(height: 16),
              FutureBuilder<List<dynamic>>(
                future: Future.wait([menusFuture, coursesFuture]),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return Center(child: CircularProgressIndicator());
        
                  if (!snapshot.hasData || snapshot.data!.isEmpty)
                    return Text("No data found", style: TextStyle(fontSize: 16));
        
                  final menus = snapshot.data![0];
                  final courses = snapshot.data![1];
                  final groupedMenus = groupMenusByCategory(menus);
        
                  return Column(
                    children:
                        groupedMenus.entries.map((entry) {
                          final category = entry.key;
                          final menusInCategory = entry.value;
        
                          return FadeInUp(
                            duration: Duration(milliseconds: 600),
                            child: Card(
                              color: Colors.lightBlue[50],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                              margin: EdgeInsets.only(bottom: 12),
                              child: ExpansionTile(
                                leading: Icon(
                                  Icons.category,
                                  color: const Color.fromARGB(255, 19, 105, 97),
                                ),
                                title: Text(
                                  category,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: const Color.fromARGB(255, 19, 105, 97),
                                  ),
                                ),
                                initiallyExpanded: expandedCategories.contains(
                                  category,
                                ),
                                onExpansionChanged: (isOpen) {
                                  setState(() {
                                    if (isOpen) {
                                      expandedCategories.add(category);
                                    } else {
                                      expandedCategories.remove(category);
                                    }
                                  });
                                },
                                children:
                                    menusInCategory.map<Widget>((menu) {
                                      final linkedCourseName =
                                          menu["course_name"];
                                      final course = courses.firstWhere(
                                        (c) =>
                                            c["course_name"] == linkedCourseName,
                                        orElse: () => null,
                                      );
        
                                      if (course == null) return SizedBox();
        
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 8.0,
                                        ),
                                        child: SlideInRight(
                                          duration: Duration(milliseconds: 500),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Colors.blue.shade100,
                                                ],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              ),
                                              borderRadius: BorderRadius.circular(
                                                10,
                                              ),
                                              border: Border.all(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            child: ListTile(
                                              contentPadding: EdgeInsets.all(12),
                                              leading: Icon(
                                                Icons.school,
                                                color: const Color.fromARGB(
                                                  255,
                                                  19,
                                                  105,
                                                  97,
                                                ),
                                              ),
                                              title: Text(
                                                linkedCourseName,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  if (course["title"] != null)
                                                    Text(
                                                      "Title: ${course["title"]}",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
        
                                                  if (course["duration"] != null)
                                                    Text(
                                                      "Duration: ${course["duration"]}",
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  SizedBox(height: 12),
                                                  ElevatedButton(
                                                    onPressed: () {
                                                      context.push(
                                                        '/course-detail/${Uri.encodeComponent(linkedCourseName)}',
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color.fromARGB(
                                                            255,
                                                            19,
                                                            105,
                                                            97,
                                                          ),
        
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 10,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                    ),
                                                    child: Text(
                                                      "View Course",
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ),
    )
      );
    
  }
}
