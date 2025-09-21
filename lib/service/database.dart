import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Reference to the main users collection
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  // Reference to the content subcollection for a specific user
  CollectionReference get contentCollection =>
      userCollection.doc(uid).collection('content');

  // Update/Create user data (for role, name, email)
  Future<void> updateUserData(String name, String email, String role) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
    });
  }

  // Get user role from Firestore
  Future<String?> getUserRole() async {
    try {
      DocumentSnapshot doc = await userCollection.doc(uid).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['role'];
      }
      return null;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  // --- NEW: Add a piece of content (Book, Announcement, etc.) ---
  Future<DocumentReference<Object?>> addContent(
    Map<String, dynamic> contentData,
  ) async {
    // Add a server-side timestamp for ordering
    contentData['createdAt'] = FieldValue.serverTimestamp();
    return await contentCollection.add(contentData);
  }

  // --- NEW: Get a stream of the author's content ---
  Stream<QuerySnapshot> getContentStream() {
    return contentCollection.orderBy('createdAt', descending: true).snapshots();
  }
}
