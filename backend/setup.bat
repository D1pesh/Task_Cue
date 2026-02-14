@echo off
REM TaskCue Backend Setup Script
REM This script initializes the Django backend with Firebase integration

echo ================================
echo  TaskCue Backend Setup Script
echo ================================
echo.

REM Check if Python is installed
python --version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python 3.8+ and try again
    pause
    exit /b 1
)

echo [1/6] Creating virtual environment...
python -m venv venv
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to create virtual environment
    pause
    exit /b 1
)

echo [2/6] Activating virtual environment...
call venv\Scripts\activate

echo [3/6] Installing Python dependencies...
pip install -r requirements.txt
if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to install dependencies
    pause
    exit /b 1
)

echo [4/6] Setting up environment configuration...
if not exist .env (
    copy .env.example .env
    echo Created .env file from template
    echo IMPORTANT: Please edit .env with your Firebase credentials
) else (
    echo .env file already exists
)

echo [5/6] Setting up database...
python manage.py makemigrations users
python manage.py makemigrations categories
python manage.py makemigrations
python manage.py migrate

echo [6/6] Initializing categories...
python manage.py shell -c "from categories.models import Category; Category.initialize_categories()"

echo.
echo ================================
echo  Setup Complete! 
echo ================================
echo.
echo Next steps:
echo 1. Edit .env file with your Firebase credentials
echo 2. Create admin user: python manage.py createsuperuser
echo 3. Start server: python manage.py runserver
echo.
echo Backend will be available at: http://127.0.0.1:8000/
echo Admin panel: http://127.0.0.1:8000/admin/
echo.
echo For Firebase setup instructions, see README.md
echo.
pause