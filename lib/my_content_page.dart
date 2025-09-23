import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyContentPage extends StatefulWidget {
  const MyContentPage({super.key});

  @override
  State<MyContentPage> createState() => _MyContentPageState();
}

class _MyContentPageState extends State<MyContentPage> {
  String _searchQuery = '';
  // Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String contentType,
    String title,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Content'),
              content: Text(
                'Are you sure you want to delete this $contentType? This action cannot be undone.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('DELETE'),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed
  }

  // Handle content deletion
  Future<void> _deleteContent(
    String docId,
    String authorId,
    String contentType,
  ) async {
    try {
      final db = DatabaseService(uid: FirebaseAuth.instance.currentUser?.uid);
      await db.deleteContent(docId, authorId, contentType);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Content deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete content: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle delete action
  Future<void> _handleDelete(
    String docId,
    String authorId,
    String contentType,
    String contentTitle,
  ) async {
    final shouldDelete = await _showDeleteConfirmation(
      context,
      contentType,
      contentTitle,
    );
    if (shouldDelete && mounted) {
      await _deleteContent(docId, authorId, contentType);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text("Please log in to see your content."));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Content'),
        backgroundColor: const Color(0xFF59AC77),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search by title...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService(uid: user.uid).getUserPublicContent(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error loading content: ${snapshot.error}"),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("You haven't created any content yet."),
            );
          }

          var docs = snapshot.data!.docs.where((doc) {
            if (_searchQuery.isEmpty) {
              return true;
            }
            var data = doc.data() as Map<String, dynamic>;
            var title =
                data['name'] as String? ??
                data['bookName'] as String? ??
                data['text'] as String? ??
                '';
            return title.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          // Sort documents by creation date (newest first)
          docs.sort((a, b) {
            var aTime =
                (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp? ??
                Timestamp.now();
            var bTime =
                (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp? ??
                Timestamp.now();
            return bTime.compareTo(aTime);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String contentType = data['contentType'] ?? 'Unknown';
              String docId = docs[index].id;

              switch (contentType) {
                case 'Book':
                  return _BookCard(
                    data: data,
                    docId: docId,
                    onDelete: () => _handleDelete(
                      docId,
                      data['authorId'] ?? '',
                      'book',
                      data['name'] ?? 'this book',
                    ),
                  );
                case 'Announcement':
                  return _AnnouncementCard(
                    data: data,
                    docId: docId,
                    onDelete: () => _handleDelete(
                      docId,
                      data['authorId'] ?? '',
                      'announcement',
                      'this announcement',
                    ),
                  );
                case 'BookTalk':
                  return _BookTalkCard(
                    data: data,
                    docId: docId,
                    onDelete: () => _handleDelete(
                      docId,
                      data['authorId'] ?? '',
                      'book talk',
                      'this book talk',
                    ),
                  );
                default:
                  return const SizedBox.shrink(); // Hide unknown content types
              }
            },
          );
        },
      ),
    );
  }
}

// --- CARD WIDGETS ---

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onDelete;

  const _BookCard({
    required this.data,
    required this.docId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Draft';
    final timestamp = data['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? DateFormat('MMMM d, yyyy').format(timestamp.toDate())
        : 'No date';
    final imageUrl = data['imageUrl'] as String?;
    final genre = data['genre'] as String?;
    final publisher = data['publisher'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image section
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: status == 'Published'
                            ? Colors.green.shade100
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: status == 'Published'
                              ? Colors.green.shade800
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.book, color: Color(0xFF59AC77)),
                    const SizedBox(width: 8),
                    const Text(
                      "BOOK",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF59AC77),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  data['name'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (genre != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    genre,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                if (publisher != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Published by: $publisher',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  data['description'] ?? 'No description provided.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[800]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateString,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.data,
    required this.docId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = data['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate())
        : 'No date';
    final text = data['text'] as String?;
    final imageUrl = data['imageUrl'] as String?;
    final authorName = data['authorName'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image section if available
          if (imageUrl != null && imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.broken_image,
                    size: 48,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.campaign, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "ANNOUNCEMENT",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const Spacer(),
                    if (authorName != null)
                      Text(
                        'By $authorName',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (text != null && text.isNotEmpty)
                  Text(text, style: const TextStyle(fontSize: 16, height: 1.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dateString,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
}

class _BookTalkCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;
  final VoidCallback onDelete;

  const _BookTalkCard({
    required this.data,
    required this.docId,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final timestamp = data['eventTimestamp'] as Timestamp?;
    final dateString = timestamp != null
        ? DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate())
        : 'No date';
    final bookName = data['bookName'] as String? ?? 'Untitled Book';
    final authors = data['authors'] as String?;
    final eventType = data['eventType'] as String? ?? 'Physical';
    final location = data['location'] as String?;
    final isOnline = eventType == 'Online';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with event type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isOnline ? Colors.blue.shade50 : Colors.purple.shade50,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.videocam : Icons.location_on,
                  color: isOnline ? Colors.blue : Colors.purple,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'ONLINE EVENT' : 'IN-PERSON EVENT',
                  style: TextStyle(
                    color: isOnline ? Colors.blue : Colors.purple,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
                if (timestamp != null &&
                    timestamp.toDate().isAfter(DateTime.now()))
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'UPCOMING',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book title
                Text(
                  bookName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),

                // Authors
                if (authors != null && authors.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          authors,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Event details
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date & Time
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Date & Time',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateString,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Location/Online Link
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isOnline ? Icons.link : Icons.location_on,
                            size: 16,
                            color: Colors.grey[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOnline ? 'Online Link' : 'Location',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (location != null && location.isNotEmpty)
                                  Text(
                                    location,
                                    style: const TextStyle(fontSize: 14),
                                  )
                                else
                                  Text(
                                    isOnline
                                        ? 'Link will be provided'
                                        : 'Location to be announced',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons
                if (timestamp != null &&
                    timestamp.toDate().isAfter(DateTime.now()))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement join/register action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.event_available, size: 20),
                      label: Text(
                        isOnline ? 'JOIN EVENT' : 'REGISTER',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
