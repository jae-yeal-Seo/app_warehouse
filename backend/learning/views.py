from django.shortcuts import render
import json
import requests
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib.auth import login, authenticate
from django.contrib.auth.models import User
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status
from .models import User

# Create your views here.


@api_view(["POST"])
@permission_classes([AllowAny])
@csrf_exempt
def google_login(request):
    """Google OAuth 로그인/회원가입 API"""
    try:
        data = json.loads(request.body)
        id_token = data.get("id_token")

        if not id_token:
            return Response(
                {"error": "ID token is required"}, status=status.HTTP_400_BAD_REQUEST
            )

        # Google API를 통해 ID 토큰 검증
        google_response = requests.get(
            f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}"
        )

        if google_response.status_code != 200:
            return Response(
                {"error": "Invalid ID token"}, status=status.HTTP_400_BAD_REQUEST
            )

        google_data = google_response.json()

        # Google에서 받은 사용자 정보
        google_id = google_data.get("sub")
        email = google_data.get("email")
        name = google_data.get("name", "")
        picture = google_data.get("picture", "")
        email_verified = google_data.get("email_verified", False)

        # 기존 사용자 확인
        try:
            user = User.objects.get(google_id=google_id)
            # 기존 사용자 로그인
            login(request, user)
            return Response(
                {
                    "message": "Login successful",
                    "user": {
                        "id": user.id,
                        "email": user.email,
                        "name": user.get_full_name() or user.username,
                        "profile_picture": user.profile_picture,
                        "is_new_user": False,
                    },
                },
                status=status.HTTP_200_OK,
            )

        except User.DoesNotExist:
            # 새 사용자 회원가입
            # 이메일 중복 확인
            if User.objects.filter(email=email).exists():
                return Response(
                    {"error": "Email already exists with different login method"},
                    status=status.HTTP_400_BAD_REQUEST,
                )

            # 새 사용자 생성
            user = User.objects.create_user(
                username=email,  # 이메일을 username으로 사용
                email=email,
                first_name=name.split()[0] if name else "",
                last_name=(
                    " ".join(name.split()[1:]) if name and len(name.split()) > 1 else ""
                ),
                google_id=google_id,
                profile_picture=picture,
                email_verified=email_verified,
            )

            # 자동 로그인
            login(request, user)

            return Response(
                {
                    "message": "Registration successful",
                    "user": {
                        "id": user.id,
                        "email": user.email,
                        "name": user.get_full_name() or user.username,
                        "profile_picture": user.profile_picture,
                        "is_new_user": True,
                    },
                },
                status=status.HTTP_201_CREATED,
            )

    except json.JSONDecodeError:
        return Response({"error": "Invalid JSON"}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
