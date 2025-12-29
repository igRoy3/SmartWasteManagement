from rest_framework import serializers
from django.contrib.auth import get_user_model
from .models import GarbageReport, ReportUpdate

User = get_user_model()


class ReportUserSerializer(serializers.ModelSerializer):
    """Minimal user serializer for report responses."""
    
    class Meta:
        model = User
        fields = ['id', 'username', 'first_name', 'last_name', 'phone']


class ReportUpdateSerializer(serializers.ModelSerializer):
    """Serializer for report status updates."""
    
    updated_by = ReportUserSerializer(read_only=True)
    
    class Meta:
        model = ReportUpdate
        fields = ['id', 'status', 'note', 'updated_by', 'created_at']
        read_only_fields = ['id', 'updated_by', 'created_at']


class GarbageReportSerializer(serializers.ModelSerializer):
    """Serializer for garbage reports."""
    
    reported_by = ReportUserSerializer(read_only=True)
    assigned_to = ReportUserSerializer(read_only=True)
    updates = ReportUpdateSerializer(many=True, read_only=True)
    
    class Meta:
        model = GarbageReport
        fields = [
            'id', 'title', 'description', 'waste_type',
            'latitude', 'longitude', 'address', 'image',
            'status', 'reported_by', 'assigned_to',
            'created_at', 'updated_at', 'completed_at', 'updates'
        ]
        read_only_fields = [
            'id', 'status', 'reported_by', 'assigned_to',
            'created_at', 'updated_at', 'completed_at'
        ]


class GarbageReportCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating garbage reports."""
    
    class Meta:
        model = GarbageReport
        fields = [
            'id', 'title', 'description', 'waste_type',
            'latitude', 'longitude', 'address', 'image',
            'status', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'status', 'created_at', 'updated_at']


class AssignCollectorSerializer(serializers.Serializer):
    """Serializer for assigning a collector to a report."""
    
    collector_id = serializers.IntegerField(required=True)
    
    def validate_collector_id(self, value):
        try:
            user = User.objects.get(id=value)
            if user.role != 'collector':
                raise serializers.ValidationError(
                    "Selected user is not a collector."
                )
        except User.DoesNotExist:
            raise serializers.ValidationError("Collector not found.")
        return value


class UpdateStatusSerializer(serializers.Serializer):
    """Serializer for updating report status."""
    
    status = serializers.ChoiceField(choices=GarbageReport.Status.choices)
    note = serializers.CharField(required=False, allow_blank=True)


class MapReportSerializer(serializers.ModelSerializer):
    """Lightweight serializer for map markers."""
    
    reported_by_name = serializers.SerializerMethodField()
    assigned_to_name = serializers.SerializerMethodField()
    
    class Meta:
        model = GarbageReport
        fields = [
            'id', 'title', 'waste_type', 'status',
            'latitude', 'longitude', 'address',
            'reported_by_name', 'assigned_to_name', 'created_at'
        ]
    
    def get_reported_by_name(self, obj):
        if obj.reported_by:
            return f"{obj.reported_by.first_name} {obj.reported_by.last_name}".strip() or obj.reported_by.username
        return None
    
    def get_assigned_to_name(self, obj):
        if obj.assigned_to:
            return f"{obj.assigned_to.first_name} {obj.assigned_to.last_name}".strip() or obj.assigned_to.username
        return None
