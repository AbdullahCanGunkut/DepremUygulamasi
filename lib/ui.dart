import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'kernel.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:google_fonts/google_fonts.dart';
import 'package:mutex/mutex.dart';
import 'dart:convert';
final Mutex DataUIMutex = Mutex();

class DepremApp extends StatelessWidget {
  const DepremApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deprem Uygulaması',
      theme: ThemeData(
        primaryTextTheme: Typography(platform: TargetPlatform.android).black,
        textTheme: Typography(platform: TargetPlatform.android).black,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.white),
        useMaterial3: true,
      ),
      home: MainMenuPage(title: "Deprem Uygulaması"),
    );
  }
}

class MainMenuPage extends StatefulWidget {
  //İlk sayfamız.
  const MainMenuPage({super.key, required this.title});

  final String title;

  @override
  State<MainMenuPage> createState() => _MainMenuPageState();
}

class _MainMenuPageState extends State<MainMenuPage>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  TextEditingController _searchController = TextEditingController(text : ""); //Arama işlemi yapmak için text editimize controller atayalımki InpuText'den rahatlıkla istedğimiz verileri çekelim.


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const Key centerKey = ValueKey<String>('bottom-sliver-list');
    return Scaffold(
        floatingActionButton: Theme(
            data: Theme.of(context).copyWith(canvasColor: Colors.cyan),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                SizedBox(height: 16), // Aralık ekleyelim
              ],
            )),
        body: OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
          return Container(
              child: SafeArea(
                  bottom: true,
                  left: true,
                  right: true,
                  child: CustomScrollView(slivers: <Widget>[
                    SliverAppBar(
                        pinned: true,
                        expandedHeight: 80.0,
                        actions: [],
                        flexibleSpace: FlexibleSpaceBar(
                          title: ShaderMask(
                              blendMode: BlendMode.srcATop,
                              // Metin rengini gradient ile birleştirmek için srcATop blend mode'u kullanılır
                              shaderCallback: (Rect bounds) {
                                return LinearGradient(
                                  colors: [
                                    Colors.black87,
                                    Colors.grey
                                  ], // Gradyan renkler
                                ).createShader(bounds);
                              },
                              child: Text('Deprem Uygulaması',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500))),
                          background: Container(
                              height: 256,
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: <Color>[Colors.white, Colors.white10],
                                stops: <double>[0.0, 1.0],
                              ))),
                        )),
                    SliverToBoxAdapter(
                        child: Container(
                            child: Row( mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                      Expanded(flex: 3 ,child :  TextField(onChanged : (text){
                        placeNameSearch = text;
                      } ,controller: _searchController ,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: "Şehir veya yer ismi yazınız...",
                          ),
                        )),
                      ],
                    ))),
                    DepremListWidget()
                  ])));
        }));
  }
}

class DepremListWidget extends StatefulWidget {
  late List<DepremData> depremLst;

  DepremListWidget();

//  @override
  // State<DepremListWidget> createState() => _DepremListWidgetState(depremLst: )

  @override
  State<DepremListWidget> createState() => _DepremListWidgetState();
}

class _DepremListWidgetState extends State<DepremListWidget> {
  late Stream<List<DepremData>> _dataStream;

  @override
  void initState() {
    super.initState();
    _dataStream =
        Stream<List<DepremData>>.periodic(Duration(seconds: 1), (count) {
      GetEarthquakeList().then((value) async {
        await DataUIMutex.acquire();
        widget.depremLst = value;
        DataUIMutex.release();
      });
      return widget.depremLst;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DepremData>>(
        stream: _dataStream,
        builder:
            (BuildContext context, AsyncSnapshot<List<DepremData>> snapshot) {
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
                child: Container(
                    child: Center(child: Text("Veri yükleniyor ..."))));
          } else if (snapshot.hasData) {
            SliverPadding? grid;
            final TextColor = (GlobalSettings?.getBool("IsDarkTheme") ?? false)
                ? Colors.white
                : Colors.black87;
            try {
              List<Container> rows = [
                Container(
                    padding: EdgeInsets.all(0),
                    child: Center(
                        child: Text(
                      "Tarih",
                      style: TextStyle(fontSize: 20, color: TextColor),
                    )),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade200, width: 8.0),
                            right: BorderSide(
                                color: Colors.grey.shade200, width: 2.0)),
                        color: Colors.grey[50])),
                Container(
                    padding: EdgeInsets.all(0),
                    child: Center(
                        child: Text("Yer",
                            style: TextStyle(fontSize: 20, color: TextColor))),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade200, width: 8.0),
                            right: BorderSide(
                                color: Colors.grey.shade200, width: 2.0)),
                        color: Colors.grey[50])),
                Container(
                    padding: EdgeInsets.all(0),
                    child: Center(
                        child: Text("Derinlik",
                            style: TextStyle(fontSize: 20, color: TextColor))),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade200, width: 8.0),
                            right: BorderSide(
                                color: Colors.grey.shade200, width: 2.0)),
                        color: Colors.grey[50])),
                Container(
                    padding: EdgeInsets.all(0),
                    child: Center(
                        child: Text("Büyüklük",
                            style: TextStyle(fontSize: 20, color: TextColor))),
                    decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color: Colors.grey.shade200, width: 8.0)),
                        color: Colors.grey[50]))
              ];

              final c1Color = (GlobalSettings?.getBool("IsDarkTheme") ?? false)
                      ? Colors.grey.shade800
                      : Colors.grey.shade200,
                  c2Color = (GlobalSettings?.getBool("IsDarkTheme") ?? false)
                      ? Colors.grey.shade700
                      : Colors.grey.shade100;
              for (final data in widget.depremLst) {
                rows.addAll([
                  Container(
                      padding: EdgeInsets.all(0),
                      child: Center(child: Text(data.date.toString())),
                      decoration: BoxDecoration(
                        color: c1Color,
                      )),
                  Container(
                      padding: EdgeInsets.all(0),
                      child: Center(child: Text(data.place.toString())),
                      decoration: BoxDecoration(
                        color: c2Color,
                      )),
                  Container(
                      padding: EdgeInsets.all(0),
                      child: Center(child: Text(data.deep.toString())),
                      decoration: BoxDecoration(
                        color: c1Color,
                      )),
                  Container(
                      padding: EdgeInsets.all(0),
                      child: Center(child: Text(data.amplitude.toString())),
                      decoration: BoxDecoration(
                        color: (data.amplitude > 4.0
                            ? Colors.red
                            : (data.amplitude > 3.0 ? Colors.orange : c2Color)),
                      ))
                ]);
              }

              grid = SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return rows[index];
                    }, childCount: rows.length)),
              );
            } catch (e) {
              return SliverToBoxAdapter(
                  child: Container(
                      child: Center(child: Text("Veri yükleniyor ..."))));
            }
            return grid!;
          }
          return SliverToBoxAdapter(
              child:
                  Container(child: Center(child: Text("Veri yükleniyor ..."))));
        });
  }
}

class EarthQuakeMapPainter extends CustomPainter {
  final ui.Image? image_map;
  final BuildContext contxt;

  EarthQuakeMapPainter({this.image_map, required this.contxt}) : super();

  @override
  void paint(Canvas canvas, Size size) {
    //Dinamik olarak işlem yapacağımız yer.
    final double width = MediaQuery.of(this.contxt).size.width,
        height = MediaQuery.of(this.contxt).size.height;

    final paint = Paint();
    final Rect rect = Offset.zero & size;
    const RadialGradient gradient = RadialGradient(
      center: Alignment(0.7, -0.6),
      radius: 0.2,
      colors: <Color>[Color(0xFFFFFF00), Color(0xFF0099FF)],
      stops: <double>[0.4, 1.0],
    );
    /*  canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );*/
    if (this.image_map != null) {
      canvas.scale(size.width / this.image_map!.width);
      canvas.drawImage(this.image_map!, Offset(0, 0), paint);
    }
  }

  // Since this Sky painter has no fields, it always paints
  // the same thing and semantics information is the same.
  // Therefore we return false here. If we had fields (set
  // from the constructor) then we would return true if any
  // of them differed from the same fields on the oldDelegate.
  @override
  bool shouldRepaint(EarthQuakeMapPainter oldDelegate) => false;

  @override
  bool shouldRebuildSemantics(EarthQuakeMapPainter oldDelegate) => false;
}
