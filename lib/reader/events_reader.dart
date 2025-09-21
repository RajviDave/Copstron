import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

class EventsReader extends StatefulWidget {
  const EventsReader({Key? key}) : super(key: key);

  @override
  State<EventsReader> createState() => _EventsReaderState();
}

class _EventsReaderState extends State<EventsReader> {
  final DatabaseService _database = DatabaseService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Author Activities'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF59AC77),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Search bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search activities...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                // Filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Book Talks', 'talk'),
                      _buildFilterChip('New Books', 'book'),
                      _buildFilterChip('Announcements', 'announcement'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('content')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No activities found'));
          }

          // Filter activities based on search query and selected filter
          final activities = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final matchesSearch = _searchQuery.isEmpty ||
                (data['title']?.toString().toLowerCase().contains(_searchQuery) ??
                    false) ||
                (data['description']?.toString().toLowerCase().contains(_searchQuery) ??
                    false) ||
                (data['authorName']?.toString().toLowerCase().contains(_searchQuery) ??
                    false);
                    
            if (_selectedFilter == 'all') return matchesSearch;
            return matchesSearch && data['type'] == _selectedFilter;
          }).toList();

          if (activities.isEmpty) {
            return const Center(child: Text('No matching activities found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index].data() as Map<String, dynamic>;
              return _buildActivityCard(activity, context);
            },
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: FilterChip(
        label: Text(label),
        selected: _selectedFilter == value,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: const Color(0xFF59AC77).withOpacity(0.2),
        checkmarkColor: const Color(0xFF59AC77),
        labelStyle: TextStyle(
          color: _selectedFilter == value ? const Color(0xFF59AC77) : Colors.black,
          fontWeight: _selectedFilter == value ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, BuildContext context) {
    final type = activity['type'] ?? 'activity';
    final title = activity['title']?.toString() ?? 'Untitled';
    final description = activity['description']?.toString() ?? '';
    final authorName = activity['authorName']?.toString() ?? 'Unknown Author';
    final imageUrl = activity['imageUrl'] as String?;
    final timestamp = activity['createdAt'] as Timestamp?;
    final date = timestamp != null 
        ? intl.DateFormat('MMM d, y • h:mm a').format(timestamp.toDate())
        : 'Date not available';

    // Define icons and colors based on activity type
    IconData icon;
    Color color;
    String typeLabel;

    switch (type) {
      case 'book':
        icon = Icons.menu_book;
        color = Colors.blue;
        typeLabel = 'New Book';
        break;
      case 'talk':
        icon = Icons.mic;
        color = Colors.orange;
        typeLabel = 'Book Talk';
        break;
      case 'announcement':
        icon = Icons.announcement;
        color = Colors.green;
        typeLabel = 'Announcement';
        break;
      default:
        icon = Icons.notifications;
        color = Colors.purple;
        typeLabel = 'Activity';
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with type and date
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  date,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Author info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  authorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Content image if available
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                ),
              ),
            ),
            
          // Title and description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Show book or talk specific details
                if (type == 'book') ..._buildBookInfo(activity),
                if (type == 'talk') ..._buildTalkInfo(activity),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.favorite_border, size: 24),
                      onPressed: () {
                        // TODO: Handle like
                      },
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.comment_outlined, size: 24),
                      onPressed: () {
                        // TODO: Handle comment
                      },
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.share_outlined, size: 24),
                      onPressed: () {
                        // TODO: Handle share
                      },
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildBookInfo(Map<String, dynamic> activity) {
    final List<Widget> widgets = [
      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 12),
      const Text(
        'Book Details',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 8),
    ];

    // Add book title if available
    if (activity['bookTitle'] != null) {
      widgets.add(_buildInfoRow('Title', activity['bookTitle'].toString()));
    }

    // Add co-authors if available
    if (activity['coAuthors'] != null && activity['coAuthors'] is List) {
      try {
        final coAuthors = (activity['coAuthors'] as List).whereType<String>();
        if (coAuthors.isNotEmpty) {
          widgets.add(_buildInfoRow('Co-authors', coAuthors.join(', ')));
        }
      } catch (e) {
        debugPrint('Error processing co-authors: $e');
      }
    }

    // Add genre if available
    if (activity['genre'] != null) {
      widgets.add(_buildInfoRow('Genre', activity['genre'].toString()));
    }

    // Add publish date if available
    if (activity['publishDate'] != null) {
      widgets.add(_buildInfoRow('Published', activity['publishDate'].toString()));
    }

    return widgets;
  }
  
  List<Widget> _buildTalkInfo(Map<String, dynamic> activity) {
    final List<Widget> widgets = [
      const SizedBox(height: 12),
      const Divider(height: 1),
      const SizedBox(height: 12),
      const Text(
        'Event Details',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
      const SizedBox(height: 8),
    ];

    // Add event date if available
    if (activity['eventDate'] != null) {
      widgets.add(_buildInfoRow('Date', activity['eventDate'].toString()));
    }

    // Add location if available
    if (activity['location'] != null) {
      widgets.add(_buildInfoRow('Location', activity['location'].toString()));
    }

    // Add online status if applicable
    if (activity['isOnline'] == true) {
      widgets.add(_buildInfoRow('Type', 'Online Event'));
    }

    // Add registration link if available
    if (activity['registrationLink'] != null) {
      widgets.add(_buildInfoRow('Registration', 'Required', isLink: true));
    }

    return widgets;
  }
  
  Widget _buildInfoRow(String label, String? value, {bool isLink = false}) {
    // Ensure value is never null
    final displayValue = value ?? 'Not specified';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isLink
                ? GestureDetector(
                    onTap: () {
                      // Handle link tap
                      if (value != null && value.isNotEmpty) {
                        // TODO: Implement link opening logic
                      }
                    },
                    child: Text(
                      displayValue,
                      style: const TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Text(
                    displayValue,
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
  
  // The _buildInfoRow method is already defined above
}
