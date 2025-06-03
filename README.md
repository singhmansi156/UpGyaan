UpGyaan: Vocational Training Program for Rural Youth Development

1. Project Description
   UpGyaan is a mobile and web-based application developed to empower rural youth by offering free vocational courses, enabling skill acquisition, and enhancing job opportunities. It provides an easy-to-use platform where users can enroll in topic-based courses, track progress, and generate certificates upon successful completion—including passing a quiz at the end of each course.

2. Features
    User registration and login system  
    Topic-based vocational courses  
    Course progress tracking  
    End-of-course quiz  
    Certificate generation on quiz success  
    Admin dashboard to manage courses and users  
    Secure authentication  
    Real-time data sync between frontend and backend

3. Hardware Requirements
   Smartphone / Computer / Laptop  
   Internet connection  
   Server or local machine to run the Flask backend

4. Software Requirements
   Operating System: Windows / Linux / macOS  
   Frontend Framework: Flutter  
   Backend Framework: Flask (Python)  
   Database: MySQL  
   Programming Languages: Dart, Python  
   Libraries: 
   Flutter (`http`, `go_router`, `shared_preferences`,`youtube_flutter_player`)  
   Python (`Flask`, `Flask-MySQLdb`, `Flask-CORS`)  
   IDE: VS Code 

5. Installation & Setup Instructions
   Frontend (Flutter):
   1. Clone the repo and navigate to the `lib` folder.
   2. Run: `flutter pub get`
   3. To launch app: `flutter run -d chrome` or `flutter run` (for mobile)

   Backend (Flask):
   1. Navigate to the `backend` folder.
   2. Run: `pip install -r requirements.txt`
   3. Launch server: `python app.py`

   Database:
   1. Import `database.sql` into your MySQL server.
   2. Update DB credentials in `app.py`.

License
This project is for educational purposes only and does not carry a license for commercial use.
