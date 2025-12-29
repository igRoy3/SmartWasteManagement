import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/auth_service.dart';
import '../../services/report_service.dart';
import '../../models/report.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _garbageType = 'household';
  File? _imageFile;
  Position? _currentPosition;
  String _address = '';
  bool _isLoading = false;
  bool _loadingLocation = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _loadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      final position = await Geolocator.getCurrentPosition();
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        setState(() {
          _currentPosition = position;
          _address = '${place.street}, ${place.locality}, ${place.country}';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    } finally {
      setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (_currentPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please get your current location')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final reportService = ReportService(authService.token!);

      final report = GarbageReport(
        title: _titleController.text,
        description: _descriptionController.text,
        garbageType: _garbageType,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        address: _address,
      );

      final success = await reportService.createReport(
        report,
        imageFile: _imageFile,
      );

      setState(() => _isLoading = false);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report submitted successfully!')),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Garbage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _garbageType,
                decoration: const InputDecoration(
                  labelText: 'Garbage Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'household', child: Text('Household Waste')),
                  DropdownMenuItem(value: 'recyclable', child: Text('Recyclable')),
                  DropdownMenuItem(value: 'hazardous', child: Text('Hazardous')),
                  DropdownMenuItem(value: 'electronic', child: Text('Electronic Waste')),
                  DropdownMenuItem(value: 'construction', child: Text('Construction Debris')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() => _garbageType = value!);
                },
              ),
              const SizedBox(height: 16),
              if (_imageFile != null)
                Image.file(
                  _imageFile!,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: Text(_imageFile == null ? 'Take Photo' : 'Change Photo'),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_currentPosition != null)
                        Text(_address)
                      else
                        const Text('No location set'),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _loadingLocation ? null : _getCurrentLocation,
                        icon: _loadingLocation
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.location_on),
                        label: const Text('Get Current Location'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Submit Report'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
