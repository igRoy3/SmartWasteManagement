from rest_framework import serializers
from .models import GarbageReport, ReportComment
from accounts.serializers import UserSerializer


class ReportCommentSerializer(serializers.ModelSerializer):
    """Serializer for report comments."""
    user = UserSerializer(read_only=True)
    
    class Meta:
        model = ReportComment
        fields = ('id', 'report', 'user', 'comment', 'created_at')
        read_only_fields = ('id', 'user', 'created_at')


class GarbageReportSerializer(serializers.ModelSerializer):
    """Serializer for garbage reports."""
    reporter = UserSerializer(read_only=True)
    comments = ReportCommentSerializer(many=True, read_only=True)
    
    class Meta:
        model = GarbageReport
        fields = ('id', 'reporter', 'title', 'description', 'garbage_type', 
                  'status', 'latitude', 'longitude', 'address', 'image', 
                  'comments', 'created_at', 'updated_at')
        read_only_fields = ('id', 'reporter', 'created_at', 'updated_at')


class GarbageReportCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating garbage reports."""
    
    class Meta:
        model = GarbageReport
        fields = ('title', 'description', 'garbage_type', 'latitude', 
                  'longitude', 'address', 'image')


class GarbageReportUpdateSerializer(serializers.ModelSerializer):
    """Serializer for updating garbage report status."""
    
    class Meta:
        model = GarbageReport
        fields = ('status',)
