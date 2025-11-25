import json
from flask import Flask, jsonify, request
from db import  User, Profile, Course, StudyArea, StudyTime, Major, db

app = Flask(__name__)

# Generalized success response.
def success_response(data, code=200):
    return jsonify(data), code

# Generalized failure response.
def failure_response(data, code=404):
    return json.dumps({"error": data}), code

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
        return failure_response("username and password are required"), 400

    if User.query.filter_by(email=email).first():
        return failure_response("user already exists"), 409
        
    if User.query.filter_by(username=username).first():
        return failure_response("username already exists"), 409
        
    user = User(username, email, password)
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
        return failure_response("username and password are required"), 400

    user = User.query.filter_by(username=username).first()
    if user is None or user.password != password:
        return failure_response("invalid credentials"), 401

    return success_response(user.serialize())

@app.route("/users/<int:id>")
def get_user():
    user = User.query.get(id)
    if not user:
        return failure_response("user not found"), 404
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
    body = json.loads(request.data or "{}")
    code = body.get("code")
    if not code:
        return failure_response("code is required"), 400

    if Course.query.filter_by(code=code).first():
        return failure_response("course already exists"), 409

    course = Course(code=code)
    db.session.add(course)
    db.session.commit()
    return success_response(course.serialize(), 201)

@app.route("/majors/", methods=["POST"])
def post_major():
    """
    Creates a major.
    Request body:
    {
        "name": <STRING, required>
    }
    """
    body = json.loads(request.data or "{}")
    name = body.get("name")
    if not name:
        return failure_response("name is required"), 400

    if Major.query.filter_by(name=name).first():
        return failure_response("major already exists"), 409

    major = Major(name=name)
    db.session.add(major)
    db.session.commit()
    return success_response(major.serialize(), 201)

@app.route("/areas/", methods=["POST"])
def post_area():
    """
    Creates a study area.
    Request body:
    {
        "name": <STRING, required>
    }
    """
    body = json.loads(request.data or "{}")
    name = body.get("name")
    if not name:
        return failure_response("name is required"), 400

    if StudyArea.query.filter_by(name=name).first():
        return failure_response("study area already exists"), 409

    area = StudyArea(name=name)
    db.session.add(area)
    db.session.commit()
    return success_response(area.serialize(), 201)

@app.route("/times/", methods=["POST"])
def post_time():
    """
    Creates a study time option (e.g., morning, afternoon, evening).
    Request body:
    {
        "name": <STRING, required>
    }
    """
    body = json.loads(request.data or "{}")
    name = body.get("name")
    if not name:
        return failure_response("name is required"), 400

    if StudyTime.query.filter_by(name=name).first():
        return failure_response("study time already exists"), 409

    time = StudyTime(name=name)
    db.session.add(time)
    db.session.commit()
    return success_response(time.serialize(), 201)

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
        return failure_response("user_id is required"), 400

    user = User.query.filter_by(id=user_id).first()
    if not user:
        return failure_response("user not found")
    if user.profile:
        return failure_response("profile already exists for user"), 409

    study_area_id = body.get("study_area_id")
    if study_area_id is None :
        return failure_response("study_area_id is required"), 400
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
            object = model.query.get(item_id)
            if object:
                records.append(object)
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
        return failure_response(str(ve)), 400
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

if __name__ == "__main__":
    app.run(debug=True)