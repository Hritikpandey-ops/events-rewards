// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/events_provider.dart';

class CreateEventScreen extends StatefulWidget {
  const CreateEventScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CreateEventScreenState createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  
  DateTime? _selectedDate;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Event')),
      body: Consumer<EventsProvider>(
        builder: (context, eventsProvider, child) {
          return Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Event Title'),
                    validator: (value) => value?.isEmpty ?? true ? 'Title required' : null,
                  ),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  // Date picker
                  InkWell(
                    onTap: () => _selectDate(),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Event Date'),
                      child: Text(_selectedDate?.toString().split(' ')[0] ?? 'Select date'),
                    ),
                  ),
                  TextFormField(
                    controller: _maxParticipantsController,
                    decoration: const InputDecoration(labelText: 'Max Participants'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: eventsProvider.isLoading ? null : () => _createEvent(),
                    child: eventsProvider.isLoading 
                        ? const CircularProgressIndicator()
                        : const Text('Create Event'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final eventsProvider = Provider.of<EventsProvider>(context, listen: false);
    
    final success = await eventsProvider.createEvent(
      title: _titleController.text,
      description: _descriptionController.text,
      eventDate: _selectedDate!,
      location: _locationController.text,
      maxParticipants: int.tryParse(_maxParticipantsController.text),
    );

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event created successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to create event')),
      );
    }
  }
}
