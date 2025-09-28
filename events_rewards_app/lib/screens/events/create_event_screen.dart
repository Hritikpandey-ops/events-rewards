// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/events_provider.dart';
import '../../core/models/event_model.dart';

class CreateEventScreen extends StatefulWidget {
  final EventModel? eventToEdit;
  
  const CreateEventScreen({super.key, this.eventToEdit});

  @override
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _categoryController = TextEditingController();
  
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;
  
  // Category options
  final List<String> _categories = [
    'Music',
    'Sports',
    'Technology',
    'Business',
    'Education',
    'Arts',
    'Food',
    'Health',
    'Other'
  ];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    // Pre-fill fields if editing an existing event
    if (widget.eventToEdit != null) {
      _titleController.text = widget.eventToEdit!.title;
      _descriptionController.text = widget.eventToEdit!.description;
      _locationController.text = widget.eventToEdit!.location;
      _maxParticipantsController.text = widget.eventToEdit!.maxParticipants?.toString() ?? '';
      _selectedCategory = widget.eventToEdit!.category;
      _selectedStartDate = widget.eventToEdit!.startDate;
      _selectedStartTime = TimeOfDay.fromDateTime(widget.eventToEdit!.startDate);
      
      // Set end date/time if available
      if (widget.eventToEdit!.endDate != null) {
        _selectedEndDate = widget.eventToEdit!.endDate;
        _selectedEndTime = TimeOfDay.fromDateTime(widget.eventToEdit!.endDate!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.eventToEdit != null ? 'Edit Event' : 'Create Event'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Banner Image Placeholder
                _buildBannerSection(theme),
                const SizedBox(height: 24),
                
                // Event Title
                _buildFormField(
                  controller: _titleController,
                  label: 'Event Title',
                  icon: Icons.title,
                  validator: (value) => value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                _buildCategoryDropdown(theme),
                const SizedBox(height: 16),
                
                // Description
                _buildFormField(
                  controller: _descriptionController,
                  label: 'Description',
                  icon: Icons.description,
                  maxLines: 4,
                  validator: (value) => value?.isEmpty ?? true ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Date and Time Section
                _buildDateTimeSection(theme),
                const SizedBox(height: 16),
                
                // Location
                _buildFormField(
                  controller: _locationController,
                  label: 'Location',
                  icon: Icons.location_on,
                  validator: (value) => value?.isEmpty ?? true ? 'Location is required' : null,
                ),
                const SizedBox(height: 16),
                
                // Max Participants
                _buildFormField(
                  controller: _maxParticipantsController,
                  label: 'Max Participants (Optional)',
                  icon: Icons.people,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32),
                
                // Create/Update Button
                _buildActionButton(eventsProvider, theme),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBannerSection(ThemeData theme) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.7),
            theme.colorScheme.primary.withOpacity(0.4),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate,
            size: 48,
            color: theme.colorScheme.onPrimary.withOpacity(0.8),
          ),
          const SizedBox(height: 8),
          Text(
            widget.eventToEdit != null ? 'Edit Event Banner' : 'Add Event Banner',
            style: TextStyle(
              color: theme.colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.eventToEdit != null) ...[
            const SizedBox(height: 8),
            Text(
              'Current event image',
              style: TextStyle(
                color: theme.colorScheme.onPrimary.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
      ),
      items: _categories.map((String category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Text(category),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildDateTimeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Start Date & Time
        Row(
          children: [
            Expanded(
              child: _buildDateTimePicker(
                label: 'Start Date',
                value: _selectedStartDate != null 
                    ? DateFormat('MMM dd, yyyy').format(_selectedStartDate!)
                    : null,
                onTap: () => _selectStartDate(),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateTimePicker(
                label: 'Start Time',
                value: _selectedStartTime != null 
                    ? _formatTimeOfDay(_selectedStartTime!)
                    : null,
                onTap: () => _selectStartTime(),
                theme: theme,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // End Date & Time
        Row(
          children: [
            Expanded(
              child: _buildDateTimePicker(
                label: 'End Date (Optional)',
                value: _selectedEndDate != null 
                    ? DateFormat('MMM dd, yyyy').format(_selectedEndDate!)
                    : null,
                onTap: () => _selectEndDate(),
                theme: theme,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDateTimePicker(
                label: 'End Time (Optional)',
                value: _selectedEndTime != null 
                    ? _formatTimeOfDay(_selectedEndTime!)
                    : null,
                onTap: () => _selectEndTime(),
                theme: theme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required String label,
    required String? value,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
        ),
        child: Text(
          value ?? 'Select',
          style: TextStyle(
            color: value != null 
                ? theme.colorScheme.onSurface 
                : theme.colorScheme.onSurface.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(EventsProvider eventsProvider, ThemeData theme) {
    return ElevatedButton(
      onPressed: eventsProvider.isLoading ? null : _handleEventAction,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
      ),
      child: eventsProvider.isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : Text(
              widget.eventToEdit != null ? 'Update Event' : 'Create Event',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedStartDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final firstDate = _selectedStartDate ?? DateTime.now().add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate ?? firstDate.add(const Duration(days: 1)),
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedEndDate = date);
    }
  }

  Future<void> _selectStartTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedStartTime = time);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedEndTime ?? _selectedStartTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedEndTime = time);
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dateTime = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat('hh:mm a').format(dateTime);
  }

  DateTime _combineDateAndTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }

  Future<void> _handleEventAction() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_selectedStartDate == null || _selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start date and time')),
      );
      return;
    }

    if (_selectedEndDate != null && _selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end time if end date is provided')),
      );
      return;
    }

    if (_selectedEndDate == null && _selectedEndTime != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select end date if end time is provided')),
      );
      return;
    }

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    
    // Combine date and time
    final startDateTime = _combineDateAndTime(_selectedStartDate!, _selectedStartTime!);
    DateTime? endDateTime;
    
    if (_selectedEndDate != null && _selectedEndTime != null) {
      endDateTime = _combineDateAndTime(_selectedEndDate!, _selectedEndTime!);
      if (!endDateTime.isAfter(startDateTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date/time must be after start date/time')),
        );
        return;
      }
    }

    bool success;
    if (widget.eventToEdit != null) {
      // Update existing event
      success = await eventsProvider.updateEvent(
        eventId: widget.eventToEdit!.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        location: _locationController.text.trim(),
        category: _selectedCategory,
        maxParticipants: int.tryParse(_maxParticipantsController.text),
      );
    } else {
      // Create new event
      success = await eventsProvider.createEvent(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: startDateTime,
        endDate: endDateTime,
        location: _locationController.text.trim(),
        category: _selectedCategory,
        maxParticipants: int.tryParse(_maxParticipantsController.text),
      );
    }

    if (success && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.eventToEdit != null 
                ? 'Event updated successfully!'
                : 'Event created successfully!'
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.eventToEdit != null 
                ? 'Failed to update event'
                : 'Failed to create event'
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantsController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
}