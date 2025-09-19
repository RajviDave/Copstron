// Note: You will need to add the cloud_firestore package to use this.
// We are setting up the structure for now.
import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  // Collection reference
  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  Future<void> updateUserData(String name, String email) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
    }, SetOptions(merge: true)); // merge: true prevents overwriting data
  }
}
