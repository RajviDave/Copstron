import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LibraryReader extends StatefulWidget {
  const LibraryReader({super.key});

  @override
  _LibraryReaderState createState() => _LibraryReaderState();
}

class _LibraryReaderState extends State<LibraryReader> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DatabaseService _database = DatabaseService();
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your library.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Library'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF59AC77),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF59AC77),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF59AC77),
          tabs: const [
            Tab(icon: Icon(Icons.collections_bookmark), text: 'Reading'),
            Tab(icon: Icon(Icons.bookmark), text: 'Saved'),
            Tab(icon: Icon(Icons.history), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BookList(bookIdsStream: _database.getTrackedBookIdsStream(_currentUser!.uid)),
          _BookList(bookIdsStream: _database.getSavedBookIdsStream(_currentUser!.uid)),
          const _HistoryTab(), // History tab remains static for now
        ],
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  final Stream<List<String>> bookIdsStream;
  final DatabaseService _database = DatabaseService();

  _BookList({required this.bookIdsStream});

  Future<List<DocumentSnapshot>> _getBooksByIds(List<String> bookIds) async {
    final List<DocumentSnapshot> bookDocs = [];
    for (String id in bookIds) {
      // Assuming books are stored in the 'publicContent' collection
      final doc = await _database.publicContentCollection.doc(id).get();
      if (doc.exists) {
        bookDocs.add(doc);
      }
    }
    return bookDocs;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<String>>(
      stream: bookIdsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No books found in this section.'));
        }

        final bookIds = snapshot.data!;

        return FutureBuilder<List<DocumentSnapshot>>(
          future: _getBooksByIds(bookIds),
          builder: (context, bookSnapshot) {
            if (bookSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (bookSnapshot.hasError) {
              return Center(child: Text('Error: ${bookSnapshot.error}'));
            }
            if (!bookSnapshot.hasData || bookSnapshot.data!.isEmpty) {
              return const Center(child: Text('No books to display.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookSnapshot.data!.length,
              itemBuilder: (context, index) {
                final book = bookSnapshot.data![index].data() as Map<String, dynamic>;
                return _BookCard(book: book);
              },
            );
          },
        );
      },
    );
  }
}

class _BookCard extends StatelessWidget {
  final Map<String, dynamic> book;

  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
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
          child: book['imageUrl'] != null
              ? Image.network(
                  book['imageUrl'],
                  width: 50,
                  height: 75,
                  fit: BoxFit.cover,
                )
              : Container(
                  width: 50,
                  height: 75,
                  color: Colors.grey[200],
                  child: const Icon(Icons.book, color: Colors.grey),
                ),
        ),
        title: Text(
          book['name'] ?? 'No Title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(book['authorName'] ?? 'Unknown Author'),
      ),
    );
  }
}

// Static History Tab for now
class _HistoryTab extends StatelessWidget {
  const _HistoryTab();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('History will be implemented later.'));
  }
}
