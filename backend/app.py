import json, datetime, io
from flask import Flask, jsonify, request, send_file
from db import  User, Profile, Course, StudyArea, StudyTime, Major, Message, Meeting, UserMatchStatus, Match, db

app = Flask(__name__)
app.config["SQLALCHEMY_DATABASE_URI"] = "sqlite:///app.db"
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
db.init_app(app)
with app.app_context():
    db.create_all()

# Generalized success response.
def success_response(data, code=200):
    return jsonify(data), code

# Generalized failure response.
def failure_response(data, code=404):
    return json.dumps({"error": data}), code

MAX_PROFILE_IMAGE_BYTES = 5 * 1024 * 1024  # 5MB cap for avatar blobs

@app.route("/signup/", methods=["POST"])
def signup():
    """
    Creates an account with the provided username, email, & password.
    Request body:
    {
        username: <STRING, required>,
        email: <STRING, required>,
        password: <STRING, required>
    }
    Make sure to include both, otherwise will return error 400.
    """
    body = json.loads(request.data)
    username = body.get("username")
    email = body.get("email")
    password = body.get("password")

    if not username or not password:
        return failure_response("username and password are required", 400)

    if User.query.filter_by(email=email).first():
        return failure_response("user already exists", 409)
        
    if User.query.filter_by(username=username).first():
        return failure_response("username already exists", 409)
        
    user = User(username=username, email=email, password=password)
    db.session.add(user)
    db.session.commit()
    return success_response(user.serialize(), 201)

@app.route("/login/")
def login():
    """
    Logs in with the provided username & password.
    Request body:
    {
        username: <STRING, required>,
        password: <STRING, required>
    }
    Make sure to include both, otherwise will return error 400.
    """
    body = json.loads(request.data)
    username = body.get("username")
    password = body.get("password")

    if not username or not password:
        return failure_response("username and password are required", 400)

    user = User.query.filter_by(username=username).first()
    if user is None or user.password != password:
        return failure_response("invalid credentials", 401)

    return success_response(user.serialize())

@app.route("/users/<int:id>")
def get_user(id):
    user = User.query.filter_by(id=id).first()
    if user is None:
        return failure_response("user not found", 404)
    return success_response(user.serialize())

@app.route("/users/", methods=["GET"])
def get_all_users():
    """
    Retrieves all users.
    """
    users = User.query.all()
    return success_response([u.serialize() for u in users])

@app.route("/users/<int:id>/", methods=["GET"])
def get_user_with_trailing(id):
    """
    Retrieves a user by id (trailing slash variant).
    """
    user = User.query.get(id)
    if user is None:
        return failure_response("user not found", 404)
    return success_response(user.serialize())

@app.route("/courses/", methods=["POST"])
def post_course():
    """
    Creates a course.
    Request body:
    {
        "code": <STRING, required>
    }
    """
    body = json.loads(request.data)
    code = body.get("code")
    if not code:
        return failure_response("code is required", 400)

    if Course.query.filter_by(code=code).first():
        return failure_response("course already exists", 409)

    course = Course(code=code)
    db.session.add(course)
    db.session.commit()
    return success_response(course.serialize(), 201)


@app.route("/courses/<int:id>/")
def get_course(id):
    """
    Retrieves a course by id.
    """
    course = Course.query.get(id)
    if not course:
        return failure_response("course not found", 404)
    return success_response(course.serialize())

@app.route("/courses/")
def get_all_courses():
    """
    Retrieves all courses.
    """
    courses = Course.query.all()
    return success_response([c.serialize() for c in courses])

@app.route("/majors/", methods=["POST"])
def post_major():
    """
    Creates a major.
    Request body:
    {
        "name": <STRING, required>
    }
    """
    body = json.loads(request.data)
    name = body.get("name")
    if not name:
        return failure_response("name is required", 400)

    if Major.query.filter_by(name=name).first():
        return failure_response("major already exists", 409)

    major = Major(name=name)
    db.session.add(major)
    db.session.commit()
    return success_response(major.serialize(), 201)


@app.route("/majors/<int:id>/")
def get_major(id):
    """
    Retrieves a major by id.
    """
    major = Major.query.get(id)
    if not major:
        return failure_response("major not found", 404)
    return success_response(major.serialize())

@app.route("/majors/")
def get_all_majors():
    """
    Retrieves all majors.
    """
    majors = Major.query.all()
    return success_response([m.serialize() for m in majors])

@app.route("/areas/", methods=["POST"])
def post_area():
    """
    Creates a study area.
    Request body:
    {
        "name": <STRING, required>
    }
    """
    body = json.loads(request.data)
    name = body.get("name")
    if not name:
        return failure_response("name is required", 400)

    if StudyArea.query.filter_by(name=name).first():
        return failure_response("study area already exists", 409)

    area = StudyArea(name=name)
    db.session.add(area)
    db.session.commit()
    return success_response(area.serialize(), 201)


@app.route("/areas/<int:id>/")
def get_area(id):
    """
    Retrieves a study area by id.
    """
    area = StudyArea.query.get(id)
    if not area:
        return failure_response("study area not found", 404)
    return success_response(area.serialize())

@app.route("/areas/")
def get_all_areas():
    """
    Retrieves all study areas.
    """
    areas = StudyArea.query.all()
    return success_response([a.serialize() for a in areas])

@app.route("/times/", methods=["POST"])
def post_time():
    """
    Creates a study time option (e.g., morning, afternoon, evening).
    Request body:
    {
        "name": <STRING, required>
    }
    """
    body = json.loads(request.data)
    name = body.get("name")
    if not name:
        return failure_response("name is required", 400)

    if StudyTime.query.filter_by(name=name).first():
        return failure_response("study time already exists", 409)

    time = StudyTime(name=name)
    db.session.add(time)
    db.session.commit()
    return success_response(time.serialize(), 201)


@app.route("/times/<int:id>/")
def get_time(id):
    """
    Retrieves a study time by id.
    """
    time = StudyTime.query.get(id)
    if not time:
        return failure_response("study time not found", 404)
    return success_response(time.serialize())

@app.route("/times/")
def get_all_times():
    """
    Retrieves all study times.
    """
    times = StudyTime.query.all()
    return success_response([t.serialize() for t in times])

@app.route("/profiles/", methods=["POST"])
def create_profile():
    """
    Creates a profile for a user.
    Request body:
    {
        "user_id": <INT, required>,
        "study_area_id": <INT, required>,
        "course_ids": <[INT], required>,
        "study_time_ids": <[INT], required>,
        "major_ids": <[INT], required>
    }
    """
    body = json.loads(request.data)

    user_id = body.get("user_id")
    if user_id is None:
        return failure_response("user_id is required", 400)

    user = User.query.filter_by(id=user_id).first()
    if not user:
        return failure_response("user not found")
    if user.profile:
        return failure_response("profile already exists for user", 409)

    study_area_id = body.get("study_area_id")
    if study_area_id is None :
        return failure_response("study_area_id is required", 400)
    study_area = StudyArea.query.filter_by(id=study_area_id).first()
    if study_area is None:
        return failure_response("study area not found")
    
    def gather_related(model, ids, label):
        if ids is None:
            return []
        if not isinstance(ids, list):
            raise ValueError(f"{label} must be a list")
        records = []
        missing = []
        for item_id in ids:
            obj = model.query.get(item_id)
            if obj:
                records.append(obj)
            else:
                missing.append(item_id)
        if missing:
            raise LookupError(f"invalid {label}: {missing}")
        return records

    try:
        courses = gather_related(Course, body.get("course_ids"), "course_ids")
        study_times = gather_related(StudyTime, body.get("study_time_ids"), "study_time_ids")
        majors = gather_related(Major, body.get("major_ids"), "major_ids")
    except ValueError as ve:
        return failure_response(str(ve), 400)
    except LookupError as le:
        return failure_response(str(le))

    profile = Profile(
        user_id=user_id,
        study_area_id=study_area_id,
        study_area=study_area,
        courses=courses,
        study_times=study_times,
        majors=majors,
    )

    db.session.add(profile)
    db.session.commit()
    return success_response(profile.serialize(), 201)

@app.route("/profiles/")
def get_all_profiles():
    """
    Retrieves all profiles.
    """
    profiles = Profile.query.all()
    return success_response([p.serialize() for p in profiles])

@app.route("/profiles/<int:id>/")
def get_profile(id):
    """
    Retrieves a profile by id.
    """
    profile = Profile.query.get(id)
    if not profile:
        return failure_response("profile not found", 404)
    return success_response(profile.serialize())

@app.route("/profiles/<int:id>/", methods=["PUT"])
def update_profile(id):
    """
    Updates a profile by id. Provide any of the fields to update.
    Request body:
    {
        "study_area_id": <INT>,
        "course_ids": <[INT]>,
        "study_time_ids": <[INT]>,
        "major_ids": <[INT]>
    }
    """
    profile = Profile.query.get(id)
    if not profile:
        return failure_response("profile not found", 404)

    body = json.loads(request.data or "{}")

    def gather_related(model, ids, label):
        if ids is None:
            return None
        if not isinstance(ids, list):
            raise ValueError(f"{label} must be a list")
        records = []
        missing = []
        for item_id in ids:
            obj = model.query.get(item_id)
            if obj:
                records.append(obj)
            else:
                missing.append(item_id)
        if missing:
            raise LookupError(f"invalid {label}: {missing}")
        return records

    if "study_area_id" in body:
        study_area_id = body.get("study_area_id")
        if study_area_id is None:
            profile.study_area = None
            profile.study_area_id = None
        else:
            area = StudyArea.query.get(study_area_id)
            if not area:
               return failure_response("study area not found", 404)
            profile.study_area = area
            profile.study_area_id = study_area_id

    try:
        courses = gather_related(Course, body.get("course_ids"), "course_ids")
        study_times = gather_related(StudyTime, body.get("study_time_ids"), "study_time_ids")
        majors = gather_related(Major, body.get("major_ids"), "major_ids")
    except ValueError as ve:
        return failure_response(str(ve), 400)
    except LookupError as le:
        return failure_response(str(le))

    if courses is not None:
        profile.courses = courses
    if study_times is not None:
        profile.study_times = study_times
    if majors is not None:
        profile.majors = majors

    db.session.commit()
    return success_response(profile.serialize())


@app.route("/profiles/<int:id>/image/", methods=["POST"])
def upload_profile_image(id):
    """
    Uploads a profile image as a blob for a given profile.
    Multipart form field: "image" (Use 'image' as the key when inputting)
    """
    profile = Profile.query.get(id)
    if not profile:
        return failure_response("profile not found", 404)

    file = request.files.get("image")
    if not file or file.filename == "":
        return failure_response("image is required", 400)

    content = file.read()
    if not content:
        return failure_response("image is empty", 400)
    if len(content) > MAX_PROFILE_IMAGE_BYTES:
        return failure_response("file too large", 400)

    profile.profile_image_blob = content
    profile.profile_image_mime = file.mimetype or "application/octet-stream"
    db.session.commit()

    return success_response(
        {
            "profile_id": profile.id,
            "profile_image_blob_url": f"/profiles/{profile.id}/image/",
            "mime": profile.profile_image_mime,
        },
        201,
    )


@app.route("/profiles/<int:id>/image/")
def get_profile_image(id):
    """
    Retrieves the profile image blob.
    """
    profile = Profile.query.get(id)
    if not profile or not profile.profile_image_blob:
        return failure_response("image not found", 404)

    return send_file(
        io.BytesIO(profile.profile_image_blob),
        mimetype=profile.profile_image_mime or "application/octet-stream",
    )


@app.route("/messages/", methods=["POST"])
def send_message():
    """
    Sends a message from one user to another.
    Request body:
    {
        "sender_id": <INT, required>,
        "receiver_id": <INT, required>,
        "content": <STRING, required>
    }
    """
    body = json.loads(request.data)
    sender_id = body.get("sender_id")
    receiver_id = body.get("receiver_id")
    content = body.get("content")

    if not sender_id or not receiver_id or not content:
        return failure_response("sender_id, receiver_id, and content are required", 400)

    sender = User.query.get(sender_id)
    receiver = User.query.get(receiver_id)

    if not sender or not receiver:
        return failure_response("Sender or receiver not found", 404)
        
    if sender_id == receiver_id:
        return failure_response("Cannot send a message to yourself", 400)

    message = Message(
        sender_id=sender_id,
        receiver_id=receiver_id,
        content=content
    )
    
    db.session.add(message)
    db.session.commit()
    
    return success_response(message.serialize(), 201)

@app.route("/users/<int:user_id>/messages/")
def get_user_messages(user_id):
    """
    Retrieves all messages sent to and received by a specific user, sorted by timestamp.
    """
    user = User.query.get(user_id)
    if not user:
        return failure_response("User not found", 404)

    # Query for messages sent *or* received by the user
    messages = Message.query.filter(
        (Message.sender_id == user_id) | (Message.receiver_id == user_id)
    ).order_by(Message.timestamp.asc()).all()
    
    return success_response([m.serialize() for m in messages])


def parse_time(time_str):
    """
    Helper function to parse a time string into a datetime object.
    Supports a simple ISO-like format (YYYY-MM-DD HH:MM:SS).
    """
    try:
        # Example format: "2025-12-25 10:30:00"
        return datetime.datetime.strptime(time_str, "%Y-%m-%d %H:%M:%S")
    except ValueError:
        return None

# --- New Meeting Routes ---
@app.route("/meetings/", methods=["POST"])
def create_meeting():
    """
    Creates a meeting between two users and schedules it.
    Request body:
    {
        "user1_id": <INT, required>,
        "user2_id": <INT, required>,
        "time": <STRING, required, format: "YYYY-MM-DD HH:MM:SS">,
        "location": <STRING, optional>,
        "description": <STRING, optional>
    }
    """
    body = json.loads(request.data)
    user1_id = body.get("user1_id")
    user2_id = body.get("user2_id")
    time_str = body.get("time")
    location = body.get("location")
    description = body.get("description")

    if not user1_id or not user2_id or not time_str:
        return failure_response("user1_id, user2_id, and time are required", 400)

    user1 = User.query.get(user1_id)
    user2 = User.query.get(user2_id)

    if not user1 or not user2:
        return failure_response("One or both users not found", 404)
        
    if user1_id == user2_id:
        return failure_response("Cannot schedule a meeting with yourself", 400)
    
    meeting_time = parse_time(time_str)
    if meeting_time is None:
        return failure_response("Invalid time format. Use YYYY-MM-DD HH:MM:SS", 400)

    meeting = Meeting(
        user1_id=user1_id,
        user2_id=user2_id,
        time=meeting_time,
        location=location,
        description=description,
    )
    
    db.session.add(meeting)
    db.session.commit()
    
    return success_response(meeting.serialize(), 201)


@app.route("/users/<int:user_id>/meetings/")
def get_user_meetings(user_id):
    """
    Retrieves all meetings scheduled for a specific user, sorted by time.
    """
    user = User.query.get(user_id)
    if not user:
        return failure_response("User not found", 404)

    # Query for meetings where the user is either user1 or user2
    meetings = Meeting.query.filter(
        (Meeting.user1_id == user_id) | (Meeting.user2_id == user_id)
    ).order_by(Meeting.time.asc()).all()
    
    return success_response([m.serialize() for m in meetings])


@app.route("/swipes/", methods=["POST"])
def record_swipe():
    """
    Records a swipe action (LIKE/DISLIKE) and checks for a mutual match.
    Request body:
    {
        "swiper_id": <INT, required>,
        "target_id": <INT, required>,
        "status": <STRING, required, 'LIKE' or 'DISLIKE'>
    }
    """
    body = json.loads(request.data)
    swiper_id = body.get("swiper_id")
    target_id = body.get("target_id")
    status = body.get("status")

    if not swiper_id or not target_id or status not in ['LIKE', 'DISLIKE']:
        return failure_response("swiper_id, target_id, and status ('LIKE' or 'DISLIKE') are required", 400)

    # 1. Validate Users
    swiper = User.query.get(swiper_id)
    target = User.query.get(target_id)
    if not swiper or not target:
        return failure_response("One or both users not found", 404)
    if swiper_id == target_id:
        return failure_response("Cannot swipe on yourself", 400)

    # 2. Check for existing swipe (prevents duplicate status records)
    existing_swipe = db.session.get(UserMatchStatus, (swiper_id, target_id))
    if existing_swipe:
        return failure_response("Swipe already recorded for this pair", 409)

    # 3. Record the new swipe
    new_swipe = UserMatchStatus(swiper_id=swiper_id, target_id=target_id, status=status)
    db.session.add(new_swipe)
    db.session.commit()

    # 4. Check for a mutual match (only if the new status is 'LIKE')
    is_match = False
    if status == 'LIKE':
        # Check if the target user (B) has a reciprocal 'LIKE' on the swiper (A)
        reciprocal_swipe = UserMatchStatus.query.filter_by(
            swiper_id=target_id,  # Target is the swiper
            target_id=swiper_id,  # Swiper is the target
            status='LIKE'
        ).first()

        if reciprocal_swipe:
            is_match = True
            
            # Record the final match in the 'Match' table
            # We use the min/max ID convention set in the Match model __init__
            try:
                match = Match(user1_id=swiper_id, user2_id=target_id)
                db.session.add(match)
                db.session.commit()
            except Exception as e:
                # Handle case where match already exists due to timing/constraint
                db.session.rollback()
                pass # Match was already recorded, just continue

    response_data = {
        "swipe_recorded": new_swipe.serialize(),
        "match_found": is_match,
        "new_match_id": match.id if is_match and 'match' in locals() else None
    }
    return success_response(response_data, 201)

@app.route("/users/<int:user_id>/matches/", methods=["GET"])
def get_user_matches(user_id):
    """
    Retrieves all finalized, mutual matches for a specific user.
    """
    user = User.query.get(user_id)
    if not user:
        return failure_response("User not found", 404)

    # Query for matches where the user is either user1 or user2
    matches = Match.query.filter(
        (Match.user1_id == user_id) | (Match.user2_id == user_id)
    ).order_by(Match.matched_on.desc()).all()

    match_list = []
    for match in matches:
        # Determine the ID of the *other* user in the pair
        other_user_id = match.user2_id if match.user1_id == user_id else match.user1_id
        other_user = User.query.get(other_user_id)

        if other_user:
            match_list.append({
                "match_id": match.id,
                "matched_user": other_user.serialize(), # Get the other user's full details
                "matched_on": match.matched_on.strftime("%Y-%m-%d %H:%M:%S")
            })
            
    return success_response(match_list)

@app.route("/users/<int:user_id>/suggestions/", methods=["GET"])
def get_match_suggestions(user_id):
    """
    Retrieves profiles the user has NOT yet swiped on (LIKE or DISLIKE).
    """
    current_user = User.query.get(user_id)
    if not current_user:
        return failure_response("User not found", 404)
        
    # 1. Identify all users the current user has already swiped on (or is self)
    subquery_swiped = db.session.query(UserMatchStatus.target_id).filter(
        UserMatchStatus.swiper_id == user_id
    )
    
    # 2. Query all Users whose ID is NOT in the subquery result AND is NOT the current user's ID
    suggestions = User.query.filter(
        User.id != user_id, 
        User.id.notin_(subquery_swiped)
    ).all()
    
    return success_response([u.serialize() for u in suggestions])


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
