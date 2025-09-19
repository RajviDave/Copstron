// Note: You will need to add the cloud_firestore package to use this.
// We are setting up the structure for now.
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Collection reference
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  Future<void> updateUserData(String name, String email, String role) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
    }, SetOptions(merge: true)); // merge: true prevents overwriting data
  }

  Future<String?> getUserRole() async {
    try {
      DocumentSnapshot doc = await userCollection.doc(uid).get();
      if (doc.exists) {
        // Use `as` to cast the data to a Map, then access the 'role' field.
        final data = doc.data() as Map<String, dynamic>;
        return data['role'];
      }
      return null;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
}
