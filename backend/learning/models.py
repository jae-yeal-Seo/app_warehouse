from django.db import models
from django.contrib.auth.models import AbstractUser


class User(AbstractUser):
    """Google OAuth 사용자 모델"""

    google_id = models.CharField(max_length=100, unique=True, null=True, blank=True)
    profile_picture = models.URLField(max_length=500, null=True, blank=True)
    email_verified = models.BooleanField(default=False)

    class Meta:
        db_table = "users"

    def __str__(self):
        return self.email or self.username
