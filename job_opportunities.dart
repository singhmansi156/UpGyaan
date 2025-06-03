import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:animate_do/animate_do.dart';

class JobOpportunitiesScreen extends StatefulWidget {
  const JobOpportunitiesScreen({super.key});

  @override
  State<JobOpportunitiesScreen> createState() => _JobOpportunitiesScreenState();
}

class _JobOpportunitiesScreenState extends State<JobOpportunitiesScreen> {
  late Future<List<dynamic>> jobList;

  @override
  void initState() {
    super.initState();
    jobList = fetchJobs();
  }

  Future<List<dynamic>> fetchJobs() async {
    final response = await http.get(Uri.parse('http://127.0.0.1:5000/get_jobs'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load jobs');
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:AppBar(
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
      'Jobs',
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FutureBuilder<List<dynamic>>(
          future: jobList,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return Center(child: CircularProgressIndicator(color: Colors.teal[600]));
            if (snapshot.hasError)
              return Center(child: Text('Error fetching jobs', style: TextStyle(color: Colors.red)));

            final jobs = snapshot.data!;
            if (jobs.isEmpty)
              return Center(child: Text('No jobs available'));

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: jobs.length,
              itemBuilder: (context, index) {
                final job = jobs[index];
                return FadeInUp(
                  delay: Duration(milliseconds: 100 * index), // Staggered animation
                  child: Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade200, Colors.teal.shade400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.teal.withOpacity(0.3),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: EdgeInsets.all(4),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ZoomIn(
                            delay: Duration(milliseconds: 200),
                            child: Text(
                              job['job_title'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal[900],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          ZoomIn(
                            delay: Duration(milliseconds: 200),
                            child: Text("Company: ${job['company_name']}", style: TextStyle(color: Colors.teal[800])),
                          ),
                          ZoomIn(
                            delay: Duration(milliseconds: 300),
                            child: Text("Location: ${job['job_location']}", style: TextStyle(color: Colors.teal[800])),
                          ),
                          ZoomIn(
                            delay: Duration(milliseconds: 400),
                            child: Text("Type: ${job['job_type']}", style: TextStyle(color: Colors.teal[800])),
                          ),
                          SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ZoomIn(
                              delay: Duration(milliseconds: 200),
                              child: ElevatedButton.icon(
                                onPressed: () => _launchURL(job['apply_link']),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal[600],
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: Icon(Icons.link_rounded, color: Colors.white),
                                label: Text("Apply Now"),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
