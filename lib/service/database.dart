import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
  final CollectionReference contentCollection = FirebaseFirestore.instance.collection('content');
  final CollectionReference booksCollection = FirebaseFirestore.instance.collection('books');

  Future<void> updateUserData(String name, String email, String role) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
    }, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getUserData() async {
    try {
      DocumentSnapshot doc = await userCollection.doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  Future<String?> getUserRole() async {
    try {
      final userData = await getUserData();
      return userData?['role'];
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  Future<void> addContent(Map<String, dynamic> contentData) async {
    try {
      contentData['authorId'] = uid;
      contentData['createdAt'] = FieldValue.serverTimestamp();
      
      // Add to the global content collection
      await contentCollection.add(contentData);
      
      // Also add to user's content subcollection for easy querying
      await userCollection.doc(uid).collection('content').add(contentData);
    } catch (e) {
      print('Error adding content: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot> getContentStream() {
    return contentCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get all books by this author
  Stream<QuerySnapshot> getAuthorBooksStream() {
    return booksCollection
        .where('authorId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get count of books by this author
  Stream<int> getBookCountStream() {
    return booksCollection
        .where('authorId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
