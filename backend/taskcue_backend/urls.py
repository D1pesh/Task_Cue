"""
TaskCue Backend URL Configuration
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from django.http import JsonResponse
from django.views.decorators.cache import cache_page

def health_check(request):
    """Basic health check endpoint."""
    return JsonResponse({
        'status': 'healthy',
        'service': 'TaskCue Backend',
        'version': '1.0.0',
        'timestamp': '2026-02-09T00:00:00Z',
    })

@cache_page(60 * 15)  # Cache for 15 minutes
def api_root(request):
    """API root endpoint with available endpoints."""
    return JsonResponse({
        'name': 'TaskCue API',
        'version': '1.0.0',
        'description': 'REST API for TaskCue mobile application',
        'endpoints': {
            'health': '/health/',
            'admin': '/admin/',
            'api': {
                'auth': '/api/v1/auth/',
                'categories': '/api/v1/categories/',
                'tasks': '/api/v1/tasks/',
                'analytics': '/api/v1/analytics/',
                'gamification': '/api/v1/gamification/',
            }
        },
        'documentation': 'https://docs.taskcue.com/api/',
        'support': 'support@taskcue.com',
    })

urlpatterns = [
    # Root and health check
    path('', api_root, name='api-root'),
    path('health/', health_check, name='health-check'),
    
    # Django Admin
    path('admin/', admin.site.urls),
    
    # API v1 endpoints
    path('api/v1/auth/', include('users.urls')),
    path('api/v1/categories/', include('categories.urls')),
    path('api/v1/tasks/', include('tasks.urls')),
    path('api/v1/analytics/', include('analytics.urls')),
    path('api/v1/gamification/', include('gamification.urls')),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)

# Customize admin site
admin.site.site_header = "TaskCue Backend Administration"
admin.site.site_title = "TaskCue Backend Admin"
admin.site.index_title = "Welcome to TaskCue Backend Administration"