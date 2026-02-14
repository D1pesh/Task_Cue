# 🚀 TaskCue Backend

## Firebase-Powered Django REST API for TaskCue Mobile App

Complete Django backend with **Firebase Authentication**, **Firestore sync**, and **AI analytics** to power the TaskCue Flutter application.

### 🏗️ Architecture Overview

```
TaskCue Backend
├── 🔐 Firebase Authentication    # User auth & real-time sync
├── 📊 Django REST Framework     # API endpoints  
├── 🗃️ SQLite + Firestore       # Hybrid database
├── 🤖 AI Analytics             # scikit-learn insights
└── ⚡ Real-time Features       # Live task synchronization
```

---

## 📁 Project Structure

```
backend/
├── taskcue_backend/           # Django project settings
│   ├── settings.py           # Main configuration
│   ├── urls.py               # API routing
│   └── wsgi.py               # WSGI application
├── firebase/                 # Firebase integration
│   ├── services.py           # Firebase & Firestore services
│   └── __init__.py           # Package initialization
├── users/                    # 👤 User management
│   ├── models.py             # CustomUser, UserProfile, UserSession
│   ├── authentication.py     # Firebase auth backend
│   ├── views.py              # Authentication API
│   ├── serializers.py        # User serializers
│   ├── admin.py              # Django admin
│   └── urls.py               # User routes
├── categories/               # 📂 7 Fixed categories
│   ├── models.py             # Category, CategoryStats
│   ├── views.py              # Category API
│   ├── serializers.py        # Category serializers
│   └── admin.py              # Category admin
├── tasks/                    # ✅ Task management (TODO)
├── analytics/                # 📈 AI insights (TODO)
├── gamification/             # 🎮 Points & rewards (TODO)
├── requirements.txt          # Python dependencies
├── manage.py                 # Django management
├── .env.example              # Environment template
└── README.md                 # This file
```

---

## ⚡ Quick Start Guide

### 1️⃣ Setup Environment

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows:
venv\Scripts\activate
# macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

### 2️⃣ Configure Firebase

1. **Go to [Firebase Console](https://console.firebase.google.com/)**
2. **Create or select your project**
3. **Generate service account key:**
   - Project Settings → Service Accounts
   - Click "Generate new private key"
   - Download JSON file

4. **Copy environment file:**
   ```bash
   copy .env.example .env
   ```

5. **Edit `.env` with your Firebase credentials:**
   ```bash
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
   FIREBASE_CLIENT_EMAIL=firebase-adminsdk-xxx@your-project.iam.gserviceaccount.com
   # ... other Firebase settings
   ```

### 3️⃣ Initialize Database

```bash
# Create database migrations
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Create admin user
python manage.py createsuperuser

# Initialize the 7 fixed categories
python manage.py shell
>>> from categories.models import Category
>>> Category.initialize_categories()
>>> exit()
```

### 4️⃣ Run Development Server

```bash
# Start Django development server
python manage.py runserver

# Backend will be available at:
# http://127.0.0.1:8000/
```

---

## 🔗 API Endpoints

### 🏠 **Health & Info**
```
GET  /                    # API information
GET  /health/             # Health check
GET  /admin/              # Django admin panel
```

### 🔐 **Authentication (`/api/v1/auth/`)**
```
GET  /me/                 # Current user profile
PUT  /profile/update/     # Update user profile  
GET  /sessions/           # List user sessions
POST /logout/             # Logout user
POST /verify-token/       # Verify Firebase token
DELETE /delete-account/   # Deactivate account
```

### 📂 **Categories (`/api/v1/categories/`)**
```
GET  /                    # List all 7 categories
GET  /<id>/               # Get category details
GET  /stats/              # Category usage statistics
GET  /analytics/          # Category analytics
```

### 👤 **Admin Endpoints**
```
GET  /api/v1/auth/admin/users/       # List all users
GET  /api/v1/auth/admin/users/<id>/  # User details
GET  /api/v1/auth/admin/stats/       # User statistics
```

---

## 🏛️ **Fixed Categories System**

TaskCue enforces **exactly 7 immutable categories**:

| ID | Category | Color | Description |
|----|----------|--------|-------------|
| 1️⃣ | **Work** | 🔵 Blue | Professional tasks and projects |
| 2️⃣ | **Personal** | 🟢 Green | Personal activities and goals |
| 3️⃣ | **Health** | 🔴 Red | Fitness, medical, wellness tasks |
| 4️⃣ | **Learning** | 🟣 Purple | Education, courses, skill development |
| 5️⃣ | **Finance** | 🟠 Orange | Budget, bills, financial planning |
| 6️⃣ | **Social** | 🩷 Pink | Family, friends, social activities |
| 7️⃣ | **Home** | 🔷 Cyan | Household, maintenance, organization |

> **Note:** Categories are **immutable** - they cannot be changed, renamed, or deleted to ensure consistency across all users.

---

## 🔥 **Firebase Integration**

### **Authentication Flow**
```javascript
// Flutter app gets Firebase token
const token = await FirebaseAuth.instance.currentUser.getIdToken();

// Send to Django API
fetch('/api/v1/auth/me/', {
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json',
  }
});
```

### **Firestore Real-time Sync**
- ✅ **User profiles** synced to Firestore
- ✅ **Task data** real-time updates
- ✅ **Analytics data** for insights
- ✅ **Gamification** points & achievements

### **Security Features**
- 🛡️ **Firebase token verification**
- 🔐 **Role-based access control**
- 🕰️ **Session management**
- 📊 **Activity logging**

---

## 👥 **User Roles & Permissions**

### **🙋 Regular User (`user`)**
- Create, edit, delete own tasks
- View own analytics and statistics
- Access gamification features
- Update personal profile

### **👨‍💼 Administrator (`admin`)**
- **All user permissions** +
- View all users and their data
- Access admin dashboard
- Monitor system analytics
- Manage user accounts

### **🛠️ Moderator (`moderator`)**
- Limited admin permissions
- User support functions
- Content moderation capabilities

---

## 🎮 **Gamification System**

### **📊 Point System**
```
Task Priority Points:
├── 🔻 Low Priority    → 10 points
├── 🔸 Medium Priority → 15 points  
└── 🔺 High Priority   → 25 points

Bonus Rewards:
├── ⚡ Early Completion → +5 points
├── 🔥 Daily Streak    → +10 points
└── 🏆 Weekly Streak   → +50 points
```

### **🏅 Achievement System**
- **Task Milestones:** 10, 50, 100, 500, 1000 tasks
- **Streak Records:** 7, 30, 90, 365 days
- **Point Achievements:** 100, 1K, 5K, 10K, 50K points

---

## 📱 **Flutter Integration**

### **API Calls from Flutter**
```dart
// Example API integration
final response = await http.get(
  Uri.parse('$baseUrl/api/v1/categories/'),
  headers: {
    'Authorization': 'Bearer $firebaseToken',
    'Content-Type': 'application/json',
  },
);

if (response.statusCode == 200) {
  final categories = jsonDecode(response.body);
  // Use categories in your Flutter app
}
```

### **Real-time Updates**
```dart
// Listen to Firestore changes
FirebaseFirestore.instance
  .collection('users')
  .doc(user.uid)
  .collection('tasks')
  .snapshots()
  .listen((snapshot) {
    // Handle real-time task updates
  });
```

---

## 🐳 **Production Deployment**

### **Environment Setup**
```bash
# Production environment variables
SECRET_KEY=your-production-secret-key
DEBUG=False
ALLOWED_HOSTS=yourdomain.com,api.taskcue.com
FIREBASE_PROJECT_ID=your-production-firebase-project

# Database (upgrade to PostgreSQL)
DATABASE_URL=postgresql://user:pass@localhost/taskcue_db

# Redis for caching
REDIS_URL=redis://localhost:6379/0
```

### **Server Deployment**
```bash
# Install production server
pip install gunicorn

# Collect static files
python manage.py collectstatic --noinput

# Run with Gunicorn
gunicorn taskcue_backend.wsgi:application --bind 0.0.0.0:8000
```

---

## 🧪 **Testing & Development**

### **Run Tests**
```bash
# Run all tests
python manage.py test

# Run with coverage
pip install coverage
coverage run --source='.' manage.py test
coverage report
coverage html
```

### **API Testing**
```bash
# Test with curl
curl -H "Authorization: Bearer YOUR_FIREBASE_TOKEN" \
     http://localhost:8000/api/v1/auth/me/

# Or use Postman, Insomnia, etc.
```

---

## 🔍 **Monitoring & Health**

### **Health Check Endpoints**
```
GET /health/                      # Overall system health
GET /api/v1/auth/health/          # Users service health
GET /api/v1/categories/health/    # Categories service health
```

### **Logging & Analytics**
- ✅ **Application logs:** `logs/taskcue.log`
- ✅ **User activity tracking**
- ✅ **Performance monitoring**
- ✅ **Error tracking and alerts**

---

## 🆘 **Troubleshooting**

### **Common Issues**

**🔴 Firebase Authentication Errors**
```bash
# Check Firebase configuration
python manage.py shell
>>> from firebase.services import get_firebase_service
>>> service = get_firebase_service()
>>> # Should not raise errors
```

**🔴 Database Migration Issues**
```bash
# Reset migrations (development only)
python manage.py migrate --fake-initial
python manage.py migrate
```

**🔴 CORS Issues with Flutter**
```python
# In settings.py, ensure CORS is configured:
CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",     # Flutter web
    "http://127.0.0.1:3000",
]
```

---

## 🚧 **Remaining Implementation**

### **High Priority (Next Steps)**
- ✅ **Tasks App** - Core CRUD functionality for tasks
- ✅ **Analytics App** - AI-powered productivity insights  
- ✅ **Gamification App** - Points, streaks, achievements

### **Future Enhancements**
- 🔔 **Push Notifications** - Real-time task reminders
- 📧 **Email Reports** - Weekly/monthly summaries
- 🤖 **AI Scheduling** - Smart task scheduling suggestions
- 📱 **Mobile optimizations** - PWA support

---

## 📄 **License & Support**

- **License:** MIT License (modify as needed)
- **Support:** Create issues in the repository
- **Documentation:** [API Docs](http://localhost:8000/) (when running)
- **Admin Panel:** [Django Admin](http://localhost:8000/admin/)

---

## 🤝 **Contributing**

1. **Follow Django best practices**
2. **Add tests for new features**
3. **Update documentation**
4. **Use proper commit messages**
5. **Test Firebase integration**

---

**🎉 TaskCue Backend - Powering productivity through intelligent task management!** 

*Created with Django + Firebase + AI for the modern productivity workflow.*