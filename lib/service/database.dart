import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Reference to the users collection
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  // Reference to the public content collection
  final CollectionReference publicContentCollection = FirebaseFirestore.instance
      .collection('publicContent');

  // Get user's private content collection
  CollectionReference get privateContentCollection {
    if (uid == null) {
      throw Exception('User ID is required to access private content');
    }
    return userCollection.doc(uid).collection('content');
  }

  // Update user data
  Future<void> updateUserData(String name, String email, String role) async {
    if (uid == null) {
      throw Exception('User ID is required to update user data');
    }

    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    if (uid == null) return null;

    try {
      DocumentSnapshot doc = await userCollection.doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      rethrow;
    }
  }

  // Get user role
  Future<String?> getUserRole() async {
    try {
      final userData = await getUserData();
      return userData?['role'] as String?;
    } catch (e) {
      print('Error getting user role: $e');
      rethrow;
    }
  }

  // Add draft content (private)
  Future<void> addDraftContent(Map<String, dynamic> contentData) async {
    if (uid == null) {
      throw Exception('User ID is required to add draft content');
    }

    try {
      contentData['createdAt'] = FieldValue.serverTimestamp();
      contentData['authorId'] = uid;
      contentData['isDraft'] = true;

      await privateContentCollection.add(contentData);
    } catch (e) {
      print('Error adding draft content: $e');
      rethrow;
    }
  }

  // Add public content
  Future<void> addPublicContent(Map<String, dynamic> contentData) async {
    if (uid == null) {
      throw Exception('User ID is required to add public content');
    }

    try {
      contentData['createdAt'] = FieldValue.serverTimestamp();
      contentData['authorId'] = uid;
      contentData['isDraft'] = false;

      await publicContentCollection.add(contentData);
    } catch (e) {
      print('Error adding public content: $e');
      rethrow;
    }
  }

  // Get stream of user's private content
  Stream<QuerySnapshot> getMyContentStream() {
    if (uid == null) {
      return const Stream.empty();
    }

    return privateContentCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get stream of public content
  Stream<QuerySnapshot> getPublicContentStream() {
    return publicContentCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get user's public content
  Stream<QuerySnapshot> getUserPublicContent(String userId) {
    return publicContentCollection
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get book count stream for a user
  Stream<int> getBookCountStream() {
    if (uid == null) {
      return Stream.value(0);
    }

    return publicContentCollection
        .where('authorId', isEqualTo: uid)
        .where('contentType', isEqualTo: 'Book')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Get reader count stream (followers count)
  Stream<int> getReaderCountStream() {
    if (uid == null) {
      return Stream.value(0);
    }

    return userCollection
        .doc(uid)
        .collection('followers')
        .snapshots()
        .map((snapshot) => snapshot.size);
  }

  // Get user rating stream (average rating)
  Stream<double> getUserRatingStream() {
    if (uid == null) {
      return Stream.value(0.0);
    }

    return publicContentCollection
        .where('authorId', isEqualTo: uid)
        .where('contentType', isEqualTo: 'Book')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return 0.0;

          double totalRating = 0;
          int reviewCount = 0;

          for (var doc in snapshot.docs) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data['rating'] != null) {
              totalRating += (data['rating'] as num).toDouble();
              reviewCount++;
            }
          }

          return reviewCount > 0 ? totalRating / reviewCount : 0.0;
        });
  }
}



// import 'package:cloud_firestore/cloud_firestore.dart';

// class DatabaseService {
//   final String? uid;
//   DatabaseService({this.uid});

//   final CollectionReference userCollection = FirebaseFirestore.instance.collection('users');
//   final CollectionReference contentCollection = FirebaseFirestore.instance.collection('content');
//   final CollectionReference booksCollection = FirebaseFirestore.instance.collection('books');

//   Future<void> updateUserData(String name, String email, String role) async {
//     return await userCollection.doc(uid).set({
//       'name': name,
//       'email': email,
//       'role': role,
//     }, SetOptions(merge: true));
//   }

//   Future<Map<String, dynamic>?> getUserData() async {
//     try {
//       DocumentSnapshot doc = await userCollection.doc(uid).get();
//       if (doc.exists) {
//         return doc.data() as Map<String, dynamic>;
//       }
//       return null;
//     } catch (e) {
//       print('Error getting user data: $e');
//       return null;
//     }
//   }

//   Future<String?> getUserRole() async {
//     try {
//       final userData = await getUserData();
//       return userData?['role'];
//     } catch (e) {
//       print('Error getting user role: $e');
//       return null;
//     }
//   }

//   Future<void> addContent(Map<String, dynamic> contentData) async {
//     try {
//       contentData['authorId'] = uid;
//       contentData['createdAt'] = FieldValue.serverTimestamp();
      
//       // Add to the global content collection
//       await contentCollection.add(contentData);
      
//       // Also add to user's content subcollection for easy querying
//       await userCollection.doc(uid).collection('content').add(contentData);
//     } catch (e) {
//       print('Error adding content: $e');
//       rethrow;
//     }
//   }

//   Stream<QuerySnapshot> getContentStream() {
//     return contentCollection
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   // Get all books by this author
//   Stream<QuerySnapshot> getAuthorBooksStream() {
//     return booksCollection
//         .where('authorId', isEqualTo: uid)
//         .orderBy('createdAt', descending: true)
//         .snapshots();
//   }

//   // Get count of books by this author
//   Stream<int> getBookCountStream() {
//     return booksCollection
//         .where('authorId', isEqualTo: uid)
//         .snapshots()
//         .map((snapshot) => snapshot.docs.length);
//   }
// }
