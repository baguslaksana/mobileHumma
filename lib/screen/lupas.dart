import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login.dart';
import 'passwordbaru.dart';
import '../api/connect.dart';

class LupasPage extends StatefulWidget {
  @override
  _LupasPageState createState() => _LupasPageState();
}

class _LupasPageState extends State<LupasPage> {
  final TextEditingController hintController = TextEditingController();
  bool isLoading = false;

  Future<void> checkHint() async {
    final hint = hintController.text.trim();

    if (hint.isEmpty) {
      // showDialogMessage("Hint tidak boleh kosong.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse('$ip/check-hint?hint=$hint'));

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final int userId = data['user_id'];
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordBaruPage(userId: userId),
          ),
        );
      } else {
        // showDialogMessage(data['message'] ?? "Hint tidak ditemukan.");
      }
    } catch (e) {
      // showDialogMessage("Terjadi kesalahan: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Color(0xFF24527A),
      body: Stack(
        children: [
          Positioned(
            top: 70,
            left: 10,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ),

          Positioned(
            top: 130,
            left: 24,
            right: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lupa Password",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  "Masukkan nama bantuan ketika pertama\nkali daftar akun",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: screenHeight * 0.65,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              decoration: BoxDecoration(
                color: Color(0xFFF0FEFF),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Image.asset('assets/img/logo.png', width: 50),
                  SizedBox(height: 24),
                  TextField(
                    controller: hintController,
                    decoration: InputDecoration(
                      hintText: "Bantuan / Hint",
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Color(0xFF24527A)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(
                          color: Color(0xFF24527A),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFDDA853),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: isLoading ? null : checkHint,
                      child:
                          isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                "Lanjutkan",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
