import 'dart:convert'; // JSON işlemleri için
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Hafıza için

void main() {
  runApp(const AntkaraApp());
}

class AntkaraApp extends StatelessWidget {
  const AntkaraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Antkara Sipariş',
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: const SiparisEkrani(),
    );
  }
}

// Ürün Modeli
class Urun {
  String kategori;
  String isim;
  int adet;

  Urun(this.kategori, this.isim, {this.adet = 0});

  // Ürünü JSON formatına çevirme (Kaydetmek için)
  Map<String, dynamic> toJson() => {
        'isim': isim,
        'adet': adet,
      };
}

class SiparisEkrani extends StatefulWidget {
  const SiparisEkrani({super.key});

  @override
  State<SiparisEkrani> createState() => _SiparisEkraniState();
}

class _SiparisEkraniState extends State<SiparisEkrani> {
  // LİSTE
  List<Urun> tumUrunler = [
    // Poğaça Grubu
    Urun("Poğaça Grubu", "Kaşarlı"),
    Urun("Poğaça Grubu", "Peynirli"),
    Urun("Poğaça Grubu", "Patatesli"),
    Urun("Poğaça Grubu", "Sade"),
    Urun("Poğaça Grubu", "Zeytinli"),
    Urun("Poğaça Grubu", "Dereotlu"),

    // Açma Grubu
    Urun("Açma Grubu", "Zeytinli"),
    Urun("Açma Grubu", "Peynirli"),
    Urun("Açma Grubu", "Patatesli"),
    Urun("Açma Grubu", "Kaşarlı"),
    Urun("Açma Grubu", "Haşhaşlı"),
    Urun("Açma Grubu", "Çikolatalı"),
    Urun("Açma Grubu", "Sade"),

    // Börekler
    Urun("Börekler", "3 Kıymalı - 1 Peynirli"),
    Urun("Börekler", "2 Kıymalı - 2 Peynirli"),
    Urun("Börekler", "Tam Kıymalı"),
    Urun("Börekler", "Tam Peynirli"),

    // Diğerleri
    Urun("Diğerleri", "Tahinli"),
    Urun("Diğerleri", "Pizza"),
    Urun("Diğerleri", "Sütlü Simit"),
    Urun("Diğerleri", "Tereyağlı Simit"),
    Urun("Diğerleri", "Ev Poğaçası"),
    Urun("Diğerleri", "Kek"),
    Urun("Diğerleri", "Boyoz"),
    Urun("Diğerleri", "Sandviç"),
  ];

  @override
  void initState() {
    super.initState();
    _verileriYukle(); // Uygulama açılınca verileri getir
  }

  // --- HAFIZA İŞLEMLERİ ---

  // 1. Verileri Kaydetme
  Future<void> _verileriKaydet() async {
    final prefs = await SharedPreferences.getInstance();
    // Sadece adeti 0'dan büyük olanları kaydedelim ki yer kaplamasın
    List<Map<String, dynamic>> kaydedilecekListe = [];
    for (var urun in tumUrunler) {
      if (urun.adet > 0) {
        kaydedilecekListe.add(urun.toJson());
      }
    }
    // Listeyi yazıya (JSON) çevirip sakla
    String jsonString = jsonEncode(kaydedilecekListe);
    await prefs.setString('kayitli_siparisler', jsonString);
  }

  // 2. Verileri Yükleme
  Future<void> _verileriYukle() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonString = prefs.getString('kayitli_siparisler');

    if (jsonString != null) {
      List<dynamic> yuklenenListe = jsonDecode(jsonString);
      
      setState(() {
        // Kayıtlı verileri mevcut listeyle eşleştir
        for (var kayit in yuklenenListe) {
          // İsimden ürünü bul
          var bulunanUrun = tumUrunler.firstWhere(
            (urun) => urun.isim == kayit['isim'], 
            orElse: () => Urun("", "") // Bulunamazsa boş dön
          );
          
          if (bulunanUrun.isim.isNotEmpty) {
            bulunanUrun.adet = kayit['adet'];
          }
        }
      });
    }
  }

  // 3. Verileri Sıfırlama
  Future<void> listeyiTemizle() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kayitli_siparisler'); // Hafızadan sil

    setState(() {
      for (var urun in tumUrunler) {
        urun.adet = 0;
      }
    });
    
    // Ekranı yenile
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (BuildContext context) => super.widget));
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Urun>> kategoriliListe = {};
    for (var urun in tumUrunler) {
      if (!kategoriliListe.containsKey(urun.kategori)) {
        kategoriliListe[urun.kategori] = [];
      }
      kategoriliListe[urun.kategori]!.add(urun);
    }

    return Scaffold(
      appBar: AppBar(
        // --- DEĞİŞİKLİK 1: AppBar'a Logo Eklendi ---
        title: Row(
          children: [
            Image.asset('assets/logo.png', height: 40), // Logo
            const SizedBox(width: 10), // Boşluk
            const Text('Antkara Sipariş'),
          ],
        ),
        // ------------------------------------------
        backgroundColor: Colors.red.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: listeyiTemizle,
            tooltip: "Sıfırla",
          )
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 80),
          children: kategoriliListe.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  color: Colors.red.shade50,
                  width: double.infinity,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900),
                  ),
                ),
                ...entry.value.map((urun) {
                  return UrunKarti(
                    urun: urun,
                    veriDegisti: _verileriKaydet, // Her değişiklikte kaydet
                  );
                }),
              ],
            );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OzetEkrani(tumUrunler: tumUrunler),
            ),
          );
        },
        label: const Text("Fişi Oluştur"),
        icon: const Icon(Icons.receipt_long),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// *** ÜRÜN KARTI WIDGET'I ***
class UrunKarti extends StatefulWidget {
  final Urun urun;
  final VoidCallback veriDegisti; // Ana sayfaya haber vermek için

  const UrunKarti({super.key, required this.urun, required this.veriDegisti});

  @override
  State<UrunKarti> createState() => _UrunKartiState();
}

class _UrunKartiState extends State<UrunKarti> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.urun.adet.toString());
  }
  
  // Eğer dışarıdan güncelleme gelirse (örn: sıfırlama) controller'ı güncelle
  @override
  void didUpdateWidget(UrunKarti oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.urun.adet != int.tryParse(_controller.text)) {
       _controller.text = widget.urun.adet.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void arttir() {
    setState(() {
      widget.urun.adet++;
      _controller.text = widget.urun.adet.toString();
    });
    widget.veriDegisti(); // Kaydet
  }

  void azalt() {
    setState(() {
      if (widget.urun.adet > 0) {
        widget.urun.adet--;
        _controller.text = widget.urun.adet.toString();
      }
    });
    widget.veriDegisti(); // Kaydet
  }

  void elleGirildi(String deger) {
    if (deger.isEmpty) {
      widget.urun.adet = 0;
    } else {
      widget.urun.adet = int.tryParse(deger) ?? 0;
    }
    widget.veriDegisti(); // Kaydet
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(widget.urun.isim, style: const TextStyle(fontSize: 16)),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                  onPressed: azalt,
                ),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 5),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    onChanged: elleGirildi,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: arttir,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// FİŞ VE PAYLAŞIM EKRANI
class OzetEkrani extends StatelessWidget {
  final List<Urun> tumUrunler;
  final GlobalKey _globalKey = GlobalKey();

  OzetEkrani({super.key, required this.tumUrunler});

  Future<void> ekranGoruntusuPaylas(BuildContext context) async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getTemporaryDirectory();
      final imagePath =
          await File('${directory.path}/antkara_siparis.png').create();
      await imagePath.writeAsBytes(pngBytes);

      // ignore: deprecated_member_use
      await Share.shareXFiles([XFile(imagePath.path)],
          text: 'Antkara Sipariş Listesi');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tarih = DateTime.now();
    final tarihFormat = "${tarih.day}.${tarih.month}.${tarih.year}";

    Map<String, List<Urun>> fisGruplari = {};
    bool enAzBirUrunVar = false;

    for (var urun in tumUrunler) {
      if (urun.adet > 0) {
        enAzBirUrunVar = true;
        if (!fisGruplari.containsKey(urun.kategori)) {
          fisGruplari[urun.kategori] = [];
        }
        fisGruplari[urun.kategori]!.add(urun);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade200,
      appBar: AppBar(
        title: const Text("Sipariş Özeti"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RepaintBoundary(
                key: _globalKey,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // --- DEĞİŞİKLİK 2: Fişe Logo Eklendi ---
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 80, // Fişte logo daha büyük
                        ),
                      ),
                      // -------------------------------------

                      const Text(
                        "ANTKARA SİPARİŞ",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const Divider(thickness: 2),
                      Text("Tarih: $tarihFormat",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 10),
                      
                      if (!enAzBirUrunVar)
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text("Listede ürün yok."),
                        )
                      else
                        ...fisGruplari.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 15),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(bottom: 5),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5))
                                ),
                                child: Text(
                                  entry.key.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade800,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              ...entry.value.map((urun) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 3.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          urun.isim,
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          "${urun.adet}",
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ))
                            ],
                          );
                        }),

                      const SizedBox(height: 30),
                      const Divider(),
                      const Text("Kolay Gelsin :)",
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ekranGoruntusuPaylas(context),
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text("WhatsApp'ta Paylaş",
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}