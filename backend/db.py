from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class User(db.Model):
   """
   Model depicting a user.
   """
   __tablename__ = "users"
   id = db.Column(db.Integer, primary_key=True)
   name = db.Column(db.String(100), nullable=False)
   email = db.Column(db.String(100), nullable=False)
   password = db.Column(db.String(100), nullable=False)
   profile_id = db.Column(db.Integer, db.ForeignKey("profiles.id", ondelete="SET NULL"), unique=True, nullable=True)
   
class Profile(db.Model):
   """
   Model depicting a profile.
   """
   __tablename__ = "profiles"
   id = db.Column(db.Integer, primary_key=True)
   bio = db.Column(db.String(255), nullable=True)
   # user_id links back to the owning user
   user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, unique=True)
