import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Profil Mahasiswa')),
        body: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
             Icon(Icons.account_circle, size: 100, color: Colors.blue),
               SizedBox(height: 16),
              Text(
                'Reny Ambarwati',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '244107020066', 
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
              SizedBox(height: 16),
              Text(
                'D4 Teknik Informatika',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
               Text(
                'Politeknik Negeri Malang',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32),
              Text(
                'Pemrograman Mobile — Minggu 1',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ]),
        ),
      ),
    );
  }
}