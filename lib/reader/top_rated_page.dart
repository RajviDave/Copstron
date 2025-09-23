import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TopRatedPage extends StatefulWidget {
  const TopRatedPage({super.key});

  @override
  State<TopRatedPage> createState() => _TopRatedPageState();
}

class _TopRatedPageState extends State<TopRatedPage> {
  final DatabaseService _databaseService = DatabaseService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rated Books'),
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
                  Colors.orange.withOpacity(0.1),
                  Colors.orange.withOpacity(0.05),
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
                    const Icon(Icons.star, color: Colors.orange, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Most Loved Books',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Books with the highest number of likes from our community',
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
              stream: _databaseService.getTopRatedBooks(),
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
                          Icons.star_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No rated books available yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to like some books!',
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

                // Sort books by likes count (highest first)
                final books = snapshot.data!.docs.toList();
                books.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aLikes = (aData['likes'] as List?)?.length ?? 0;
                  final bLikes = (bData['likes'] as List?)?.length ?? 0;
                  return bLikes.compareTo(aLikes);
                });

                // Filter out books with no likes for a cleaner top rated list
                final ratedBooks = books.where((book) {
                  final data = book.data() as Map<String, dynamic>;
                  final likes = (data['likes'] as List?)?.length ?? 0;
                  return likes > 0;
                }).toList();

                if (ratedBooks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.star_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No books have been liked yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to show some love!',
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

                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {});
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: ratedBooks.length,
                    itemBuilder: (context, index) {
                      final book = ratedBooks[index].data() as Map<String, dynamic>;
                      final bookId = ratedBooks[index].id;
                      final likesCount = (book['likes'] as List?)?.length ?? 0;
                      
                      return _BookCard(
                        book: book,
                        bookId: bookId,
                        currentUser: _currentUser,
                        databaseService: _databaseService,
                        ranking: index + 1,
                        likesCount: likesCount,
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
}

class _BookCard extends StatefulWidget {
  final Map<String, dynamic> book;
  final String bookId;
  final User? currentUser;
  final DatabaseService databaseService;
  final int ranking;
  final int likesCount;

  const _BookCard({
    required this.book,
    required this.bookId,
    required this.currentUser,
    required this.databaseService,
    required this.ranking,
    required this.likesCount,
  });

  @override
  State<_BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<_BookCard> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _isSaved = false;
  bool _isTracked = false;
  late int _likesCount;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.likesCount;
    _initializeBookState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300 + (widget.ranking * 50)),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
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

  Color _getRankingColor() {
    switch (widget.ranking) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey[400]!; // Silver
      case 3:
        return Colors.brown[300]!; // Bronze
      default:
        return Colors.orange;
    }
  }

  IconData _getRankingIcon() {
    switch (widget.ranking) {
      case 1:
        return Icons.emoji_events; // Trophy
      case 2:
        return Icons.military_tech; // Medal
      case 3:
        return Icons.military_tech; // Medal
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = widget.book['createdAt'] as Timestamp?;
    final dateString = timestamp != null
        ? DateFormat('MMMM d, yyyy').format(timestamp.toDate())
        : 'No date';

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: widget.ranking <= 3 ? 8 : 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: widget.ranking <= 3 
                  ? BorderSide(color: _getRankingColor(), width: 2)
                  : BorderSide.none,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book image with ranking badge
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
                    
                    // Ranking badge
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getRankingColor(),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getRankingIcon(),
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '#${widget.ranking}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Likes count badge
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.favorite,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$_likesCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.book['genre'],
                                style: const TextStyle(
                                  color: Colors.orange,
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
                      
                      // Popularity indicator
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getRankingColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: _getRankingColor(),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rank #${widget.ranking} • $_likesCount likes',
                              style: TextStyle(
                                color: _getRankingColor(),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
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
                                  backgroundColor: _isTracked ? Colors.orange : _getRankingColor(),
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
        );
      },
    );
  }
}
