import 'package:cp_final/announcement_page.dart';
import 'package:cp_final/book_talk_page.dart';
import 'package:cp_final/publish_book_page.dart';
import 'package:flutter/material.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF59AC77);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Content'),
        backgroundColor: primaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildOptionCard(
            context: context,
            icon: Icons.book,
            title: 'Publish Book Post',
            subtitle: 'Share a new book or an update on an existing one.',
            color: primaryColor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const PublishBookPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context: context,
            icon: Icons.campaign,
            title: 'Announcement',
            subtitle: 'Post a general announcement to all your readers.',
            color: Colors.orange,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AnnouncementPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            context: context,
            icon: Icons.mic,
            title: 'Book Talk',
            subtitle: 'Schedule a new live event or book talk session.',
            color: Colors.blue,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const BookTalkPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Helper widget to build the tappable option cards for a consistent look
  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(width: 20),
              Expanded(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
