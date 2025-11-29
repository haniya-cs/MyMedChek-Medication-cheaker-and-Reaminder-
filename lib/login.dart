 import 'package:flutter/material.dart';
 import 'home.dart';

 class LoginScreen extends StatefulWidget {
   const LoginScreen({super.key});
   @override
   State<LoginScreen> createState() => _LoginScreenState();
 }

 class _LoginScreenState extends State<LoginScreen> {
   final email = TextEditingController();
   final pass = TextEditingController();
   void login() {
     if (email.text.isNotEmpty && pass.text.isNotEmpty) {
       Navigator.pushReplacement(
         context,
           MaterialPageRoute(builder: (_) => const HomeScreen())
      );
     } else {
      ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text("Enter email and password")),
       );
     }
   }

   InputDecoration inputStyle(String label) {
     return InputDecoration(
       labelText: label,
       labelStyle: const TextStyle(color: Colors.blue),
       floatingLabelStyle: const TextStyle(color: Colors.blue),
       hintStyle: const TextStyle(color: Colors.blue),
       contentPadding: const EdgeInsets.symmetric(
         horizontal: 12,
         vertical: 10,
       ),

       enabledBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(8),
         borderSide: const BorderSide(color: Colors.blue, width: 1),
       ),

       focusedBorder: OutlineInputBorder(
         borderRadius: BorderRadius.circular(8),
         borderSide: const BorderSide(color: Colors.blue, width: 1.5),
       ),
     );
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
      backgroundColor: Colors.white,

       body: Center(
         child: SizedBox(
           width: 350,
           child: Padding(
             padding: const EdgeInsets.all(25),
             child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
               crossAxisAlignment: CrossAxisAlignment.stretch,
               children: [
                 const Text(
                   "Login",
                   textAlign: TextAlign.center,
                   style: TextStyle(
                     fontSize: 32,
                     fontWeight: FontWeight.bold,
                    color: Colors.blue,
                   ),
                 ),

                 const SizedBox(height: 40),
                 TextField(
                   controller: email,
                   cursorColor: Colors.blue,
                   decoration: inputStyle("Email"),
                 ),

                 const SizedBox(height: 20),
                 TextField(
                   controller: pass,
                  obscureText: true,
                   cursorColor: Colors.blue,
                   decoration: inputStyle("Password"),
                 ),

                 const SizedBox(height: 30),
                 SizedBox(
                   height: 45,
                   child: ElevatedButton(
                     onPressed: login,
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.blue,
                       foregroundColor: Colors.white,
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                    ),
                    child: const Text(
                     "Login",
                       style: TextStyle(fontSize: 18),
                     ),
                   ),
                 ),
               ],
             ),
           ),
         ),
       ),
     );
   }
 }

