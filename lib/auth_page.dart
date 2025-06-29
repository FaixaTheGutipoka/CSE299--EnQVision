import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showLogin = true;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _auth = FirebaseAuth.instance;

  /* ---------- GOOGLE ---------- */
  Future<void> _handleGoogle() async {
    try {
      UserCredential cred;

      if (kIsWeb) {
        // ✅ Web uses the Firebase popup which opens the normal account picker.
        cred = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        // ✅ Mobile uses the google_sign_in plugin.
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return; // cancelled
        final googleAuth = await googleUser.authentication;

        final googleCred = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        cred = await _auth.signInWithCredential(googleCred);
      }

      if (!mounted) return;
      _goHome(cred.user);
    } catch (e) {
      _snack(e.toString());
    }
  }

  /* ---------- EMAIL / PASSWORD ---------- */
  Future<void> _submit() async {
    try {
      UserCredential cred;
      if (showLogin) {
        cred = await _auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      } else {
        cred = await _auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        await cred.user!.updateDisplayName(_name.text.trim());
        await cred.user!.sendEmailVerification();
        _snack('Verification link sent to your e-mail.');
      }

      if (!mounted) return;
      _goHome(cred.user);
    } on FirebaseAuthException catch (e) {
      _snack(e.message ?? e.code);
    } catch (e) {
      _snack(e.toString());
    }
  }

  /* ---------- HELPERS ---------- */
  void _goHome(User? user) {
    if (user == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => HomePage(user: user)),
    );
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  /* ---------- UI ---------- */
  Widget _form() => Column(
    children: [
      if (!showLogin)
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
      TextField(
        controller: _email,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      TextField(
        controller: _password,
        obscureText: true,
        decoration: const InputDecoration(labelText: 'Password'),
      ),
      const SizedBox(height: 20),
      ElevatedButton(
        onPressed: _submit,
        child: Text(showLogin ? 'Login' : 'Create Account'),
      ),
      // ⬇⬇  NEW inline link to switch modes  ⬇⬇
      TextButton(
        onPressed: () => setState(() => showLogin = !showLogin),
        child: Text(
          showLogin
              ? "Don't have an account? Sign Up"
              : "Already registered? Back to Login",
        ),
      ),
      const Divider(height: 40),
      ElevatedButton.icon(
        onPressed: _handleGoogle,
        icon: const Icon(Icons.login),
        label: const Text('Continue with Google'),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EnQVision')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: SingleChildScrollView(child: _form())),
      ),
    );
  }
}
