// ============================================================
// firebase_service.dart
// Auth (Email + Google) + Firestore (profils + entretiens)
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/candidate_profile.dart';

class FirebaseService {
  static final _auth = FirebaseAuth.instance;
  static final _firestore = FirebaseFirestore.instance;
  static final _google = GoogleSignIn();

  // ─────────────────────────────────────────
  // AUTH — utilisateur courant
  // ─────────────────────────────────────────

  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStream => _auth.authStateChanges();
  static bool get isLoggedIn => _auth.currentUser != null;

  // ─────────────────────────────────────────
  // INSCRIPTION Email/Password
  // ─────────────────────────────────────────

  static Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(name);

    // Créer le document utilisateur dans Firestore
    await _firestore.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return cred;
  }

  // ─────────────────────────────────────────
  // CONNEXION Email/Password
  // ─────────────────────────────────────────

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // ─────────────────────────────────────────
  // CONNEXION GOOGLE
  // ─────────────────────────────────────────

  static Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final cred = await _auth.signInWithCredential(credential);

    // Créer le doc utilisateur si nouveau
    final doc = await _firestore.collection('users').doc(cred.user!.uid).get();

    if (!doc.exists) {
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'name': cred.user!.displayName ?? '',
        'email': cred.user!.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return cred;
  }

  // ─────────────────────────────────────────
  // DÉCONNEXION
  // ─────────────────────────────────────────

  static Future<void> signOut() async {
    await _google.signOut();
    await _auth.signOut();
  }

  // ─────────────────────────────────────────
  // RESET MOT DE PASSE
  // ─────────────────────────────────────────

  static Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE — PROFILS
  // ═══════════════════════════════════════════════════════════

  /// Sauvegarder un profil candidat dans Firestore
  static Future<String> saveProfile(CandidateProfile profile) async {
    final uid = currentUser!.uid;
    final ref = await _firestore
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .add({
          ...profile.toJson(),
          'createdAt': FieldValue.serverTimestamp(),
          'userId': uid,
        });
    return ref.id;
  }

  /// Récupérer tous les profils de l'utilisateur
  static Future<List<Map<String, dynamic>>> getProfiles() async {
    final uid = currentUser!.uid;
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }

  /// Récupérer le dernier profil
  static Future<CandidateProfile?> getLastProfile() async {
    final profiles = await getProfiles();
    if (profiles.isEmpty) return null;
    return CandidateProfile.fromJson(profiles.first);
  }

  /// Supprimer un profil
  static Future<void> deleteProfile(String profileId) async {
    final uid = currentUser!.uid;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('profiles')
        .doc(profileId)
        .delete();
  }

  /// Supprimer tout l'historique de l'utilisateur courant.
  static Future<void> clearUserHistory() async {
    final user = currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    final profiles = await userRef.collection('profiles').get();
    final interviews = await userRef.collection('interviews').get();

    WriteBatch batch = _firestore.batch();
    var operations = 0;

    Future<void> commitIfNeeded() async {
      if (operations == 0) return;
      await batch.commit();
      batch = _firestore.batch();
      operations = 0;
    }

    for (final doc in [...profiles.docs, ...interviews.docs]) {
      batch.delete(doc.reference);
      operations++;
      if (operations >= 450) {
        await commitIfNeeded();
      }
    }

    await commitIfNeeded();
  }

  // ═══════════════════════════════════════════════════════════
  // FIRESTORE — RAPPORTS ENTRETIEN
  // ═══════════════════════════════════════════════════════════

  /// Sauvegarder un rapport d'entretien
  static Future<void> saveInterviewReport({
    required String profileId,
    required Map<String, dynamic> report,
  }) async {
    final uid = currentUser!.uid;
    await _firestore.collection('users').doc(uid).collection('interviews').add({
      ...report,
      'profileId': profileId,
      'createdAt': FieldValue.serverTimestamp(),
      'userId': uid,
    });
  }

  /// Récupérer tous les rapports d'entretien
  static Future<List<Map<String, dynamic>>> getInterviews() async {
    final uid = currentUser!.uid;
    final snap = await _firestore
        .collection('users')
        .doc(uid)
        .collection('interviews')
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => {'id': d.id, ...d.data()}).toList();
  }
}
