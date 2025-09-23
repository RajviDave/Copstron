import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cp_final/reader/genre_books_page.dart';
import 'package:cp_final/reader/new_releases_page.dart';
import 'package:cp_final/reader/top_rated_page.dart';
import 'package:cp_final/service/database.dart';
import 'package:flutter/material.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final DatabaseService _databaseService = DatabaseService();
  List<String> _genres = [];
  bool _isLoadingGenres = true;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final genres = await _databaseService.getAvailableGenres();
      setState(() {
        _genres = genres;
        _isLoadingGenres = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGenres = false;
      });
      print('Error loading genres: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Books'),
        backgroundColor: const Color(0xFF59AC77),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGenres,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(),
              const SizedBox(height: 24),
              
              // Quick Actions Section
              _buildQuickActionsSection(),
              const SizedBox(height: 24),
              
              // Genres Section
              _buildGenresSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF59AC77), Color(0xFF4A9B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📚 Explore Amazing Books',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Discover new stories, explore different genres, and find your next favorite read',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.auto_stories, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_genres.length} genres available',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Access',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildQuickActionCard(
                title: 'New Releases',
                subtitle: 'Latest books',
                icon: Icons.new_releases,
                color: Colors.blue,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NewReleasesPage(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildQuickActionCard(
                title: 'Top Rated',
                subtitle: 'Most liked books',
                icon: Icons.star,
                color: Colors.orange,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopRatedPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withOpacity(0.1),
          ),
          child: Column(
            children: [
              Icon(icon, size: 32, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenresSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Browse by Genre',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingGenres)
          const Center(child: CircularProgressIndicator())
        else if (_genres.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No genres available yet',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.5,
            ),
            itemCount: _genres.length,
            itemBuilder: (context, index) {
              final genre = _genres[index];
              return _buildGenreCard(genre);
            },
          ),
      ],
    );
  }

  Widget _buildGenreCard(String genre) {
    // Define colors for different genres
    final colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    final color = colors[genre.hashCode % colors.length];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GenreBooksPage(genre: genre),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getGenreIcon(genre),
                  color: color,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  genre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  IconData _getGenreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'romance':
        return Icons.favorite;
      case 'mystery':
      case 'thriller':
        return Icons.search;
      case 'fantasy':
        return Icons.auto_fix_high;
      case 'science fiction':
      case 'sci-fi':
        return Icons.rocket_launch;
      case 'horror':
        return Icons.dark_mode;
      case 'comedy':
      case 'humor':
        return Icons.sentiment_very_satisfied;
      case 'drama':
        return Icons.theater_comedy;
      case 'adventure':
        return Icons.explore;
      case 'biography':
        return Icons.person;
      case 'history':
        return Icons.history_edu;
      case 'self-help':
        return Icons.psychology;
      case 'business':
        return Icons.business;
      case 'technology':
        return Icons.computer;
      case 'health':
        return Icons.health_and_safety;
      case 'cooking':
        return Icons.restaurant;
      case 'travel':
        return Icons.flight;
      case 'art':
        return Icons.palette;
      case 'music':
        return Icons.music_note;
      case 'sports':
        return Icons.sports;
      default:
        return Icons.book;
    }
  }
}
