import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class GenreBooksPage extends StatefulWidget {
  final String genre;

  const GenreBooksPage({super.key, required this.genre});

  @override
  State<GenreBooksPage> createState() => _GenreBooksPageState();
}

class _GenreBooksPageState extends State<GenreBooksPage> {
  final DatabaseService _databaseService = DatabaseService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.genre} Books'),
        backgroundColor: const Color(0xFF59AC77),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF59AC77).withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore ${widget.genre} Books',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF59AC77),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Discover amazing books in this genre from talented authors',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Books list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _databaseService.getBooksByGenre(widget.genre),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading books: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${widget.genre.toLowerCase()} books available yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new releases!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final books = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: books.length,
                  itemBuilder: (context, index) {
                    final book = books[index].data() as Map<String, dynamic>;
                    final bookId = books[index].id;
                    return _BookCard(
                      book: book,
                      bookId: bookId,
                      currentUser: _currentUser,
                      databaseService: _databaseService,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatefulWidget {
  final Map<String, dynamic> book;
  final String bookId;
  final User? currentUser;
  final DatabaseService databaseService;

  const _BookCard({
    required this.book,
    required this.bookId,
    required this.currentUser,
    required this.databaseService,
  });

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isTracked = false;
  int _likesCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeBookState();
  }

  void _initializeBookState() {
    final likes = widget.book['likes'] as List?;
    _likesCount = likes?.length ?? 0;
    
    if (widget.currentUser != null) {
      _isLiked = likes?.contains(widget.currentUser!.uid) ?? false;
      _checkIfSaved();
      _checkIfTracked();
    }
  }

  Future<void> _checkIfSaved() async {
    if (widget.currentUser == null) return;
    
    try {
      final savedBooksStream = widget.databaseService.getSavedBookIdsStream(widget.currentUser!.uid);
      savedBooksStream.listen((savedBookIds) {
        if (mounted) {
          setState(() {
            _isSaved = savedBookIds.contains(widget.bookId);
          });
        }
      });
    } catch (e) {
      print('Error checking if book is saved: $e');
    }
  }

  Future<void> _checkIfTracked() async {
    if (widget.currentUser == null) return;
    
    try {
      final trackedBooksStream = widget.databaseService.getTrackedBooksStream(widget.currentUser!.uid);
      trackedBooksStream.listen((snapshot) {
        if (mounted) {
          final trackedBookIds = snapshot.docs.map((doc) => doc.id).toList();
          setState(() {
            _isTracked = trackedBookIds.contains(widget.bookId);
          });
        }
      });
    } catch (e) {
      print('Error checking if book is tracked: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (widget.currentUser == null) return;

    try {
      await widget.databaseService.toggleLike(widget.bookId, widget.currentUser!.uid);
      setState(() {
        if (_isLiked) {
          _likesCount--;
        } else {
          _likesCount++;
        }
        _isLiked = !_isLiked;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleSave() async {
    if (widget.currentUser == null) return;

    try {
      if (_isSaved) {
        await widget.databaseService.unsaveBook(widget.currentUser!.uid, widget.bookId);
      } else {
        await widget.databaseService.saveBook(widget.currentUser!.uid, widget.bookId);
      }
      setState(() {
        _isSaved = !_isSaved;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Book saved!' : 'Book removed from saved'),
          backgroundColor: _isSaved ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _toggleTrack() async {
    if (widget.currentUser == null) return;

    try {
      if (_isTracked) {
        await widget.databaseService.untrackBook(widget.currentUser!.uid, widget.bookId);
      } else {
        await widget.databaseService.trackBook(widget.currentUser!.uid, widget.bookId);
      }
      setState(() {
        _isTracked = !_isTracked;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isTracked ? 'Book added to reading list!' : 'Book removed from reading list'),
          backgroundColor: _isTracked ? Colors.green : Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.book['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? DateFormat('MMMM d, yyyy').format(timestamp.toDate())
        : 'No date';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book image
          if (widget.book['imageUrl'] != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                widget.book['imageUrl'],
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book title and genre
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.book['name'] ?? 'No Title',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF59AC77).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.book['genre'] ?? 'Unknown',
                        style: const TextStyle(
                          color: Color(0xFF59AC77),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Author name
                Text(
                  'By ${widget.book['authorName'] ?? 'Unknown Author'}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Publisher
                if (widget.book['publisher'] != null) ...[
                  Text(
                    'Published by: ${widget.book['publisher']}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                
                // Description
                Text(
                  widget.book['description'] ?? 'No description available.',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[800]),
                ),
                const SizedBox(height: 12),
                
                // Publication date
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Published: $dateString',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Action buttons
                if (widget.currentUser != null) ...[
                  Row(
                    children: [
                      // Like button
                      IconButton(
                        onPressed: _toggleLike,
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey,
                        ),
                      ),
                      Text('$_likesCount'),
                      const SizedBox(width: 16),
                      
                      // Save button
                      IconButton(
                        onPressed: _toggleSave,
                        icon: Icon(
                          _isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: _isSaved ? const Color(0xFF59AC77) : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Track reading button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _toggleTrack,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isTracked ? Colors.orange : const Color(0xFF59AC77),
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(_isTracked ? Icons.remove_circle : Icons.add_circle),
                          label: Text(_isTracked ? 'Stop Reading' : 'Start Reading'),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Sign in to interact with books',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
