import 'package:flutter/material.dart';

class ExploreReader extends StatelessWidget {
  const ExploreReader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Explore'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF59AC77),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Color(0xFF59AC77),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF59AC77),
            tabs: [
              Tab(text: 'Trending'),
              Tab(text: 'Genres'),
              Tab(text: 'New Releases'),
              Tab(text: 'Top Rated'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTrendingTab(),
            _buildGenresTab(),
            _buildNewReleasesTab(),
            _buildTopRatedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookGrid([
          {'title': 'The Song of Achilles', 'author': 'Madeline Miller'},
          {'title': 'Piranesi', 'author': 'Susanna Clarke'},
          {'title': 'Klara and the Sun', 'author': 'Kazuo Ishiguro'},
          {'title': 'The Four Winds', 'author': 'Kristin Hannah'},
        ]),
      ],
    );
  }

  Widget _buildGenresTab() {
    final List<Map<String, dynamic>> genres = [
      {'name': 'Fiction', 'emoji': '📚'},
      {'name': 'Mystery', 'emoji': '🕵️'},
      {'name': 'Romance', 'emoji': '💖'},
      {'name': 'Sci-Fi', 'emoji': '🚀'},
      {'name': 'Fantasy', 'emoji': '🐉'},
      {'name': 'Biography', 'emoji': '📖'},
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: genres.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '${genres[index]['emoji']} ${genres[index]['name']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNewReleasesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookGrid([
          {'title': 'The Last Thing He Told Me', 'author': 'Laura Dave'},
          {'title': 'The Midnight Library', 'author': 'Matt Haig'},
          {'title': 'The Push', 'author': 'Ashley Audrain'},
          {'title': 'The Sanatorium', 'author': 'Sarah Pearse'},
        ]),
      ],
    );
  }

  Widget _buildTopRatedTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildBookGrid([
          {'title': 'The Vanishing Half', 'author': 'Brit Bennett'},
          {'title': 'The Invisible Life', 'author': 'Addie LaRue'},
          {'title': 'Project Hail Mary', 'author': 'Andy Weir'},
          {'title': 'The Four Winds', 'author': 'Kristin Hannah'},
        ]),
      ],
    );
  }

  Widget _buildBookGrid(List<Map<String, String>> books) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: books.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    'https://picsum.photos/200/300?random=$index',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      books[index]['title']!,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      books[index]['author']!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
