import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../utils/theme.dart';

/// Route Optimization Screen - Helps collectors plan optimal routes
class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final MapController _mapController = MapController();
  List<Task> _selectedTasks = [];
  List<Task> _optimizedRoute = [];
  LatLng? _currentLocation;
  bool _isOptimizing = false;

  // Default starting location (can be updated with current location)
  final LatLng _defaultLocation = const LatLng(28.6139, 77.2090); // Delhi

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    // In a real app, you would use geolocator package here
    // For now, we'll use the default location
    setState(() {
      _currentLocation = _defaultLocation;
    });
  }

  void _toggleTaskSelection(Task task) {
    setState(() {
      if (_selectedTasks.any((t) => t.id == task.id)) {
        _selectedTasks.removeWhere((t) => t.id == task.id);
      } else {
        _selectedTasks.add(task);
      }
      _optimizedRoute = []; // Clear optimized route when selection changes
    });
  }

  void _selectAllTasks(List<Task> tasks) {
    setState(() {
      _selectedTasks = List.from(
        tasks.where((t) => t.latitude != null && t.longitude != null),
      );
      _optimizedRoute = [];
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedTasks = [];
      _optimizedRoute = [];
    });
  }

  /// Simple nearest neighbor algorithm for route optimization
  void _optimizeRoute() {
    if (_selectedTasks.isEmpty || _currentLocation == null) return;

    setState(() {
      _isOptimizing = true;
    });

    // Nearest neighbor algorithm
    List<Task> remaining = List.from(_selectedTasks);
    List<Task> optimized = [];
    LatLng current = _currentLocation!;

    while (remaining.isNotEmpty) {
      Task? nearest;
      double minDistance = double.infinity;

      for (var task in remaining) {
        if (task.latitude != null && task.longitude != null) {
          double distance = _calculateDistance(
            current,
            LatLng(task.latitude!, task.longitude!),
          );
          if (distance < minDistance) {
            minDistance = distance;
            nearest = task;
          }
        }
      }

      if (nearest != null) {
        optimized.add(nearest);
        remaining.remove(nearest);
        current = LatLng(nearest.latitude!, nearest.longitude!);
      } else {
        break;
      }
    }

    setState(() {
      _optimizedRoute = optimized;
      _isOptimizing = false;
    });

    // Fit map to show all points
    _fitMapToRoute();
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const Distance distance = Distance();
    return distance.as(LengthUnit.Kilometer, point1, point2);
  }

  void _fitMapToRoute() {
    if (_optimizedRoute.isEmpty && _selectedTasks.isEmpty) return;

    List<LatLng> points = [];
    if (_currentLocation != null) {
      points.add(_currentLocation!);
    }

    final tasksToShow = _optimizedRoute.isNotEmpty
        ? _optimizedRoute
        : _selectedTasks;
    for (var task in tasksToShow) {
      if (task.latitude != null && task.longitude != null) {
        points.add(LatLng(task.latitude!, task.longitude!));
      }
    }

    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    }
  }

  Future<void> _openInMaps() async {
    if (_optimizedRoute.isEmpty) return;

    // Build waypoints for Google Maps URL
    String waypoints = _optimizedRoute
        .where((t) => t.latitude != null && t.longitude != null)
        .map((t) => '${t.latitude},${t.longitude}')
        .join('/');

    String origin =
        '${_currentLocation!.latitude},${_currentLocation!.longitude}';
    String destination =
        '${_optimizedRoute.last.latitude},${_optimizedRoute.last.longitude}';

    // Google Maps directions URL
    String url = 'https://www.google.com/maps/dir/$origin/$waypoints';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open maps')));
      }
    }
  }

  double _calculateTotalDistance() {
    if (_optimizedRoute.isEmpty || _currentLocation == null) return 0;

    double total = 0;
    LatLng current = _currentLocation!;

    for (var task in _optimizedRoute) {
      if (task.latitude != null && task.longitude != null) {
        total += _calculateDistance(
          current,
          LatLng(task.latitude!, task.longitude!),
        );
        current = LatLng(task.latitude!, task.longitude!);
      }
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Planner'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: _clearSelection,
              tooltip: 'Clear Selection',
            ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final pendingTasks = taskProvider.tasks
              .where(
                (t) =>
                    t.status != 'completed' &&
                    t.latitude != null &&
                    t.longitude != null,
              )
              .toList();

          return Column(
            children: [
              // Map
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _currentLocation ?? _defaultLocation,
                        initialZoom: 12,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.smartwaste.collector',
                        ),
                        // Current location marker
                        if (_currentLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: _currentLocation!,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withOpacity(0.3),
                                        blurRadius: 10,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.my_location,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        // Route line
                        if (_optimizedRoute.isNotEmpty &&
                            _currentLocation != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: [
                                  _currentLocation!,
                                  ..._optimizedRoute
                                      .where(
                                        (t) =>
                                            t.latitude != null &&
                                            t.longitude != null,
                                      )
                                      .map(
                                        (t) =>
                                            LatLng(t.latitude!, t.longitude!),
                                      ),
                                ],
                                color: AppTheme.primaryColor,
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        // Task markers
                        MarkerLayer(
                          markers: pendingTasks.map((task) {
                            final isSelected = _selectedTasks.any(
                              (t) => t.id == task.id,
                            );
                            final routeIndex = _optimizedRoute.indexWhere(
                              (t) => t.id == task.id,
                            );

                            return Marker(
                              point: LatLng(task.latitude!, task.longitude!),
                              width: 50,
                              height: 50,
                              child: GestureDetector(
                                onTap: () => _toggleTaskSelection(task),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : Colors.grey.shade600,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.2,
                                            ),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: routeIndex >= 0
                                          ? Center(
                                              child: Text(
                                                '${routeIndex + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            )
                                          : const Icon(
                                              Icons.delete_outline,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                    ),
                                    if (isSelected && routeIndex < 0)
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: Container(
                                          width: 18,
                                          height: 18,
                                          decoration: const BoxDecoration(
                                            color: Colors.green,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    // Route info overlay
                    if (_optimizedRoute.isNotEmpty)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildInfoItem(
                                Icons.location_on,
                                '${_optimizedRoute.length} stops',
                              ),
                              _buildInfoItem(
                                Icons.directions,
                                '${_calculateTotalDistance().toStringAsFixed(1)} km',
                              ),
                              ElevatedButton.icon(
                                onPressed: _openInMaps,
                                icon: const Icon(Icons.navigation, size: 18),
                                label: const Text('Navigate'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Task list panel
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _optimizedRoute.isNotEmpty
                                  ? 'Optimized Route (${_optimizedRoute.length} stops)'
                                  : 'Select Tasks (${_selectedTasks.length}/${pendingTasks.length})',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Row(
                              children: [
                                if (_selectedTasks.length < pendingTasks.length)
                                  TextButton(
                                    onPressed: () =>
                                        _selectAllTasks(pendingTasks),
                                    child: const Text('Select All'),
                                  ),
                                if (_selectedTasks.isNotEmpty &&
                                    _optimizedRoute.isEmpty)
                                  ElevatedButton(
                                    onPressed: _isOptimizing
                                        ? null
                                        : _optimizeRoute,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                    ),
                                    child: _isOptimizing
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text('Optimize'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // Task list
                      Expanded(
                        child: _optimizedRoute.isNotEmpty
                            ? _buildOptimizedRouteList()
                            : _buildTaskSelectionList(pendingTasks),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryColor),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildOptimizedRouteList() {
    return ListView.builder(
      itemCount: _optimizedRoute.length,
      itemBuilder: (context, index) {
        final task = _optimizedRoute[index];
        final distance = index == 0 && _currentLocation != null
            ? _calculateDistance(
                _currentLocation!,
                LatLng(task.latitude!, task.longitude!),
              )
            : index > 0
            ? _calculateDistance(
                LatLng(
                  _optimizedRoute[index - 1].latitude!,
                  _optimizedRoute[index - 1].longitude!,
                ),
                LatLng(task.latitude!, task.longitude!),
              )
            : 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              task.title ?? 'Task #${task.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              task.address ?? 'Unknown address',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${distance.toStringAsFixed(1)} km',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            onTap: () {
              Navigator.pushNamed(context, '/task-detail', arguments: task.id);
            },
          ),
        );
      },
    );
  }

  Widget _buildTaskSelectionList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No pending tasks with location',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isSelected = _selectedTasks.any((t) => t.id == task.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryColor.withOpacity(0.1)
                : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (_) => _toggleTaskSelection(task),
            activeColor: AppTheme.primaryColor,
            title: Text(
              task.title ?? 'Task #${task.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              task.address ?? 'Unknown address',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            secondary: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(task.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                task.status?.replaceAll('_', ' ').toUpperCase() ?? 'PENDING',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(task.status),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'assigned':
        return Colors.blue;
      case 'in_progress':
        return Colors.purple;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
