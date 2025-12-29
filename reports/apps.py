from django.apps import AppConfig


class ReportsConfig(AppConfig):
    name = 'reports'
    
    def ready(self):
        # Import signals to register them
        import reports.signals  # noqa
