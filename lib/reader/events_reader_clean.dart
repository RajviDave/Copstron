import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/service/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:timeago/timeago.dart' as timeago;

class EventsReader extends StatefulWidget {
  const EventsReader({super.key});

  @override
  State<EventsReader> createState() => _EventsReaderState();
}

class _CommentsSection extends StatefulWidget {
  final String announcementId;
  final String authorId;
  final User? currentUser;
  final DatabaseService database;

  const _CommentsSection({
    required this.announcementId,
    required this.authorId,
    required this.currentUser,
    required this.database,
  });

  @override
  _CommentsSectionState createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<_CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: widget.database.getCommentsStream(widget.announcementId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No comments yet.');
                    }

                    final comments = snapshot.data!.docs;

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        final commentData = comment.data() as Map<String, dynamic>;
                        final commentUserId = commentData['userId'] as String;

                        return FutureBuilder<Map<String, dynamic>?>(
                          future: widget.database.getUserDataById(commentUserId),
                          builder: (context, userSnapshot) {
                            if (userSnapshot.connectionState == ConnectionState.waiting) {
                              return const SizedBox.shrink();
                            }

                            final commenterName = userSnapshot.data?['name'] ?? 'Anonymous';
                            final canDelete = widget.currentUser?.uid == commentUserId ||
                                widget.currentUser?.uid == widget.authorId;

                            return ListTile(
                              title: Text(commenterName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(commentData['text'] as String),
                              trailing: canDelete
                                  ? IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.grey),
                                      onPressed: () {
                                        widget.database.deleteComment(widget.announcementId, comment.id);
                                      },
                                    )
                                  : null,
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                if (widget.currentUser != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: () {
                            if (_commentController.text.isNotEmpty) {
                              widget.database.addComment(
                                widget.announcementId,
                                _commentController.text,
                                widget.currentUser!.uid,
                              );
                              _commentController.clear();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        TextButton(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Text(_isExpanded ? 'Hide Comments' : 'View Comments'),
        ),
      ],
    );
  }
}

class _EventsReaderState extends State<EventsReader> {
  final DatabaseService _database = DatabaseService();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  User? _currentUser;
  List<String> _savedBookIds = [];

  @override
  void initState() {
    super.initState();
    timeago.setLocaleMessages('en', timeago.EnMessages());
    _getCurrentUser();
  }

  void _getCurrentUser() {
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _database.getSavedBookIdsStream(_currentUser!.uid).listen((savedIds) {
        if (mounted) {
          setState(() {
            _savedBookIds = savedIds;
          });
        }
      });
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latest Updates'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF59AC77),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by book, author, or content...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      const SizedBox(width: 4),
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Book Talks', 'BookTalk'),
                      _buildFilterChip('New Books', 'Book'),
                      _buildFilterChip('Announcements', 'Announcement'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _database.getPublicContentStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading content: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'No activities found. Check back later for updates!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          try {
            final activities = snapshot.data!.docs
                .map((doc) => {
                      'id': doc.id,
                      ...doc.data() as Map<String, dynamic>,
                      'timestamp': (doc.data() as Map<String, dynamic>)['createdAt'] as Timestamp?,
                    })
                .toList();

            activities.sort((a, b) {
              final aTime = a['timestamp'] as Timestamp? ?? Timestamp.now();
              final bTime = b['timestamp'] as Timestamp? ?? Timestamp.now();
              return bTime.compareTo(aTime);
            });

            final filteredActivities = activities.where((activity) {
              final contentType = activity['contentType'] as String? ?? '';
              final searchableText = '${activity['name'] ?? ''} ' 
                                  '${activity['bookName'] ?? ''} ' 
                                  '${activity['text'] ?? ''} ' 
                                  '${activity['authors'] ?? ''} ' 
                                  '${activity['authorName'] ?? ''}'
                                  .toLowerCase();

              if (_selectedFilter != 'all') {
                if (_selectedFilter == 'Book' && contentType != 'Book') return false;
                if (_selectedFilter == 'BookTalk' && contentType != 'BookTalk') return false;
                if (_selectedFilter == 'Announcement' && contentType != 'Announcement') return false;
              }

              if (_searchQuery.isNotEmpty) {
                return searchableText.contains(_searchQuery);
              }

              return true;
            }).toList();

            return _buildActivityList(filteredActivities);
          } catch (e) {
            debugPrint('Error processing activities: $e');
            return const Center(
              child: Text('Error loading content. Please try again later.'),
            );
          }
        },
      ),
    );
  }

  Widget _buildActivityList(List<dynamic> activities) {
    if (activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching activities found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return _buildActivityCard(activity, context);
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? value : 'all';
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: const Color(0xFF59AC77),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? const Color(0xFF59AC77) : Colors.grey[300]!,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, BuildContext context) {
    final contentType = activity['contentType'] as String? ?? '';
    final timestamp = activity['timestamp'] as Timestamp?;
    final date = timestamp != null ? timestamp.toDate() : DateTime.now();
    final timeAgo = timestamp != null ? timeago.format(date, locale: 'en') : 'Just now';
    
    final authorName = activity['authorName'] as String? ?? 'Author';
    final imageUrl = activity['imageUrl'] as String?;
    
    switch (contentType) {
      case 'Book':
        return _buildBookCard(activity, authorName, imageUrl, timeAgo, context);
      case 'BookTalk':
        return _buildBookTalkCard(activity, authorName, imageUrl, timeAgo, context);
      case 'Announcement':
        return _buildAnnouncementCard(activity, authorName, imageUrl, timeAgo, context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBookCard(Map<String, dynamic> book, String authorName, String? imageUrl, String timeAgo, BuildContext context) {
    final title = book['name'] as String? ?? 'Untitled Book';
    final description = book['description'] as String? ?? '';
    final genre = book['genre'] as String?;
    final bookId = book['id'] as String;
    final isSaved = _savedBookIds.contains(bookId);
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book, size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'NEW BOOK',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 80,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 120,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Container(
                    width: 80,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.book, size: 40, color: Colors.grey),
                  ),
                
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 4),
                      
                      Text(
                        'By $authorName',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                      
                      if (genre != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          genre,
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    if (_currentUser != null) {
                      if (isSaved) {
                        _database.unsaveBook(_currentUser!.uid, bookId);
                      } else {
                        _database.saveBook(_currentUser!.uid, bookId);
                      }
                    }
                  },
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Theme.of(context).primaryColor : Colors.grey.shade700,
                  ),
                  label: Text(
                    isSaved ? 'Saved' : 'Save',
                    style: TextStyle(
                      color: isSaved ? Theme.of(context).primaryColor : Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionButton(Icons.share_outlined, 'Share'),
                const Spacer(),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'track') {
                      if (_currentUser != null) {
                        _database.trackBook(_currentUser!.uid, bookId);
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'track',
                      child: Text('Track the book'),
                    ),
                  ],
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBookTalkCard(Map<String, dynamic> talk, String authorName, String? imageUrl, String timeAgo, BuildContext context) {
    final bookName = talk['bookName'] as String? ?? 'Book Talk';
    final authors = talk['authors'] as String? ?? '';
    final isOnline = (talk['eventType'] as String? ?? 'Physical') == 'Online';
    final location = talk['location'] as String?;
    final eventTime = talk['eventTimestamp'] as Timestamp?;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isOnline ? Colors.purple.shade50 : Colors.orange.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  isOnline ? Icons.videocam : Icons.event,
                  color: isOnline ? Colors.purple : Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isOnline ? 'ONLINE BOOK TALK' : 'IN-PERSON BOOK TALK',
                  style: TextStyle(
                    color: isOnline ? Colors.purple : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (eventTime != null && eventTime.toDate().isAfter(DateTime.now()))
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        bookName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'With $authors',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Date & Time',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eventTime != null 
                            ? intl.DateFormat('EEEE, MMMM d, y • h:mm a').format(eventTime.toDate())
                            : 'TBD',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isOnline ? Icons.link : Icons.location_on,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isOnline ? 'Join Online' : 'Location',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
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
                                    isOnline ? 'Link will be provided' : 'Location to be announced',
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
                
                if (eventTime != null && eventTime.toDate().isAfter(DateTime.now()))
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implement join/register action
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOnline ? Colors.purple : Colors.orange,
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
  
  Widget _buildAnnouncementCard(Map<String, dynamic> announcement, String authorName, String? imageUrl, String timeAgo, BuildContext context) {
    final text = announcement['text'] as String? ?? '';
    final dynamic likesData = announcement['likes'];
    final List<String> likes = likesData is List ? List<String>.from(likesData) : [];
    final isLiked = _currentUser != null && likes.contains(_currentUser!.uid);
    final announcementId = announcement['id'] as String;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.campaign, size: 16, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'ANNOUNCEMENT',
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  timeAgo,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade200,
                      child: Text(
                        authorName.isNotEmpty ? authorName[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Author',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  text,
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                
                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        if (_currentUser != null) {
                          _database.toggleLike(announcementId, _currentUser!.uid);
                        }
                      },
                      icon: Icon(
                        isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                        color: isLiked ? Theme.of(context).primaryColor : Colors.grey.shade700,
                        size: 20,
                      ),
                      label: Text(
                        '${likes.length} Likes',
                        style: TextStyle(
                          color: isLiked ? Theme.of(context).primaryColor : Colors.grey.shade700,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _buildActionButton(Icons.comment_outlined, 'Comment'),
                    const SizedBox(width: 16),
                    _buildActionButton(Icons.share_outlined, 'Share'),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          _CommentsSection(
            announcementId: announcementId,
            authorId: announcement['authorId'] as String,
            currentUser: _currentUser,
            database: _database,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(IconData icon, String label) {
    return TextButton.icon(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: Colors.grey.shade700,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }



  }
