import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skill_development_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class CourseLessonScreen extends StatefulWidget {
  final String courseName;
  final List<dynamic> courseContent;
  final int courseId;

  const CourseLessonScreen({
    Key? key,
    required this.courseId,
    required this.courseName,
    required this.courseContent,
  }) : super(key: key);

  @override
  State<CourseLessonScreen> createState() => _CourseLessonScreenState();
}

class _CourseLessonScreenState extends State<CourseLessonScreen> {
  Set<String> watchedTopics = {};
  bool isCertificateGenerated = false;
  bool isQuizCompleted = false;
  bool isQuizAvailable = false;

  void checkIfAllWatched() {
    final allWatched = widget.courseContent.every((item) {
      final topic = item['topic_title'] ?? '';
      return watchedTopics.contains(topic);
    });
    if (allWatched) {
      setState(() {
        isQuizAvailable = true;
      });
    }
  }

  Future<void> fetchWatchedTopics() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    // ✅ Removed the recursive call here
    final topics = await ApiService.getWatchedTopics(email, widget.courseName);

    setState(() {
      watchedTopics = topics.toSet(); // ✅ Correctly updating the state
    });
    checkIfAllWatched();
  }

  @override
  void initState() {
    super.initState();
    fetchWatchedTopics(); // ✅ Only called once here
  }

  Future<void> startQuiz() async {
    final quiz = await ApiService.fetchQuizByCourseName(widget.courseName);

    if (quiz == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No quiz found for this course")),
      );
      return;
    }

    final List<dynamic> questions = quiz['questions'];
    int score = 0;
    List<String?> userAnswers = [];

    for (var q in questions) {
      final result = await showDialog<String>(

        context: context,
        builder:
            (context) => AlertDialog(
              elevation: 8,
              surfaceTintColor: Colors.blueGrey,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              contentPadding: const EdgeInsets.all(12),
              title: Text(q['question'], style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    (q['options'] as List<dynamic>).map((opt) {
                      return ListTile(
                        title: Text(opt, style: TextStyle(color: Colors.black, fontSize: 17),),
                        onTap: () {
                          Navigator.pop(context, opt);
                        },
                      );
                    }).toList(),
              ),
            ),
      );
      userAnswers.add(result);
    }

    for (int i = 0; i < questions.length; i++) {
      final correctAnswer =
          questions[i]['answer']?.toString().trim().toLowerCase();
      final userAnswer = userAnswers[i]?.toString().trim().toLowerCase();

      if (userAnswer == correctAnswer) {
        score++;
      } else {
        print("Wrong: Q$i -> User: $userAnswer | Correct: $correctAnswer");
      }
    }

    bool isPassed = score >= (questions.length / 2);

    if (isPassed) {
      setState(() {
        isQuizCompleted = true;
      });
    }

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(isPassed ? "Passed in Quiz" : "Failed in Quiz"),
            content: Text("Your score: $score / ${questions.length}"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("OK"),
              ),
            ],
          ),
    );
  }

  Future<void> markVideoWatched(String topicTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? '';

    final success = await ApiService.markTopicWatched(
      email,
      widget.courseName,
      topicTitle,
    );

    if (success) {
      setState(() {
        watchedTopics.add(topicTitle); // Update the watched topics set
      });
      checkIfAllWatched();
    }
  }

  String extractVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    if (uri.host.contains('youtu.be')) {
      return uri.pathSegments.first;
    } else if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'] ?? '';
    }
    return '';
  }

  void openVideoPlayer(String url, String topicTitle) {
    final videoId = extractVideoId(url);

    if (videoId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid YouTube link')));
      return;
    }

    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          contentPadding: const EdgeInsets.all(12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                topicTitle,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                width: MediaQuery.of(context).size.width * 0.8,
                child: YoutubePlayer(controller: controller),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await markVideoWatched(topicTitle);

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder:
                        (_) => const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 70,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "Marked as Watched!",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                  );

                  await Future.delayed(
                    const Duration(seconds: 1),
                  ); // Show tick for 1s
                  Navigator.of(context).pop(); // Close animation dialog
                  Navigator.of(context).pop(); // Close video dialog
                },
                icon: const Icon(Icons.check),
                label: const Text("Mark as Watched"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildLessonCard(Map<String, dynamic> item) {
    final topic = item['topic_title'] ?? '';
    final url = item['video_url'] ?? '';
    final watched = watchedTopics.contains(topic);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              watched
                  ? [Colors.white, Colors.green.shade100]
                  : [Colors.white, Colors.teal.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(2, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          topic,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: watched ? Colors.black : Colors.black87,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: watched ? 0.5 : 1.0,
            child: ElevatedButton.icon(
              onPressed: () => openVideoPlayer(url, topic),
              icon: const Icon(Icons.play_circle, color: Colors.white),
              label: const Text("Open"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 48, 122, 114),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        trailing: Icon(
          watched ? Icons.check_circle : Icons.circle_outlined,
          color: watched ? Colors.green : Colors.grey,
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validTopics =
        widget.courseContent
            .map((item) => item['topic_title'])
            .whereType<String>()
            .where((title) => title.trim().isNotEmpty)
            .toList();

    final allWatched = validTopics.every(
      (topic) => watchedTopics.contains(topic),
    );

    return YoutubePlayerControllerProvider(
      controller: YoutubePlayerController(), // Dummy controller
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: BoxDecoration(
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
            child: AppBar(
              title: Text(widget.courseName),
              centerTitle: true,
              foregroundColor: Colors.white,
              backgroundColor: Colors.transparent,
              elevation: 0,
            ),
          ),
        ),
        body:
            widget.courseContent.isEmpty
                ? const Center(
                  child: Text('No content available for this course.'),
                )
                : Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      constraints.maxWidth > 600
                                          ? 800
                                          : double.infinity,
                                ),
                                child: ListView.builder(
                                  itemCount: widget.courseContent.length,
                                  itemBuilder: (context, index) {
                                    return buildLessonCard(
                                      widget.courseContent[index],
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (isQuizAvailable && !isQuizCompleted)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade700,
                          padding: const EdgeInsets.only(
                           top: 10,
                            bottom: 10,
                            left: 20,
                            right: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: startQuiz,
                        icon: const Icon(
                          Icons.question_answer,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Take Quiz',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                    if (isQuizCompleted)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed:
                              isCertificateGenerated
                                  ? null
                                  : () async {
                                    final prefs =
                                        await SharedPreferences.getInstance();
                                    final apiService = ApiService();
                                    final courseId = await apiService
                                        .fetchCourseIdByName(widget.courseName);

                                    if (courseId == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("Course ID not found!"),
                                        ),
                                      );
                                      return;
                                    }

                                    final userId =
                                        prefs.getInt('user_id') ?? -1;
                                    if (userId == -1) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text("User ID not found!"),
                                        ),
                                      );
                                      return;
                                    }

                                    final certificateUrl =
                                        await ApiService.generateCertificate(
                                          userId,
                                          courseId,
                                        );

                                    if (certificateUrl != null) {
                                      setState(() {
                                        isCertificateGenerated = true;
                                      });

                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              title: Row(
                                                children: const [
                                                  Icon(
                                                    Icons.emoji_events,
                                                    color: Colors.amber,
                                                    size: 30,
                                                  ),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "Certificate Ready 🎓",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              content: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const SizedBox(height: 10),
                                                  const Text(
                                                    "Congratulations! 🎉",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    "Your certificate has been successfully generated.",
                                                    textAlign: TextAlign.center,
                                                  ),
                                                  const SizedBox(height: 15),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.link,
                                                          color: Colors.black,
                                                        ),
                                                        const SizedBox(
                                                          width: 8,
                                                        ),
                                                        Expanded(
                                                          child: Text(
                                                            certificateUrl,
                                                            style: const TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              decoration:
                                                                  TextDecoration
                                                                      .underline,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15),
                                                  ElevatedButton.icon(
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          Colors.indigo,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 12,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              12,
                                                            ),
                                                      ),
                                                    ),
                                                    onPressed: () async {
                                                      if (await canLaunchUrl(
                                                        Uri.parse(
                                                          certificateUrl,
                                                        ),
                                                      )) {
                                                        await launchUrl(
                                                          Uri.parse(
                                                            certificateUrl,
                                                          ),
                                                          mode:
                                                              LaunchMode
                                                                  .externalApplication,
                                                        );
                                                      } else {
                                                        throw 'Could not launch $certificateUrl';
                                                      }
                                                    },
                                                    icon: const Icon(
                                                      Icons.download,
                                                      color: Colors.white,
                                                    ),
                                                    label: const Text(
                                                      'Download',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Failed to generate certificate",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          icon: const Icon(Icons.verified, color: Colors.white),
                          label: const Text(
                            'Generate Certificate',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
      ),
    );
  }
}
