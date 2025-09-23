import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NewReleasesPage extends StatefulWidget {
  const NewReleasesPage({super.key});

  @override
  State<NewReleasesPage> createState() => _NewReleasesPageState();
}

class _NewReleasesPageState extends State<NewReleasesPage> {
  final DatabaseService _databaseService = DatabaseService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Releases'),
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
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.blue.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.new_releases, color: Colors.blue, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Latest Book Releases',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Discover the newest books from our talented authors',
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
              stream: _databaseService.getAllBooks(), // Get all books to show more than just 4
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
                          'No books available yet',
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

                // Sort books by creation date (newest first)
                final books = snapshot.data!.docs.toList();
                books.sort((a, b) {
                  final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index].data() as Map<String, dynamic>;
                      final bookId = books[index].id;
                      final isNew = _isNewRelease(book['createdAt'] as Timestamp?);
                      
                      return _BookCard(
                        book: book,
                        bookId: bookId,
                        currentUser: _currentUser,
                        databaseService: _databaseService,
                        isNew: isNew,
                        index: index,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _isNewRelease(Timestamp? createdAt) {
    if (createdAt == null) return false;
    final now = DateTime.now();
    final bookDate = createdAt.toDate();
    final difference = now.difference(bookDate).inDays;
    return difference <= 7; // Consider books published in the last 7 days as "new"
  }
}

class _BookCard extends StatefulWidget {
  final Map<String, dynamic> book;
  final String bookId;
  final User? currentUser;
  final DatabaseService databaseService;
  final bool isNew;
  final int index;

  const _BookCard({
    required this.book,
    required this.bookId,
    required this.currentUser,
    required this.databaseService,
    required this.isNew,
    required this.index,
  });

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isTracked = false;
  int _likesCount = 0;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeBookState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.index * 100)),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Book image with new badge
                  Stack(
                    children: [
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
                      
                      // New release badge
                      if (widget.isNew)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      
                      // Ranking badge for top books
                      if (widget.index < 3)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.index == 0 ? Colors.amber : 
                                     widget.index == 1 ? Colors.grey[400] : 
                                     Colors.brown[300],
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '#${widget.index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
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
                            if (widget.book['genre'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.book['genre'],
                                  style: const TextStyle(
                                    color: Colors.blue,
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
                            if (widget.isNew) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.fiber_new, size: 16, color: Colors.red),
                              Text(
                                'New Release!',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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
                                    backgroundColor: _isTracked ? Colors.orange : Colors.blue,
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
            ),
          ),
        );
      },
    );
  }
}
