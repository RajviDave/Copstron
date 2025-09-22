import 'package:flutter/material.dart';

class LibraryReader extends StatelessWidget {
  const LibraryReader({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Library'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF59AC77),
          bottom: const TabBar(
            labelColor: Color(0xFF59AC77),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF59AC77),
            tabs: [
              Tab(icon: Icon(Icons.collections_bookmark), text: 'Reading'),
              Tab(icon: Icon(Icons.bookmark), text: 'Saved'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [_ReadingTab(), _SavedTab(), _HistoryTab()],
        ),
      ),
    );
  }
}

class _ReadingTab extends StatelessWidget {
  const _ReadingTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> readingList = [
      {
        'title': 'The Midnight Library',
        'author': 'Matt Haig',
        'progress': 0.65,
        'cover': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
      },
      {
        'title': 'Project Hail Mary',
        'author': 'Andy Weir',
        'progress': 0.30,
        'cover': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: readingList.length,
      itemBuilder: (context, index) {
        final book = readingList[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    book['cover'],
                    width: 80,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        book['author'],
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: book['progress'],
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF59AC77),
                        ),
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(book['progress'] * 100).toInt()}% completed',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    // TODO: Show options menu
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SavedTab extends StatelessWidget {
  const _SavedTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> savedBooks = [
      {
        'title': 'Dune',
        'author': 'Frank Herbert',
        'cover': 'https://images.unsplash.com/photo-1589998059171-988d887df646',
      },
      {
        'title': 'The Song of Achilles',
        'author': 'Madeline Miller',
        'cover': 'https://images.unsplash.com/photo-1541963463532-d68292c34b19',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: savedBooks.length,
      itemBuilder: (context, index) {
        final book = savedBooks[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                book['cover']!,
                width: 50,
                height: 75,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              book['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(book['author']!),
            trailing: IconButton(
              icon: const Icon(Icons.bookmark, color: Color(0xFF59AC77)),
              onPressed: () {
                // TODO: Remove from saved
              },
            ),
          ),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> history = [
      {
        'title': 'The Midnight Library',
        'author': 'Matt Haig',
        'date': '2 days ago',
        'cover': 'https://images.unsplash.com/photo-1544947950-fa07a98d237f',
      },
      {
        'title': 'Project Hail Mary',
        'author': 'Andy Weir',
        'date': '1 week ago',
        'cover': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final item = history[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item['cover'],
                width: 50,
                height: 75,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['author']),
                const SizedBox(height: 4),
                Text(
                  item['date'],
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {
                // TODO: Navigate to book details
              },
            ),
          ),
        );
      },
    );
  }
}
