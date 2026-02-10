"""
TaskCue Backend Settings Configuration
Django Settings for TaskCue Mobile App Backend
"""
import os
import json
from pathlib import Path
from decouple import config
import firebase_admin
from firebase_admin import credentials

# Build paths inside the project
BASE_DIR = Path(__file__).resolve().parent.parent

# Security Settings
SECRET_KEY = config('SECRET_KEY', default='django-insecure-change-me-in-production')
DEBUG = config('DEBUG', default=True, cast=bool)
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1,0.0.0.0').split(',')

# Application definition
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

THIRD_PARTY_APPS = [
    'rest_framework',
    'corsheaders',
]

LOCAL_APPS = [
    'users',
    'categories',
    'tasks',
    'analytics',
    'gamification',
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'taskcue_backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'taskcue_backend.wsgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Custom User Model
AUTH_USER_MODEL = 'users.CustomUser'

# Django REST Framework Configuration
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'users.authentication.FirebaseAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
    'DEFAULT_RENDERER_CLASSES': [
        'rest_framework.renderers.JSONRenderer',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DATETIME_FORMAT': '%Y-%m-%dT%H:%M:%S.%fZ',
    'DEFAULT_THROTTLE_CLASSES': [
        'rest_framework.throttling.AnonRateThrottle',
        'rest_framework.throttling.UserRateThrottle',
    ],
    'DEFAULT_THROTTLE_RATES': {
        'anon': '100/hour',
        'user': '1000/hour',
    },
}

# CORS Configuration for Flutter/Web apps
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
]

CORS_ALLOW_CREDENTIALS = True

CORS_ALLOWED_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
    'firebase-token',
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'

# Media Files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

# Default primary key field type
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# Firebase Configuration
try:
    import firebase_admin
    from firebase_admin import credentials
    
    FIREBASE_CONFIG = {
        'type': config('FIREBASE_TYPE', default='service_account'),
        'project_id': config('FIREBASE_PROJECT_ID', default=''),
        'private_key_id': config('FIREBASE_PRIVATE_KEY_ID', default=''),
        'private_key': config('FIREBASE_PRIVATE_KEY', default='').replace('\\n', '\n'),
        'client_email': config('FIREBASE_CLIENT_EMAIL', default=''),
        'client_id': config('FIREBASE_CLIENT_ID', default=''),
        'auth_uri': config('FIREBASE_AUTH_URI', default='https://accounts.google.com/o/oauth2/auth'),
        'token_uri': config('FIREBASE_TOKEN_URI', default='https://oauth2.googleapis.com/token'),
        'auth_provider_x509_cert_url': config('FIREBASE_AUTH_PROVIDER_X509_CERT_URL', default='https://www.googleapis.com/oauth2/v1/certs'),
        'client_x509_cert_url': config('FIREBASE_CLIENT_X509_CERT_URL', default=''),
    }

    # Initialize Firebase Admin SDK
    if not firebase_admin._apps:
        try:
            if FIREBASE_CONFIG['project_id']:
                cred = credentials.Certificate(FIREBASE_CONFIG)
                firebase_admin.initialize_app(cred)
            else:
                print("Warning: Firebase credentials not configured. Using default credentials.")
                firebase_admin.initialize_app()
        except Exception as e:
            print(f"Warning: Failed to initialize Firebase: {e}")
            
except ImportError:
    print("Warning: Firebase Admin SDK not installed. Firebase features will be disabled.")
    FIREBASE_CONFIG = {}

# TaskCue Specific Settings
TASK_CATEGORIES = [
    {'id': 1, 'name': 'Work', 'color': '#3B82F6', 'icon': 'work', 'description': 'Professional tasks and projects'},
    {'id': 2, 'name': 'Personal', 'color': '#10B981', 'icon': 'person', 'description': 'Personal activities and goals'}, 
    {'id': 3, 'name': 'Health', 'color': '#EF4444', 'icon': 'health_and_safety', 'description': 'Fitness, medical, wellness tasks'},
    {'id': 4, 'name': 'Learning', 'color': '#8B5CF6', 'icon': 'school', 'description': 'Education, courses, skill development'},
    {'id': 5, 'name': 'Finance', 'color': '#F59E0B', 'icon': 'account_balance', 'description': 'Budget, bills, financial planning'},
    {'id': 6, 'name': 'Social', 'color': '#EC4899', 'icon': 'people', 'description': 'Family, friends, social activities'},
    {'id': 7, 'name': 'Home', 'color': '#06B6D4', 'icon': 'home', 'description': 'Household, maintenance, organization'},
]

# Gamification Settings
GAMIFICATION_SETTINGS = {
    'TASK_COMPLETION_POINTS': {
        'LOW_PRIORITY': 10,
        'MEDIUM_PRIORITY': 15,
        'HIGH_PRIORITY': 25,
    },
    'BONUS_POINTS': {
        'EARLY_COMPLETION': 5,
        'STREAK_DAILY': 10,
        'STREAK_WEEKLY': 50,
        'STREAK_MONTHLY': 200,
    },
    'ACHIEVEMENT_THRESHOLDS': {
        'TASKS_COMPLETED': [10, 50, 100, 500, 1000],
        'STREAK_DAYS': [7, 30, 90, 365],
        'POINTS_EARNED': [100, 1000, 5000, 10000, 50000],
    },
}

# Logging Configuration
LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{levelname} {asctime} {module} {process:d} {thread:d} {message}',
            'style': '{',
        },
        'simple': {
            'format': '{levelname} {message}',
            'style': '{',
        },
    },
    'handlers': {
        'file': {
            'level': 'INFO',
            'class': 'logging.FileHandler',
            'filename': BASE_DIR / 'logs' / 'taskcue.log',
            'formatter': 'verbose',
        },
        'console': {
            'level': 'INFO',
            'class': 'logging.StreamHandler',
            'formatter': 'simple',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['file', 'console'],
            'level': 'INFO',
            'propagate': True,
        },
        'taskcue_backend': {
            'handlers': ['file', 'console'],
            'level': 'DEBUG',
            'propagate': True,
        },
    },
}

# Create logs directory if it doesn't exist
os.makedirs(BASE_DIR / 'logs', exist_ok=True)

# Cache Configuration  
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.redis.RedisCache',
        'LOCATION': config('REDIS_URL', default='redis://127.0.0.1:6379/1'),
    }
} if config('REDIS_URL', default=None) else {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'unique-snowflake',
    }
}

# Celery Configuration (for background tasks)
CELERY_BROKER_URL = config('REDIS_URL', default='redis://localhost:6379/0')
CELERY_RESULT_BACKEND = config('REDIS_URL', default='redis://localhost:6379/0')
CELERY_ACCEPT_CONTENT = ['json']
CELERY_TASK_SERIALIZER = 'json'
CELERY_RESULT_SERIALIZER = 'json'
CELERY_TIMEZONE = TIME_ZONE

# Email Configuration
EMAIL_BACKEND = config('EMAIL_BACKEND', default='django.core.mail.backends.console.EmailBackend')
EMAIL_HOST = config('EMAIL_HOST', default='smtp.gmail.com')
EMAIL_PORT = config('EMAIL_PORT', default=587, cast=int)
EMAIL_USE_TLS = config('EMAIL_USE_TLS', default=True, cast=bool)
EMAIL_HOST_USER = config('EMAIL_HOST_USER', default='')
EMAIL_HOST_PASSWORD = config('EMAIL_HOST_PASSWORD', default='')

# Production Security Settings
if not DEBUG:
    SECURE_BROWSER_XSS_FILTER = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    X_FRAME_OPTIONS = 'DENY'
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    CSRF_COOKIE_SECURE = True
    SESSION_COOKIE_SECURE = True