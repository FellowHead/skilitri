import 'package:flutter/material.dart';
import 'package:skilitri/tree.dart';
import 'package:photo_view/photo_view.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'skilitri',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
      ),
      home: MainView()
    );
  }
}

class MainView extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MainViewState();
}

class MainViewState extends State<MainView> {
  Root tree;
  double scale = 1;
  bool inZoomMode = true;

  PhotoViewController controller;

  PhotoViewControllerValue frozenValue;

  @override
  void initState() {
    super.initState();
    controller = PhotoViewController()
      ..outputStateStream.listen(listener);
  }

  @override
  void dispose() {
    //controller.dispose();
    super.dispose();
  }

  void listener(PhotoViewControllerValue value) {
    setState(() {
      scale = value.scale;
      if (inZoomMode) {
        frozenValue = value;
      } else {
        controller.value = frozenValue;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    //return buildSmol();
    //print("Building | " + DateTime.now().millisecondsSinceEpoch.toString());
    var viewport = buildViewport();
    //print("Built viewport | " + DateTime.now().millisecondsSinceEpoch.toString());
    return Scaffold(
      appBar: AppBar(title: Text("skilitri")),
      body: Column(
        children: <Widget>[
          Expanded(
            child: viewport,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
                color: Colors.teal
            ),
            child: Container(
              height: 50,
              child: Row(
                  children: [
                    Checkbox(
                      value: inZoomMode,
                      onChanged: (v) =>
                      {
                        setState(() =>
                        {
                          inZoomMode = v
                        })
                      },
                    ),
                    MaterialButton(
                      onPressed: () =>
                      {
                        setState(() =>
                        {
                          resetTree()
                        })
                      },
                      child: Text("Reset tree"),
                    ),
                  ]
              ),
            ),
          )
        ],
      ),
    );
  }

  void resetTree() {
    tree = Root(this,
        {
          Node(
              title: "Node",
              position: Offset(0, 0),
              children: {
                ScoreNode(
                    title: "Score Node #1",
                    position: Offset(0, -100),
                    score: 100,
                    children: {
                      ScoreNode(
                          title: "Score Node #2",
                          position: Offset(-300, -200),
                          score: 5
                      ),
                      ScoreNode(
                          title: "Score Node #3",
                          position: Offset(300, -200),
                          score: 63
                      )
                    }
                )
              }
          )
        }
    );
  }

  bool check = false;

  Widget buildSmol() {
    print("Building | " + DateTime.now().millisecondsSinceEpoch.toString());

    Size size = Size(1000, 1000);

    return Scaffold(
      appBar: AppBar(title: Text("skilitri")),
      body: Column(
        children: <Widget>[
          Expanded(
            child: IgnorePointer(
              child: Center(
                child: PhotoView.customChild(
                  child: Stack(
                    children: <Widget>[
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: Colors.black
                          ),
                          child: Container(
                            width: 1,
                            height: size.height,
                          ),
                        ),
                      ),
                      Center(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                              color: Colors.black
                          ),
                          child: Container(
                            width: size.width,
                            height: 1,
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: false,
                        child: Stack(
                            children: [
                              Center(
                                  child: Transform.translate(
                                      offset: Offset(0,0),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: Colors.red
                                        ),
                                        child: Container(
                                          width: 200,
                                          height: 80,
                                          child: Column(
                                            children: <Widget>[
                                              Text("A node",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    //fontSize: 15.0 / scale
                                                    fontSize: 18.0
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  children: <Widget>[
                                                    Listener(
                                                      onPointerUp: (event) => {
                                                        setState(() => {
                                                          check = !check
                                                        })
                                                      },
                                                      child: Checkbox(
                                                        onChanged: (v) => {
                                                          print(DateTime.now().millisecondsSinceEpoch),
//                                                          setState(() => {
//                                                            check = v,
//                                                          })
                                                        },
                                                        value: check,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                  )
                              )
                            ]
                        ),
                      ),
                    ],
                  ),
                  childSize: size,
                  backgroundDecoration: BoxDecoration(color: Colors.white),
                  initialScale: 1.0,
                  controller: controller,
                  transitionOnUserGestures: false,
                ),
              ),
              ignoring: false,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
                color: Colors.teal
            ),
            child: Container(
              height: 50,
              child: Row(
                  children: [
                    Checkbox(
                      value: inZoomMode,
                      onChanged: (v) =>
                      {
                        setState(() =>
                        {
                          inZoomMode = v
                        })
                      },
                    ),
                    MaterialButton(
                      onPressed: () =>
                      {
                        setState(() =>
                        {
                          resetTree()
                        })
                      },
                      child: Text("Reset tree"),
                    ),
                  ]
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildViewport() {
    if (tree == null) {
      resetTree();
    }

    Size size = Size(10000, 10000);
    return Center(
      child: PhotoView.customChild(
        child: Stack(
          children: <Widget>[
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Colors.black
                ),
                child: Container(
                  width: 1,
                  height: size.height,
                ),
              ),
            ),
            Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                    color: Colors.black
                ),
                child: Container(
                  width: size.width,
                  height: 1,
                ),
              ),
            ),
            Center(
              child: CustomPaint(
                painter: ShapesPainter(tree),
              ),
            ),
            Stack(
                children: tree.getDescendants().map((item) =>
                    Center(
                        child: Transform.translate(
                          offset: item.position.scale(1, -1),
                          child: item.render(this)
                        )
                    )
                ).toList()
            ),
          ],
        ),
        childSize: size,
        backgroundDecoration: BoxDecoration(color: inZoomMode ? Colors.grey : Colors.white),
        initialScale: 1.0,
        controller: controller,
        scaleStateCycle: (scale) => getScale(scale),
      ),
    );
  }

  PhotoViewScaleState getScale(PhotoViewScaleState prev) {
    setState(() {
      inZoomMode = !inZoomMode;
    });
    return prev;
  }
}

class ShapesPainter extends CustomPainter {
  Root root;

  ShapesPainter(Root root) {
    this.root = root;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = Colors.black;
    paint.strokeWidth = 5;
    for (Node n in root.getDescendants()) {
      if (n.parent is Node) {
        canvas.drawLine(n.position.scale(1, -1), (n.parent as Node).position.scale(1, -1), paint);
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}