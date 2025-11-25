from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

profile_course_association = db.Table(
    "profile_courses",
    db.Column("profile_id", db.Integer, db.ForeignKey("profiles.id"), primary_key=True),
    db.Column("course_id", db.Integer, db.ForeignKey("courses.id"), primary_key=True),
)

profile_studytime_association = db.Table(
    "profile_study_times",
    db.Column("profile_id", db.Integer, db.ForeignKey("profiles.id"), primary_key=True),
    db.Column("study_time_id", db.Integer, db.ForeignKey("study_times.id"), primary_key=True),
)

profile_major_association = db.Table(
    "profile_majors",
    db.Column("profile_id", db.Integer, db.ForeignKey("profiles.id"), primary_key=True),
    db.Column("major_id", db.Integer, db.ForeignKey("majors.id"), primary_key=True),
)

class User(db.Model):
   """
   Depicts a User.
   A user has one profile.
   """
   __tablename__ = "users"
   id = db.Column(db.Integer, primary_key=True)
   username = db.Column(db.String(100), nullable=False)
   email = db.Column(db.String(100), nullable=False)
   password = db.Column(db.String(100), nullable=False)
   profile = db.relationship("Profile", back_populates="user", uselist=False)
   
   def __init__(self, **kwargs):
      """
      Initializes a User.
      """
      self.username = kwargs.get("username", "")
      self.password = kwargs.get("password", "")
      
   def serialize(self):
      """
      Serializes a User into a dictionary, providing all their information.
      """
      return {
         "id": self.id,
         "username": self.username,
         "email": self.email,
         "password": self.password,
         "profile": self.profile.serialize() if self.profile else None,
      }

class Profile(db.Model):
   """
   Depicts a Profile.
   A profile can be linked to many courses.
   A profile links to one study area.
   A profile can have multiple study times.
   A profile can have multiple majors.
   """
   __tablename__ = "profiles"
   id = db.Column(db.Integer, primary_key=True)
   user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, unique=True)
   study_area_id = db.Column(db.Integer, db.ForeignKey("study_areas.id"), nullable=True)
   study_area = db.relationship("StudyArea", back_populates="profiles", uselist=False)
   study_times = db.relationship("StudyTime", secondary=profile_studytime_association, backref="profiles")
   courses = db.relationship("Course", secondary=profile_course_association, backref="profiles")
   majors = db.relationship("Major", secondary=profile_major_association, backref="profiles")
   user = db.relationship("User", back_populates="profile", uselist=False)
   
   def __init__(self, **kwargs):
      """
      Initializes a Profile.
      """
      self.user_id = kwargs.get("user_id")
      self.study_area_id = kwargs.get("study_area_id")
      self.study_area = kwargs.get("study_area")
      self.study_times = kwargs.get("study_times", [])
      self.courses = kwargs.get("courses", [])
      self.majors = kwargs.get("majors", [])

   def serialize(self):
      """
      Serializes a Profile, including related objects.
      """
      return {
         "id": self.id,
         "user_id": self.user_id,
         "study_area": self.study_area.serialize() if self.study_area else None,
         "study_times": [st.simple_serialize() for st in self.study_times],
         "courses": [c.simple_serialize() for c in self.courses],
         "majors": [m.simple_serialize() for m in self.majors],
      }

   def simple_serialize(self):
      """
      Serializes a Profile without nested relationships.
      """
      return {
         "id": self.id,
         "user_id": self.user_id,
         "study_area_id": self.study_area_id,
      }
   
   
class Courses(db.Model):
   """
   Depicts a Course.
   A course can be linked to many profiles.
   """
   __tablename__ = "courses"
   id = db.Column(db.Integer, primary_key=True)
   code = db.Column(db.String(100), nullable=False)
   profiles = db.relationship("Profile", secondary=profile_course_association, backref="courses")

   def __init__(self, **kwargs):
      """
      Initializes a Course.
      """
      self.code = kwargs.get("code", "")

   def serialize(self):
      """
      Serializes a Course, including related profiles.
      """
      return {
         "id": self.id,
         "code": self.code,
         "profiles": [p.simple_serialize() for p in self.profiles],
      }

   def simple_serialize(self):
      """
      Serializes a Course without relationships.
      """
      return {
         "id": self.id,
         "code": self.code,
      }

class StudyArea(db.Model):
   """
   Depicts a favorite study area.
   A study area can be linked to many profiles.
   """
   __tablename__ = "study_areas"
   id = db.Column(db.Integer, primary_key=True)
   name = db.Column(db.String(255), nullable=False)
   profiles = db.relationship("Profile", back_populates="study_area")

   def __init__(self, **kwargs):
      """
      Initializes a StudyArea.
      """
      self.name = kwargs.get("name", "")

   def serialize(self):
      """
      Serializes a StudyArea, including related profiles.
      """
      return {
         "id": self.id,
         "name": self.name,
         "profiles": [p.simple_serialize() for p in self.profiles],
      }

   def simple_serialize(self):
      """
      Serializes a StudyArea without relationships.
      """
      return {
         "id": self.id,
         "name": self.name,
      }

class StudyTime(db.Model):
   """
   Depicts a study time option (e.g., morning, afternoon, evening).
   A study time can be linked to many profiles.
   """
   __tablename__ = "study_times"
   id = db.Column(db.Integer, primary_key=True)
   name = db.Column(db.String(50), nullable=False, unique=True)
   profiles = db.relationship("Profile", secondary=profile_studytime_association, backref="available_study_times")

   def __init__(self, **kwargs):
      """
      Initializes a StudyTime.
      """
      self.name = kwargs.get("name", "")

   def serialize(self):
      """
      Serializes a StudyTime, including related profiles.
      """
      return {
         "id": self.id,
         "name": self.name,
         "profiles": [p.simple_serialize() for p in self.profiles],
      }

   def simple_serialize(self):
      """
      Serializes a StudyTime without relationships.
      """
      return {
         "id": self.id,
         "name": self.name,
      }

class Major(db.Model):
   """
   Depicts a Major.
   A major can be linked to many profiles.
   """
   __tablename__ = "majors"
   id = db.Column(db.Integer, primary_key=True)
   name = db.Column(db.String(255), nullable=False, unique=True)
   profiles = db.relationship("Profile", secondary=profile_major_association, backref="available_majors")

   def __init__(self, **kwargs):
      """
      Initializes a Major.
      """
      self.name = kwargs.get("name", "")

   def serialize(self):
      """
      Serializes a Major, including related profiles.
      """
      return {
         "id": self.id,
         "name": self.name,
         "profiles": [p.simple_serialize() for p in self.profiles],
      }

   def simple_serialize(self):
      """
      Serializes a Major without relationships.
      """
      return {
         "id": self.id,
         "name": self.name,
      }
