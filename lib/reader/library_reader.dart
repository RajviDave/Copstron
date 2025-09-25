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
        title: const Text(
          'My Library',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF59AC77),
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
          _TrackedBookList(trackedBooksStream: _database.getTrackedBooksStream(_currentUser!.uid)),
          _SavedBookList(bookIdsStream: _database.getSavedBookIdsStream(_currentUser!.uid)),
          _HistoryList(historyStream: _database.getHistoryStream(_currentUser!.uid)),
        ],
      ),
    );
  }
}

class _SavedBookList extends StatelessWidget {
  final Stream<List<String>> bookIdsStream;
  final DatabaseService _database = DatabaseService();

  _SavedBookList({required this.bookIdsStream});

  Future<List<DocumentSnapshot>> _getBooksByIds(List<String> bookIds) async {
    final List<DocumentSnapshot> bookDocs = [];
    for (String id in bookIds) {
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
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No saved books.'));
        }

        final bookIds = snapshot.data!;

        return FutureBuilder<List<DocumentSnapshot>>(
          future: _getBooksByIds(bookIds),
          builder: (context, bookSnapshot) {
            if (bookSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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

class _TrackedBookList extends StatelessWidget {
  final Stream<QuerySnapshot> trackedBooksStream;
  final DatabaseService _database = DatabaseService();

  _TrackedBookList({required this.trackedBooksStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: trackedBooksStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No books being tracked.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final trackedBook = snapshot.data!.docs[index];
            final progressData = trackedBook.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: _database.publicContentCollection.doc(trackedBook.id).get(),
              builder: (context, bookSnapshot) {
                if (bookSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Or a small loader
                }
                if (!bookSnapshot.hasData || !bookSnapshot.data!.exists) {
                  // This book has been deleted by the author.
                  return const SizedBox.shrink();
                }
                final book = bookSnapshot.data!.data() as Map<String, dynamic>;
                return _BookCard(book: book, progressData: progressData, bookId: trackedBook.id);
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
  final Map<String, dynamic>? progressData;
  final Map<String, dynamic>? historyData;
  final String? bookId;

  const _BookCard({required this.book, this.progressData, this.historyData, this.bookId});

  @override
  Widget build(BuildContext context) {
    final totalPages = progressData?['totalPages'] ?? 0;
    final pagesRead = progressData?['pagesRead'] ?? 0;
    final progress = totalPages > 0 ? pagesRead / totalPages : 0.0;
    final finishedAt = historyData?['finishedAt'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          if (progressData != null && bookId != null) {
            showDialog(
              context: context,
              builder: (context) => _ProgressDialog(
                bookId: bookId!,
                initialTotalPages: totalPages,
                initialPagesRead: pagesRead,
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: book['imageUrl'] != null
                        ? Image.network(book['imageUrl'], width: 50, height: 75, fit: BoxFit.cover)
                        : Container(width: 50, height: 75, color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(book['name'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(book['authorName'] ?? 'Unknown Author'),
                      ],
                    ),
                  ),
                ],
              ),
              if (progressData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: progress, backgroundColor: Colors.grey[200]),
                      const SizedBox(height: 4),
                      Text('${(progress * 100).toInt()}% read'),
                    ],
                  ),
                ),
              if (finishedAt != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Finished on: ${finishedAt.toDate().toLocal().toString().split(' ')[0]}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressDialog extends StatefulWidget {
  final String bookId;
  final int initialTotalPages;
  final int initialPagesRead;

  const _ProgressDialog({
    required this.bookId,
    required this.initialTotalPages,
    required this.initialPagesRead,
  });

  @override
  _ProgressDialogState createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  late final TextEditingController _totalPagesController;
  late final TextEditingController _pagesReadController;
  final DatabaseService _database = DatabaseService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _totalPagesController = TextEditingController(text: widget.initialTotalPages.toString());
    _pagesReadController = TextEditingController(text: widget.initialPagesRead.toString());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Progress'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _totalPagesController,
            decoration: const InputDecoration(labelText: 'Total Pages'),
            keyboardType: TextInputType.number,
          ),
          TextField(
            controller: _pagesReadController,
            decoration: const InputDecoration(labelText: 'Pages Read'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final totalPages = int.tryParse(_totalPagesController.text) ?? 0;
            final pagesRead = int.tryParse(_pagesReadController.text) ?? 0;
            if (_currentUser != null) {
              if (totalPages > 0 && pagesRead >= totalPages) {
                _database.moveBookToHistory(_currentUser!.uid, widget.bookId);
              } else {
                _database.updateBookProgress(_currentUser!.uid, widget.bookId, totalPages, pagesRead);
              }
            }
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _HistoryList extends StatelessWidget {
  final Stream<QuerySnapshot> historyStream;
  final DatabaseService _database = DatabaseService();

  _HistoryList({required this.historyStream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: historyStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('You have no read history yet.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final historyDoc = snapshot.data!.docs[index];
            final historyData = historyDoc.data() as Map<String, dynamic>;

            return FutureBuilder<DocumentSnapshot>(
              future: _database.publicContentCollection.doc(historyDoc.id).get(),
              builder: (context, bookSnapshot) {
                if (bookSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink(); // Or a small loader
                }
                if (!bookSnapshot.hasData || !bookSnapshot.data!.exists) {
                  // This book has been deleted by the author.
                  return const SizedBox.shrink();
                }
                final book = bookSnapshot.data!.data() as Map<String, dynamic>;
                return _BookCard(book: book, historyData: historyData);
              },
            );
          },
        );
      },
    );
  }
}
