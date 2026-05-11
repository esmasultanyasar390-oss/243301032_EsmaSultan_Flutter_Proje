import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Yeni oluşturduğun dosyayı buraya tanıtıyoruz (Import)

void main() {
  runApp(const ToptanGuzellikApp());
}

class ToptanGuzellikApp extends StatelessWidget {
  const ToptanGuzellikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toptan Güzellik',
      debugShowCheckedModeBanner: false, // Sağ üstteki debug yazısını kaldırır
      theme: ThemeData(
        primarySwatch:
            Colors.purple, // Buton renklerine uygun olması için mor tema
      ),
      // Uygulama açıldığında hangi ekranın geleceğini burada seçiyoruz:
      home: const LoginScreen(),
    );
  }
}
