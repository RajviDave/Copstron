import 'package:flutter/material.dart';

class EventsReader extends StatelessWidget {
  const EventsReader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events & Talks'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF59AC77),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Upcoming Events'),
          const SizedBox(height: 16),
          _buildEventCard(
            'Virtual Book Club: Sci-Fi Edition',
            'Join us for a discussion on the latest science fiction releases.',
            'May 15, 2023 • 6:00 PM',
            'https://images.unsplash.com/photo-1510172951991-856a62a9df94',
            'Virtual',
            true,
          ),
          const SizedBox(height: 16),
          _buildEventCard(
            'Author Talk: Jane Smith',
            'Bestselling author Jane Smith discusses her new novel and writing process.',
            'May 20, 2023 • 7:30 PM',
            'https://images.unsplash.com/photo-1522071820081-009c7c3e1db5',
            'Main Library',
            false,
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Past Events'),
          const SizedBox(height: 16),
          _buildPastEventCard(
            'Poetry Reading Night',
            'April 10, 2023',
            'https://images.unsplash.com/photo-1506880018603-83d39b870e46',
          ),
          const SizedBox(height: 12),
          _buildPastEventCard(
            'Book Signing: John Doe',
            'March 28, 2023',
            'https://images.unsplash.com/photo-1529154691717-478b8a0f1b84',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implement create event functionality
        },
        backgroundColor: const Color(0xFF59AC77),
        icon: const Icon(Icons.add),
        label: const Text('Create Event'),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF333333),
      ),
    );
  }

  Widget _buildEventCard(
    String title,
    String description,
    String dateTime,
    String imageUrl,
    String location,
    bool isOnline,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
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
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dateTime,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isOnline ? Icons.videocam : Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOnline ? 'Online Event' : location,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Handle RSVP
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF59AC77),
                          side: const BorderSide(color: Color(0xFF59AC77)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('RSVP'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: Handle more details
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF59AC77),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Details'),
                      ),
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

  Widget _buildPastEventCard(String title, String date, String imageUrl) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
            width: 60,
            height: 80,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          date,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // TODO: Navigate to event details
        },
      ),
    );
  }
}
