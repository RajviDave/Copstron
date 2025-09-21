import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyContentPage extends StatelessWidget {
  const MyContentPage({Key? key}) : super(key: key);

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
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: DatabaseService(uid: user.uid).getContentStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Something went wrong."));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("You haven't created any content yet."),
            );
          }

          var docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String contentType = data['contentType'] ?? 'Unknown';

              switch (contentType) {
                case 'Book':
                  return _BookCard(data: data);
                case 'Announcement':
                  return _AnnouncementCard(data: data);
                case 'BookTalk':
                  return _BookTalkCard(data: data);
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
  const _BookCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'Draft';
    final timestamp = data['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? DateFormat('MMMM d, yyyy').format(timestamp.toDate())
        : 'No date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.book, color: Color(0xFF59AC77)),
                const SizedBox(width: 8),
                const Text(
                  "BOOK POST",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF59AC77),
                  ),
                ),
                const Spacer(),
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
              ],
            ),
            const Divider(height: 20),
            Text(
              data['name'] ?? 'No Title',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              data['description'] ?? 'No description.',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Text(
              dateString,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnnouncementCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final timestamp = data['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? DateFormat('MMMM d, yyyy \'at\' h:mm a').format(timestamp.toDate())
        : 'No date';
    return Card(/* ... Similar beautiful card design for announcements ... */);
  }
}

class _BookTalkCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _BookTalkCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final timestamp = data['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? DateFormat('MMMM d, yyyy').format(timestamp.toDate())
        : 'No date';
    final eventDate = data['date'] != null
        ? DateFormat(
            'MMMM d, yyyy',
          ).format((data['date'] as Timestamp).toDate())
        : 'TBA';

    return Card(/* ... Similar beautiful card design for book talks ... */);
  }
}
