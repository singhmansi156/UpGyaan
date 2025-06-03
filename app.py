from email.mime import image
import traceback
from turtle import width
from flask import Flask, json, request, jsonify, send_file, send_from_directory, url_for
from flask_cors import CORS
from networkx import draw
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity
import pymysql
from datetime import datetime, timedelta
import secrets
from itsdangerous import URLSafeTimedSerializer
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from werkzeug.security import generate_password_hash, check_password_hash
from flask_cors import cross_origin
from flask import render_template_string
from PIL import Image, ImageDraw, ImageFont, ImageOps
from flask import Flask, request, jsonify
from openai import AzureOpenAI
from dotenv import load_dotenv
from flask_cors import CORS
import bcrypt
import os

load_dotenv()
app = Flask(__name__)
CORS(app)  # allows Flutter (web) to access it

azure_oai_endpoint = os.getenv("AZURE_OAI_ENDPOINT")
azure_oai_key = os.getenv("AZURE_OAI_KEY")
azure_oai_deployment = os.getenv("AZURE_OAI_DEPLOYMENT")

client = AzureOpenAI(
    azure_endpoint=azure_oai_endpoint,
    api_key=azure_oai_key,
    api_version="2024-02-15-preview"
)

# Initialize Flask App
app = Flask(__name__)
CORS(app, origins="*",)

bcrypt = Bcrypt(app)

# Set Secret Keys
app.config['JWT_SECRET_KEY'] = os.getenv("JWT_SECRET_KEY", "e5cccd40353d753d47076ec2f6493407a57f5bca68676e8ba0b5d84d764b94a")
jwt = JWTManager(app)
serializer = URLSafeTimedSerializer(app.config['JWT_SECRET_KEY'])

# Database Connection
def get_db_connection():
    return pymysql.connect(
        host=os.getenv("DB_HOST", "localhost"),
        user=os.getenv("DB_USER", "root"),
        password=os.getenv("DB_PASSWORD", "mahadev"),
        database=os.getenv("DB_NAME", "userdata"),
        cursorclass=pymysql.cursors.DictCursor
    )


categories = []
category_types = {}

def load_categories():
    try:
        with open('categories.json', 'r') as file:
            data = json.load(file)
            return data.get('categories', []), data.get('category_types', {})
    except Exception as e:
        print(f"Error loading categories: {e}")
        return [], {}  # ✅ Return default tuple if file doesn't exist or has error


def save_categories(categories, category_types):
    with open('categories.json', 'w') as file:
        json.dump({"categories": categories, "category_types": category_types}, file)

def load_category_types(category_name):
    if category_name in category_types:
        return category_types[category_name]
    else:
        return [] 
    
def save_category_types(category_name, types):
    if category_name in category_types:
        category_types[category_name].extend(types)
    else:
        category_types[category_name] = types
    save_categories(categories, category_types)

categories = load_categories()[0]  # Load categories from file
category_types = load_categories()[1]  # Load category types from file

@app.route('/get_categories', methods=['GET'])
def get_categories():
    return jsonify({"categories": categories})


@app.route('/get_types_for_category/<category_name>', methods=['GET'])
def get_types_for_category(category_name):
    types = category_types.get(category_name, [])
    return jsonify({"types": types})

# ✅ API to add a new category (in-memory)
@app.route('/add_category', methods=['POST'])
def add_category():
    try:
        data = request.get_json()
        category_name = data.get('category_name', '').strip()

        if not category_name:
            return jsonify({"message": "Invalid data"}), 400

        if category_name not in categories:
            categories.append(category_name)
            category_types[category_name] = []  # Add empty types list
            save_categories(categories=categories, category_types=category_types)  # Save to file
            return jsonify({"message": "Category added successfully"}), 200
        else:
            return jsonify({"message": "Category already exists"}), 400

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"message": "Internal server error"}), 500

@app.route('/delete_category/<category_name>', methods=['DELETE'])
def delete_category(category_name):
    try:
        category_name = category_name.strip()

        if category_name not in categories:
            return jsonify({"message": "Category not found"}), 404

        categories.remove(category_name)
        category_types.pop(category_name, None)
        save_categories(categories=categories, category_types=category_types)  # Save to file

        return jsonify({"message": "Category deleted successfully"}), 200

    except Exception as e:
        print(f"Error: {e}")
        return jsonify({"message": "Internal server error"}), 500
    
    
@app.route('/add_type', methods=['POST'])
def add_type():
    data = request.get_json()
    category_name = data.get('category_name', '').strip()
    type_name = data.get('type_name', '').strip()

    if not category_name or not type_name:
        return jsonify({"message": "Invalid category or type"}), 400

    if category_name not in categories:
        return jsonify({"message": "Category does not exist"}), 400

    # Ensure the category exists in category_types dictionary
    if category_name not in category_types:
        category_types[category_name] = []

    if type_name in category_types[category_name]:
        return jsonify({"message": "Type already exists in this category"}), 400

    # Add the type and save
    category_types[category_name].append(type_name)
    save_category_types(category_name, [type_name])
    return jsonify({"message": "Type added successfully"}), 200

def generate_confirmation_token(email):
    serializer = URLSafeTimedSerializer(app.config['JWT_SECRET_KEY']) 
    return serializer.dumps(email, salt='email-confirmation-salt')

def confirm_token(token, expiration=3600):
    serializer = URLSafeTimedSerializer(app.config['JWT_SECRET_KEY'])  
    try:
        email = serializer.loads(
            token,
            salt='email-confirmation-salt',
            max_age=expiration
        )
        print(f"Token is valid. Email: {email}")
    except Exception as e:
        print(f"Error in token validation: {str(e)}")
        return None
    return email

@app.route('/signup', methods=['POST'])
def signup():
    db = cursor = None
    try:
        data = request.json
        if not data:
            return jsonify({"error": "Missing JSON data"}), 400

        name, email, password, role = data.get('name'), data.get('email'), data.get('password'), data.get('role')
        if not all([name, email, password, role]):
            return jsonify({"error": "Missing one or more required fields"}), 400

        ip_address = request.remote_addr
        db = get_db_connection()
        cursor = db.cursor()

        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        user = cursor.fetchone() 

        if user is not None:
         return jsonify({"message": "Email already registered"}), 400


        password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
        cursor.execute("INSERT INTO users (name, email, password_hash, role, is_verified) VALUES (%s, %s, %s, %s, FALSE)",
                       (name, email, password_hash, role))
        user_id = cursor.lastrowid

        cursor.execute("INSERT INTO signup_details (user_id, ip_address) VALUES (%s, %s)", (user_id, ip_address))
        db.commit()

        token = generate_confirmation_token(email)
        verify_url = url_for('verify_email', token=token, _external=True)

        if not send_verification_email(email, verify_url):
            return jsonify({"message": "Signup successful, but verification email failed."}), 500

        return jsonify({"message": "Signup successful. Please check your email to verify your account."}), 201

    except Exception as e:
        print(f"Error during signup: {str(e)}")
        return jsonify({"error": "An error occurred during signup."}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()




# Login API

@app.route('/login', methods=['POST'])
def login():
    db = cursor = None
    try:
        data = request.json
        if not data:
            return jsonify({"error": "Missing JSON data"}), 400

        email, password = data.get('email'), data.get('password')
        ip_address = request.remote_addr

        db = get_db_connection()
        cursor = db.cursor()
        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user or not bcrypt.check_password_hash(user['password_hash'], password):
            if user:
                cursor.execute("INSERT INTO login_details (user_id, ip_address, status) VALUES (%s, %s, 'Failed')", 
                               (user['id'], ip_address))
                db.commit()
            return jsonify({"message": "Invalid email or password"}), 401

        if not user.get('is_verified', False):
            return jsonify({"message": "Please verify your email before logging in."}), 403

        token = create_access_token(identity={"id": user["id"], "email": user["email"], "role": user["role"]},
                                    expires_delta=timedelta(hours=2))

        cursor.execute("INSERT INTO login_details (user_id, ip_address, status) VALUES (%s, %s, 'Success')",
                       (user["id"], ip_address))
        db.commit()

        return jsonify({
            "message": "Login successful",
            "token": token,
            "role": user["role"],
            "user_id": user["id"]
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

    finally:
        if cursor: cursor.close()
        if db: db.close()


        

# Function to send verification email
def send_verification_email(to_email, verify_link):
    sender_email = os.getenv("EMAIL_USER", "singh26mansi02@gmail.com")
    sender_password = os.getenv("EMAIL_PASS", "fsjk wewt fnpy gino")

    try:
        msg = MIMEMultipart()
        msg["From"] = sender_email
        msg["To"] = to_email
        msg["Subject"] = "Email Verification Request"

        body = f"""
        Thank you for signing up!
        Please click the link below to verify your email address:

        {verify_link}

        If you did not sign up, please ignore this email.

        Note: This link will expire in 1 hour.
        """
        msg.attach(MIMEText(body, "plain"))

        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.sendmail(sender_email, to_email, msg.as_string())

        print("Verification email sent successfully!")
        return True
    except Exception as e:
        print(f"Error sending email: {str(e)}")
        return False




@app.route('/verify_email/<token>', methods=['GET'])
def verify_email(token):
    db = cursor = None
    try:
        email = confirm_token(token)

        if not email:
            return render_template_string("<h3 style='color:red;'>❌ Invalid or expired token.</h3>")

        db = get_db_connection()
        cursor = db.cursor()

        cursor.execute("SELECT id FROM users WHERE email = %s", (email,))
        user = cursor.fetchone()

        if not user:
            return render_template_string("<h3 style='color:red;'>❌ User not found.</h3>")

        cursor.execute("UPDATE users SET is_verified = TRUE WHERE email = %s", (email,))
        db.commit()

        # ✅ Success UI in HTML directly from Python
        return render_template_string("""
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <title>Email Verified</title>
            <style>
                body {
                    background: linear-gradient(135deg, #84fab0, #8fd3f4);
                    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                    text-align: center;
                    padding-top: 80px;
                    color: #333;
                }
                .card {
                    background: white;
                    padding: 40px;
                    border-radius: 15px;
                    box-shadow: 0 10px 25px rgba(0,0,0,0.2);
                    display: inline-block;
                }
                h1 {
                    color: #2ecc71;
                    font-size: 32px;
                    margin-bottom: 15px;
                }
                p {
                    font-size: 18px;
                    margin-top: 0;
                }
                .btn {
                    display: inline-block;
                    margin-top: 25px;
                    padding: 12px 24px;
                    background-color: #2ecc71;
                    color: white;
                    text-decoration: none;
                    border-radius: 8px;
                    transition: background 0.3s;
                }
                .btn:hover {
                    background-color: #27ae60;
                }
            </style>
        </head>
        <body>
            <div class="card">
                <h1>✅ Email Verified!</h1>
                <p>Go ahead and log in to start your journey with us.</p>
                <p>Go Back To The LogIn Page of UpGyaan</p>
               
            </div>
        </body>
        </html>
        """)

    except Exception as e:
        return render_template_string(f"<h3 style='color:red;'>⚠️ Error occurred: {str(e)}</h3>")

    finally:
        if cursor: cursor.close()
        if db: db.close()




# Function to send reset email
def send_reset_email(to_email, reset_link):
    sender_email = os.getenv("EMAIL_USER", "singh26mansi02@gmail.com")
    sender_password = os.getenv("EMAIL_PASS", "fsjk wewt fnpy gino")  

    try:
        msg = MIMEMultipart()
        msg["From"] = sender_email
        msg["To"] = to_email
        msg["Subject"] = "Password Reset Request"

        # Email body
        body = f"""
        You requested a password reset.
        Click the link below to reset your password:
        
        {reset_link}
        
        If you did not request this, please ignore this email.
        
        Note: This link will expire in 10 minutes.
        """
        msg.attach(MIMEText(body, "plain"))  

        with smtplib.SMTP("smtp.gmail.com", 587) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            server.sendmail(sender_email, to_email, msg.as_string())

        print("Reset email sent successfully!")
        return True
    except Exception as e:
        print("Error sending email:", str(e)) 
        return False


# ✅ Forgot Password API (User Requests Reset)
@app.route('/forgot-password', methods=['POST'])
def forgot_password():
    data = request.get_json()
    email = data.get("email")

    try:
        db = get_db_connection()
        cursor = db.cursor()
        cursor.execute("SELECT * FROM users WHERE email=%s", (email,))
        user = cursor.fetchone()

        if not user:
            return jsonify({"status": "error", "message": "Email not registered!"}), 400

        # Generate reset token
        token = serializer.dumps(email, salt="password-reset")
    
        reset_link = f"http://localhost:5000/#/reset-password?token={token}"
      
  

        if send_reset_email(email, reset_link):
            return jsonify({"status": "success", "message": "Password reset link sent!"})
        else:
            return jsonify({"status": "error", "message": "Failed to send email!"}), 500

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)}), 500

    finally:
        cursor.close()
        db.close()

@app.route('/reset-password', methods=['POST'])
@cross_origin()
def reset_password():
    print("🔔 /reset-password API hit!") 
    try:
        data = request.get_json(force=True)
        print("Received data:", data)
        token = request.args.get("token")
        new_password = data.get("new_password")

        if not token:
            return jsonify({"status": "error", "message": "Missing token"}), 400
        if not new_password:
            return jsonify({"status": "error", "message": "Missing new password"}), 400

        email = serializer.loads(token, salt="password-reset", max_age=3600)
     
        password_hash = bcrypt.generate_password_hash(new_password).decode('utf-8')


        db = get_db_connection()
        cursor = db.cursor()
        cursor.execute("UPDATE users SET password_hash = %s WHERE email = %s", (password_hash, email))
        db.commit()

        return jsonify({"status": "success", "message": "Password reset successful!"})

    except Exception as e:
        print("🔥 Reset Password Error:", str(e))
        return jsonify({"status": "error", "message": str(e)}), 500

    finally:
        if 'cursor' in locals(): cursor.close()
        if 'db' in locals(): db.close()

@app.route('/menus', methods=['POST'])
def add_menu():
    try:
        data = request.get_json()
        print("Received data:", data)

        category = data.get("category")
        course_name = data.get("course_name")
        status = data.get("status", "True")
        menu_type = data.get("type")

        db = get_db_connection()
        cursor = db.cursor()
        cursor.execute("""
            INSERT INTO menus (category, course_name, status, created_at, type)
            VALUES (%s, %s, %s, NOW(), %s)
        """, (category, course_name, status, menu_type))
        db.commit()

        return jsonify({"message": "Menu added successfully"}), 201

    except Exception as e:
        print("Flask Error:", str(e))
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        db.close()



# Get all menus
@app.route('/menus', methods=['GET'])
def get_menus():
    db = get_db_connection()
    cursor = db.cursor()  # ✅ Important change
    cursor.execute("SELECT * FROM menus WHERE status = 'True'")
    menus = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(menus)


# Add a new course
@app.route('/courses', methods=['POST'])
def add_course():
    try:
        data = request.get_json()
        print("Received course data:", data)

        course_name = data.get("course_name")
        title = data.get("title")
        description = data.get("description")
        status = data.get("status", "True")
        duration = data.get("duration")

        db = get_db_connection()
        cursor = db.cursor()
        cursor.execute("""
            INSERT INTO courses (course_name, title, description, status, duration)
            VALUES (%s, %s, %s, %s, %s)
        """, (course_name, title, description, status, duration))
        db.commit()

        return jsonify({"message": "Course added successfully"}), 201

    except Exception as e:
        print("Flask Error:", str(e))
        return jsonify({"error": str(e)}), 500

    finally:
        cursor.close()
        db.close()

        
# Flask route example
@app.route('/course-detail/<course_name>', methods=['GET'])
def course_detail(course_name):
    db = get_db_connection()
    cursor = db.cursor()  
    query = "SELECT * FROM courses WHERE course_name = %s"
    cursor.execute(query, (course_name,))
    course = cursor.fetchone()
    cursor.close()
    if course:
        return jsonify(dict(course))
    else:
        return jsonify({'error': 'Course not found'}), 404
    
@app.route('/course-content/<course_name>', methods=['GET'])
def course_content(course_name):
    db = get_db_connection()
    cursor = db.cursor()  

    # Step 1: Get course_id using course_name
    cursor.execute("SELECT id FROM courses WHERE course_name = %s", (course_name,))
    course = cursor.fetchone()

    if not course:
        cursor.close()
        return jsonify({'error': 'Course not found'}), 404

    course_id = course['id']
    print("Course ID:", course_id)

    # Step 2: Get course content using course_id
    cursor.execute("SELECT id, topic_title, video_url FROM course_contents WHERE course_id = %s", (course_id,))
    contents = cursor.fetchall()
    cursor.close()

    return jsonify(contents)




@app.route('/submit_course_content', methods=['POST'])
def submit_course_content():
    data = request.get_json()

    course_name = data.get('course_name')
    topics = data.get('topics')  # List of topic dictionaries

    if not course_name or not topics:
        return jsonify({"error": "Missing course_name or topics"}), 400

    try:
        db = get_db_connection()
        cursor = db.cursor()

        # Get course_id from course_name
        cursor.execute("SELECT id FROM courses WHERE course_name LIKE %s", (course_name,))

        result = cursor.fetchone()

        if not result:
            return jsonify({"error": f"No course found with name: {course_name}"}), 404

        course_id = result['id']
        print("Course ID:", course_id)

        for topic in topics:
            topic_title = topic.get('topic_title')
            video_url = topic.get('video_url')

            if topic_title and video_url:
                cursor.execute(
                    "INSERT INTO course_contents (course_id, course_name, topic_title, video_url) VALUES (%s, %s, %s, %s)",
                    (course_id, course_name, topic_title, video_url)
                )

        db.commit()
        cursor.close()
        db.close()
        return jsonify({"message": "Course content added successfully"}), 200

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": str(e)}), 500



    
@app.route('/routes', methods=['GET'])
def show_routes():
    import urllib
    routes = []
    for rule in app.url_map.iter_rules():
        routes.append({
            'endpoint': rule.endpoint,
            'methods': list(rule.methods),
            'route': urllib.parse.unquote(str(rule))
        })
    return jsonify(routes)



# Get all courses
@app.route('/courses', methods=['GET'])
def get_courses():
    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM courses WHERE status='True'")
    courses = cursor.fetchall()
    cursor.close()
    db.close()
    return jsonify(courses)


@app.route('/enroll', methods=['POST'])
def enroll_course():
    data = request.get_json()
    user_email = data.get('user_email')
    course_name = data.get('course_name')
    
    db = get_db_connection()
    cursor = db.cursor()

    # 🔍 STEP 1: Check if already enrolled
    check_query = "SELECT * FROM enrollments WHERE user_email=%s AND course_name=%s"
    cursor.execute(check_query, (user_email, course_name))
    existing = cursor.fetchone()

    if existing:
        cursor.close()
        db.close()
        return jsonify({"status": "failed", "message": "Already enrolled"})

    # ✅ STEP 2: Proceed with enrollment
    enroll_query = "INSERT INTO enrollments (user_email, course_name, enrolled_at) VALUES (%s, %s, NOW())"
    cursor.execute(enroll_query, (user_email, course_name))
    db.commit()

    cursor.close()
    db.close()

    return jsonify({"status": "success", "message": "Enrolled successfully"})


@app.route('/get-enrolled-courses/<user_email>', methods=['GET'])
def get_enrolled_courses(user_email):
    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT course_name, enrolled_at FROM enrollments WHERE user_email = %s", (user_email,))
    enrolled_courses = cursor.fetchall()
    cursor.close()
    db.close()

    return jsonify(enrolled_courses)

@app.route('/mark-watched', methods=['POST'])
def mark_watched():
    data = request.get_json()
    email = data['user_email']
    course = data['course_name']
    topic = data['topic_title']
    db = get_db_connection()
    cursor = db.cursor()
    
    cursor.execute("SELECT * FROM course_progress WHERE user_email=%s AND course_name=%s AND topic_title=%s", 
                   (email, course, topic))
    if cursor.fetchone() is None:
        cursor.execute("INSERT INTO course_progress (user_email, course_name, topic_title, watched) VALUES (%s, %s, %s, TRUE)",
                       (email, course, topic))
        db.commit()

    return jsonify({'status': 'success'})

@app.route('/get-watched-topics', methods=['GET'])
def get_watched_topics():
    email = request.args.get('user_email')
    course = request.args.get('course_name')

    if not email or not course:
        return jsonify({'error': 'Missing user_email or course_name in query params'}), 400

    db = get_db_connection()
    cursor = db.cursor()
    
    cursor.execute(
        "SELECT topic_title FROM course_progress WHERE user_email=%s AND course_name=%s AND watched=TRUE", 
        (email, course)
    )
    results = cursor.fetchall()

    print("RESULTS:", results)  # Debug line

    watched_topics = [row['topic_title'] for row in results]  # ✅ right


    return jsonify({'watched_topics': watched_topics})




@app.route('/check_enrollment', methods=['POST'])
def check_enrollment():
    data = request.get_json()
    user_email = data.get('user_email')
    course_name = data.get('course_name')

    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM enrollments WHERE user_email=%s AND course_name=%s", (user_email, course_name))
    result = cursor.fetchone()
    cursor.close()

    if result:
        return jsonify({'enrolled': True})
    else:
        return jsonify({'enrolled': False})
    

@app.route('/course-content/<int:content_id>', methods=['PUT'])
def update_course_content(content_id):
    data = request.get_json()
    topic = data['topic_title']
    video_url = data['video_url']

    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(
        "UPDATE course_contents SET topic_title = %s, video_url = %s WHERE id = %s",
        (topic, video_url, content_id)
    )
    conn.commit()
    conn.close()
    return jsonify({"message": "Course content updated successfully"})

# DELETE: Single Course Content by ID
@app.route('/course-content/<int:id>', methods=['DELETE'])
def delete_course_content(id):
    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("DELETE FROM course_contents WHERE id = %s", (id,))
    db.commit()
    db.close()
    return jsonify({"message": "Course content deleted successfully"})


@app.route('/generate_certificate', methods=['POST'])
def generate_certificate():
    data = request.get_json()
    user_id = data.get('user_id')
    course_id = data.get('course_id')

    if not user_id or not course_id:
        return jsonify({'error': 'Missing user_id or course_id'}), 400

    try:
        db = get_db_connection()
        db.autocommit(True)  # Prevent locking issues
        cursor = db.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SET innodb_lock_wait_timeout = 3")  # reduce lock wait time

        # Step 1: Fetch user name
        cursor.execute("SELECT name FROM users WHERE id = %s", (user_id,))
        user = cursor.fetchone()
        if not user:
            return jsonify({'error': 'User not found'}), 404
        user_name = user['name']

        # Step 2: Fetch course name
        cursor.execute("SELECT course_name FROM courses WHERE id = %s", (course_id,))
        course = cursor.fetchone()
        if not course:
            return jsonify({'error': 'Course not found'}), 404
        course_name = course['course_name']

        # Step 3: Check if certificate already exists
        cursor.execute("SELECT certificate_url FROM certificates WHERE user_id=%s AND course_id=%s", (user_id, course_id))
        existing = cursor.fetchone()

        if existing:
            return jsonify({'certificate_url': existing['certificate_url'], 'message': 'Certificate already exists'}), 200

        # Step 4: Generate the certificate image
        cert_filename = f"{user_id}_{course_id}.png"
        cert_path = f"certificates/certificate/{cert_filename}"
        generate_certificate_image(user_name, course_name, cert_path)

        # Step 5: Build certificate URL
        cert_url = f"http://127.0.0.1:5000/download_certificate/{cert_filename}"
        #host_url = request.host_url.rstrip('/')
        #cert_url = f"{host_url}/download_certificate/{cert_filename}" 
        # Step 6: Insert into DB
        cursor.execute("""
            INSERT INTO certificates (user_id, course_id, issued_at, certificate_url)
            VALUES (%s, %s, NOW(), %s)
        """, (user_id, course_id, cert_url))

        return jsonify({'certificate_url': cert_url, 'message': 'Certificate generated successfully'}), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500



# Certificate Image Generator Function
def generate_certificate_image(user_name, course_name, file_path):
    width, height = 1000, 700
    image = Image.new('RGB', (width, height), 'white')
    draw = ImageDraw.Draw(image)

    try:
        title_font = ImageFont.truetype("arialbd.ttf", 50)
        name_font = ImageFont.truetype("arialbd.ttf", 40)
        info_font = ImageFont.truetype("arial.ttf", 30)
        small_font = ImageFont.truetype("arial.ttf", 22)
    except:
        title_font = name_font = info_font = small_font = ImageFont.load_default()

    # --- Draw border ---
    border_color = (19, 105, 97)
    border_thickness = 10
    draw.rectangle([border_thickness, border_thickness, width - border_thickness, height - border_thickness], outline=border_color, width=border_thickness)

    # --- Add logo ---
    try:
        logo = Image.open("logo2.png")  # Place this logo file in the same backend directory
        logo = logo.resize((100, 100))
        image.paste(logo, (width - 140, 30))
    except Exception as e:
        print("Logo not found or error loading:", e)

    # --- Title text center ---
    title_text = "Certificate of Completion"
    bbox = draw.textbbox((0, 0), title_text, font=title_font)
    title_w = bbox[2] - bbox[0]
    draw.text(((width - title_w) / 2, 80), title_text, font=title_font, fill="black")

    # --- Certificate content ---
    y = 200
    for text, font, color in [
        ("This is to certify that", info_font, "black"),
        (user_name, name_font, border_color),
        ("has successfully completed the course", info_font, "black"),
        (course_name, name_font, border_color),
        (f"on {datetime.now().strftime('%d %B %Y')}", info_font, "black"),
    ]:
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        draw.text(((width - text_w) / 2, y), text, font=font, fill=color)
        y += 70

    # Signature line
    draw.line([(100, 600), (300, 600)], fill="black", width=2)
    draw.text((100, 610), "Authorized Signature", font=small_font, fill="black")

    os.makedirs(os.path.dirname(file_path), exist_ok=True)
    image.save(file_path)




# Endpoint: Serve the Certificate Image File
@app.route('/download_certificate/<filename>')
def download_certificate(filename):
    certificate_folder = os.path.join(os.getcwd(), 'certificates/certificate')
    return send_from_directory(certificate_folder, filename, as_attachment=True)



    
@app.route('/get_course_id', methods=['POST'])
def get_course_id():
    data = request.get_json()
    course_name = data.get('course_name')

    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT id FROM courses WHERE course_name = %s", (course_name,))
    result = cursor.fetchone()

    if result:
        return jsonify({'course_id': result['id']})
    else:
        return jsonify({'error': 'Course not found'}), 404
    
@app.route('/get_jobs', methods=['GET'])
def get_jobs():
    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM jobs")
    jobs = cursor.fetchall()
    cursor.close()
    return jsonify(jobs)



@app.route('/jobs', methods=['POST'])
def add_job():
    data = request.get_json()
    job_title = data.get('job_title')
    company_name = data.get('company_name')
    job_location = data.get('job_location')
    job_type = data.get('job_type')
    apply_link = data.get('apply_link')
    
    db = get_db_connection()
    cursor = db.cursor()
    query = "INSERT INTO jobs (job_title, company_name, job_location, job_type, apply_link) VALUES (%s, %s, %s, %s, %s)"
    values = (job_title, company_name, job_location, job_type, apply_link)

    cursor.execute(query, values)
    db.commit()

    return jsonify({'message': 'Job added successfully'}), 201

@app.route('/chat', methods=['POST'])
def chat():
    data = request.get_json()
    user_id = data.get("user_id")        # ✅ Get user_id from frontend
    question = data.get("question")

    db = get_db_connection()
    cursor = db.cursor()

    if not user_id or not question:
        return jsonify({"error": "Missing user_id or question"}), 400

    prompt = f"""You are an expert tutor. Provide a simple, clear, and easy-to-understand answer to the question below.
    Avoid using any special characters like asterisks (*), bullet points, or markdown formatting. Just write clean, attractive text.

    Question: {question}"""

    # ✅ Get response from Azure OpenAI
    response = client.chat.completions.create(
        model=azure_oai_deployment,
        max_tokens=500,
        messages=[
            {"role": "system", "content": "You are a prominent teacher and an educator."},
            {"role": "user", "content": prompt}
        ]
    )

    result = response.choices[0].message.content.strip()

    # ✅ Save chat history to MySQL
    insert_query = """
        INSERT INTO chat_history (user_id, question, response)
        VALUES (%s, %s, %s)
    """
    cursor.execute(insert_query, (user_id, question, result))
    db.commit()
    current_time = datetime.now().strftime("%I:%M %p")

    return jsonify({"response": result,  "time": current_time})

@app.route("/get_chat_history/<user_id>", methods=["GET"])
def get_chat_history(user_id):
    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute(
        "SELECT question, response, timestamp FROM chat_history WHERE user_id = %s ORDER BY timestamp ASC",
        (user_id,)
    )
    rows = cursor.fetchall()

    messages = []
    for row in rows:
        user_time = row["timestamp"].strftime("%I:%M %p")
        messages.append({"sender": "user", "text": row["question"], "time": user_time})
        messages.append({"sender": "bot", "text": row["response"], "time": user_time})

    return jsonify({"messages": messages})

@app.route("/add_quiz", methods=["POST"])
def add_quiz():
    try:
        data = request.get_json()

        course_name = data.get("course_name")
        quiz_title = data.get("quiz_title")
        questions = data.get("questions")

        if not (course_name and quiz_title and questions):
            return jsonify({"error": "Missing required fields"}), 400

        db = get_db_connection()
        cursor = db.cursor()

        # Get course_id
        cursor.execute("SELECT id FROM courses WHERE course_name = %s", (course_name,))
        course = cursor.fetchone()

        if not course:
            return jsonify({"error": "Course not found"}), 404

        course_id = course["id"]  # Fixed here
        questions_json = json.dumps(questions)

        cursor.execute("""
            INSERT INTO quizzes (course_id, course_name, quiz_title, questions)
            VALUES (%s, %s, %s, %s)
        """, (course_id, course_name, quiz_title, questions_json))

        db.commit()
        cursor.close()
        db.close()

        return jsonify({"message": "Quiz added successfully!"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route("/get_quiz_by_course_name/<course_name>", methods=["GET"])
def get_quiz_by_course_name(course_name):
    db = get_db_connection()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM quizzes WHERE course_name = %s", (course_name,))
    quiz = cursor.fetchone()
    cursor.close()
    db.close()

    if quiz:
        quiz["questions"] = json.loads(quiz["questions"])
        return jsonify(quiz)
    return jsonify({"message": "Quiz not found"}), 404


@app.route("/submit_quiz", methods=["POST"])
def submit_quiz():
    data = request.get_json()
    user_answers = data["answers"]
    course_name = data["course_name"]
    user_id = data["user_id"]

    db = get_db_connection()
    cursor = db.cursor(dictionary=True)

    # 🔍 Get course_id from course_name
    cursor.execute("SELECT id FROM courses WHERE course_name = %s", (course_name,))
    course = cursor.fetchone()
    if not course:
        return jsonify({"error": "Course not found"}), 404

    course_id = course["id"]

    # 🔍 Fetch quiz
    cursor.execute("SELECT questions FROM quizzes WHERE course_id = %s", (course_id,))
    quiz = cursor.fetchone()

    correct = 0
    if quiz:
        questions = json.loads(quiz["questions"])
        for i, q in enumerate(questions):
            if i < len(user_answers) and user_answers[i] == q["answer"]:
                correct += 1

        percentage = (correct / len(questions)) * 100
        passed = percentage >= 60

        if passed:
            cursor.execute("""
                INSERT INTO passed_quizzes (user_id, course_id)
                VALUES (%s, %s)
                ON DUPLICATE KEY UPDATE course_id = course_id
            """, (user_id, course_id))
            db.commit()

        return jsonify({"passed": passed, "score": percentage})

    return jsonify({"message": "Quiz not found"}), 404



# Run Flask Server
if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)  
