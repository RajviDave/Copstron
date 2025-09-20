import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // A package for date formatting

class PublishBookPage extends StatefulWidget {
  const PublishBookPage({Key? key}) : super(key: key);

  @override
  State<PublishBookPage> createState() => _PublishBookPageState();
}

class _PublishBookPageState extends State<PublishBookPage> {
  final _formKey = GlobalKey<FormState>();
  static const Color primaryColor = Color(0xFF59AC77);

  // Controllers for text fields
  final _bookNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _publisherController = TextEditingController();

  // State variables for other inputs
  DateTime? _selectedDate;
  String? _selectedGenre;
  bool _isLoading = false;

  final List<String> _genres = [
    'Fiction',
    'Non-Fiction',
    'Science Fiction',
    'Fantasy',
    'Mystery',
    'Thriller',
    'Romance',
    'Biography',
  ];

  @override
  void dispose() {
    _bookNameController.dispose();
    _descriptionController.dispose();
    _publisherController.dispose();
    super.dispose();
  }

  // Function to show the date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Function to handle form submission
  Future<void> _submitForm(String status) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // Simulate network call
      await Future.delayed(const Duration(seconds: 2));

      // Collect all the data
      final bookData = {
        'name': _bookNameController.text,
        'description': _descriptionController.text,
        'publisher': _publisherController.text,
        'genre': _selectedGenre,
        'publishDate': _selectedDate != null
            ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
            : null,
        'status': status, // 'Published' or 'Draft'
      };

      print('Saving book with data: $bookData');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Book successfully saved as $status!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(); // Go back after success
      }

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish a New Book'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Book Name
              _buildTextFormField(
                controller: _bookNameController,
                label: 'Name of Book',
              ),
              const SizedBox(height: 20),

              // Upload Photo Button
              OutlinedButton.icon(
                icon: const Icon(
                  Icons.cloud_upload_outlined,
                  color: primaryColor,
                ),
                label: const Text(
                  'Upload Book Cover',
                  style: TextStyle(color: primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // TODO: Implement image picking logic
                },
              ),
              const SizedBox(height: 20),

              // Description
              _buildTextFormField(
                controller: _descriptionController,
                label: 'Description of Book',
                maxLines: 5,
              ),
              const SizedBox(height: 20),

              // Publisher House
              _buildTextFormField(
                controller: _publisherController,
                label: 'Publisher House',
              ),
              const SizedBox(height: 20),

              // Genre Dropdown
              DropdownButtonFormField<String>(
                value: _selectedGenre,
                decoration: InputDecoration(
                  labelText: 'Genre of Book',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _genres.map((String genre) {
                  return DropdownMenuItem<String>(
                    value: genre,
                    child: Text(genre),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedGenre = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Please select a genre' : null,
              ),
              const SizedBox(height: 20),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12.0),
                  child: Icon(Icons.calendar_today, color: primaryColor),
                ),
                title: Text(
                  _selectedDate == null
                      ? 'Select Publication Date'
                      : DateFormat('MMMM d, yyyy').format(_selectedDate!),
                ),
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  // Save as Draft Button
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading ? null : () => _submitForm('Draft'),
                      child: const Text(
                        'SAVE AS DRAFT',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Publish Button
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isLoading
                          ? null
                          : () => _submitForm('Published'),
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
                              'PUBLISH',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget for consistent text field styling
  TextFormField _buildTextFormField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field cannot be empty.';
        }
        return null;
      },
    );
  }
}
