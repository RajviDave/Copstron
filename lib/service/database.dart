import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final String? uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection = FirebaseFirestore.instance
      .collection('users');

  Future<void> updateUserData(String name, String email, String role) async {
    return await userCollection.doc(uid).set({
      'name': name,
      'email': email,
      'role': role,
    });
  }

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
}
