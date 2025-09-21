import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart'; // <-- CORRECTED PATH
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookTalkPage extends StatefulWidget {
  const BookTalkPage({Key? key}) : super(key: key);

  @override
  State<BookTalkPage> createState() => _BookTalkPageState();
}

class _BookTalkPageState extends State<BookTalkPage> {
  final _formKey = GlobalKey<FormState>();
  static const Color primaryColor = Colors.blue;

  final _bookNameController = TextEditingController();
  final _authorsController = TextEditingController();
  final _locationController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isOnlineEvent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _bookNameController.dispose();
    _authorsController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  // --- THIS IS THE FINAL, CORRECTED FUNCTION ---
  Future<void> _scheduleTalk() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        _selectedTime != null) {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final DateTime finalDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final contentData = {
        'contentType': 'BookTalk',
        'bookName': _bookNameController.text,
        'authors': _authorsController.text,
        'eventType': _isOnlineEvent ? 'Online' : 'Physical',
        'location': _locationController.text,
        'eventTimestamp': Timestamp.fromDate(finalDateTime),
      };

      try {
        await DatabaseService(uid: user.uid).addContent(contentData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Book talk scheduled successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields, including date and time.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule a Book Talk'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextFormField(
                controller: _bookNameController,
                label: 'Name of the Book',
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _authorsController,
                label: 'Author(s) & Co-Author(s)',
              ),
              const SizedBox(height: 20),
              ToggleButtons(
                isSelected: [!_isOnlineEvent, _isOnlineEvent],
                onPressed: (index) =>
                    setState(() => _isOnlineEvent = index == 1),
                borderRadius: BorderRadius.circular(12),
                selectedColor: Colors.white,
                fillColor: primaryColor,
                color: primaryColor,
                selectedBorderColor: primaryColor,
                borderColor: primaryColor,
                constraints: BoxConstraints(
                  minHeight: 45.0,
                  minWidth: (MediaQuery.of(context).size.width - 60) / 2,
                ),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Physical Venue'),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('Online Meet'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _locationController,
                label: _isOnlineEvent
                    ? 'Online Meet Link (e.g., Zoom, Meet)'
                    : 'Venue Address',
                icon: _isOnlineEvent ? Icons.link : Icons.location_on_outlined,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildPickerTile(
                      icon: Icons.calendar_today,
                      label: _selectedDate == null
                          ? 'Select Date'
                          : DateFormat('MMM d, yyyy').format(_selectedDate!),
                      onTap: () => _selectDate(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildPickerTile(
                      icon: Icons.access_time,
                      label: _selectedTime == null
                          ? 'Select Time'
                          : _selectedTime!.format(context),
                      onTap: () => _selectTime(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _scheduleTalk,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'SCHEDULE BOOK TALK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: primaryColor) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? 'This field cannot be empty.' : null,
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade400),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12.0),
        child: Icon(icon, color: primaryColor),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
