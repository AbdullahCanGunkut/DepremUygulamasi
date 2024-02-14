//Bu kodlar bizim internet üzerinden çekeceğimiz  deprem bilgilerini işler ve flutter dart arayüzü ile iletişim kurar.
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:mutex/mutex.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'dart:ui' as ui;
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


SharedPreferences? GlobalSettings;
late List<DepremData> GlobalDepremList;//depremlerin global olarak çıktığı liste.
final url = Uri.parse('https://deprem.afad.gov.tr/last-earthquakes.html');
String placeNameSearch = "";


class DepremData{ //Deprem bilgimizin tutulacağı Model class'mız.

  final DateTime date; //Tarih
  final String place; //Oluştuğu yer
  final double deep; //Derinlik
  final String type; //Tipi
  final double amplitude;//Deprem şiddeti
  final int plaka;
  final String il;

  DepremData({required this.date ,
    required this.place , required this.deep , required this.type , required this.amplitude ,
    required this.plaka , required this.il});


}


final Map<String, ui.Image> sharedImages = {};


Future<ui.Image> loadImage(String assetPath) async {

  if (sharedImages.containsKey(assetPath))//dosyaya eğer yüklendi ise onu direkt olaraktan alalım ve bu performans açısından oldukça önemlidir , bilgisayar yeniden dosya yükleme yapmaz
      {
   var img = sharedImages[assetPath];
   return img!;
  }
  ByteData data = await rootBundle.load(assetPath); // Dosyayı yükle
  Uint8List bytes = data.buffer.asUint8List(); // Byte dizisine dönüştür

  var img = await decodeImageFromList(bytes);
  sharedImages[assetPath] = img;
  return img; // Byte dizisinden görüntüyü yükle
}

/*
List<DepremData> CheckNewEarthquake(List<DepremData> dprmList , {Duration? durationRange}){
  durationRange ??= Duration(seconds: 1);
 List<DepremData> list = [];
 var now = DateTime.now();
 for (var dprmData in list){
 final dur = now.difference(dprmData.date);
 if (dur <= durationRange){//Eğer oluşan deprem yeni ise kontrol eder (0 ve durationRange aralığında ise)
   list.add(dprmData);
 }

 }
  return list;
}
*/
Future<List<DepremData>> GetEarthquakeList() async{



  List<DepremData> dataList = [];

  // Özel bir başlık eklemek için headers kullanılır.
  Map<String, String> headers = {
    'Accept' : 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Encoding' : 'gzip, deflate, br',
    'Accept-Language' : 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
    'Cache-Control' : 'max-age=0',
    'Connection' : 'keep-alive',
    'Host' : 'deprem.afad.gov.tr',
    'Sec-Fetch-Dest' : 'document',
    'Sec-Fetch-Mode' : 'navigate',
    'Sec-Fetch-Site' : 'cross-site',
    'User-Agent' : 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Mobile Safari/537.36',
    'sec-ch-ua' : "Not A(Brand\";v=\"99\", \"Google Chrome\";v=\"121\", \"Chromium\";v=\"121",
    'sec-ch-ua-mobile' : '?1',
    'sec-ch-ua-platform': "Android",
    'Referrer-Policy' : 'origin'
  };

  // GET isteği oluşturuluyor ve başlık (header) ekliyoruz.
  var response = await http.get(url, headers: headers);

  // Yanıtın durum kodunu kontrol ediyoruz.
  if (response.statusCode == 200) {
    // Başarıyla veri alındıysa, JSON verisini çözümleyebiliriz.
    final decodedString = utf8.decode(response.bodyBytes);
    var jsonData = htmlParser.parse(decodedString);

    var nodes = jsonData.body!.getElementsByTagName("tr");
    nodes.removeAt(0);//ilk satırımızı silelim çünkü işimizi görmeyecek.
    for (var node in nodes) { //verilerimizi internet üzerinden gelen Element dizilimlerine göre sırayla çekelim.

      var placeName =  node.children[6].innerHtml;
      RegExp regex = RegExp(placeNameSearch , caseSensitive: false);

      if (regex.allMatches(placeName).length > 0)
      dataList.add(DepremData(date: DateTime.parse(node.children[0].innerHtml),
          place:  placeName,
          deep: double.parse(node.children[3].innerHtml),
          type: node.children[4].innerHtml,
          amplitude: double.parse(node.children[5].innerHtml),
          plaka: 0 ,
          il: "nodes[6].innerHtml.al"));
    }


  } else {
    print('Hata: ${response.statusCode}');
    return GlobalDepremList;
  }
  GlobalDepremList = dataList;
  return dataList;

}


final KERNEL_UPDATE_TICK_DURATION =  Duration(seconds : 1); //kernel thread'in kaç saniyede bir tepki ile çalışaçağını ayarlabilirsiniz.

 Future<void> kernel_init() async{
 GlobalSettings = await SharedPreferences.getInstance();
}


