import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skilitri/tree.dart';
import 'package:photo_view/photo_view.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

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
      home: BetterApp()
    );
  }
}

//class MainView extends StatefulWidget {
//  @override
//  State<StatefulWidget> createState() => MainViewState();
//}

//class MainViewState extends State<MainView> {
//  Root tree;
//  double scale = 1;
//  bool inZoomMode = true;
//
//  PhotoViewController controller;
//
//  PhotoViewControllerValue frozenValue = PhotoViewControllerValue(position: Offset(0, 0), scale: 1.0, rotation: 0.0, rotationFocusPoint: null);
//
//  @override
//  void initState() {
//    super.initState();
//    controller = PhotoViewController()
//      ..outputStateStream.listen(listener);
//  }
//
//  @override
//  void dispose() {
//    //controller.dispose();
//    super.dispose();
//  }
//
//  void listener(PhotoViewControllerValue value) {
//    setState(() {
////      if (inZoomMode) {
////        frozenValue = value;
////        scale = value.scale;
////      } else {
////        controller.value = frozenValue;
////      }
//      scale = value.scale;
//    });
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    //return buildSmol();
//    //print("Building | " + DateTime.now().millisecondsSinceEpoch.toString());
//    var viewport = buildSmol();
//    //print("Built viewport | " + DateTime.now().millisecondsSinceEpoch.toString());
//    return Scaffold(
//      appBar: AppBar(title: Text("skilitri")),
//      body: Column(
//        children: <Widget>[
//          Expanded(
//            child: viewport,
//          ),
//          DecoratedBox(
//            decoration: BoxDecoration(
//                color: Colors.teal
//            ),
//            child: Container(
//              height: 50,
//              child: Row(
//                  children: [
//                    Checkbox(
//                      value: inZoomMode,
//                      onChanged: (v) =>
//                      {
//                        setState(() =>
//                        {
//                          inZoomMode = v
//                        })
//                      },
//                    ),
//                    MaterialButton(
//                      onPressed: () =>
//                      {
//                        setState(() =>
//                        {
//                          resetTree()
//                        })
//                      },
//                      child: Text("Reset tree"),
//                    ),
//                    MaterialButton(
//                      onPressed: () =>
//                      {
//                        setState(() =>
//                        {
//                          controller.reset()
//                        })
//                      },
//                      child: Text("Reset view"),
//                    ),
//                    MaterialButton(
//                      onPressed: () =>
//                      {
//                        setState(() =>
//                        {
//                          debugDumpRenderTree()
//                        })
//                      },
//                      child: Text("DUMP"),
//                    ),
//                  ]
//              ),
//            ),
//          )
//        ],
//      ),
//    );
//  }
//
//  void resetTree() {
//    tree = Root(this,
//        {
//          Node(
//              title: "Node",
//              position: Offset(0, 0),
//              children: {
//                ScoreNode(
//                    title: "Score Node #1",
//                    position: Offset(0, -100),
//                    score: 100,
//                    children: {
//                      ScoreNode(
//                          title: "Score Node #2",
//                          position: Offset(-300, -200),
//                          score: 5
//                      ),
//                      ScoreNode(
//                          title: "Score Node #3",
//                          position: Offset(300, -200),
//                          score: 63
//                      )
//                    }
//                )
//              }
//          )
//        }
//    );
//  }
//
//  bool check = false;
//  Offset position = Offset(0, -50);
//  Matrix4 matrix = Matrix4.identity();
//
//  Widget buildSmol() {
//    return Center(
//        widthFactor: 2,
//        child: Container(
//          width: 1000,
//          child: MatrixGestureDetector(
//              onMatrixUpdate: (m, tm, sm, rm) {
//                setState(() {
//                  matrix = m;
//                });
//              },
//              clipChild: false,
//              child: Container(
//                child: Transform(
//                  transform: matrix,
//                  child: Stack(
//                    children: <Widget>[
//                      Container(
//                        width: 10000,
//                        height: 10000,
//                        constraints: BoxConstraints(),
//                        child: DecoratedBox(
//                          decoration: BoxDecoration(color: Colors.yellow),
//                        ),
//                      ),
//                      // vertical line
//                      Center(
//                        child: DecoratedBox(
//                          decoration: BoxDecoration(
//                              color: Colors.black
//                          ),
//                          child: Container(
//                            width: 1,
//                            height: 1000,
//                          ),
//                        ),
//                      ),
//                      // horizontal line
//                      Center(
//                        child: DecoratedBox(
//                          decoration: BoxDecoration(
//                              color: Colors.black
//                          ),
//                          child: Container(
//                            width: 1000,
//                            height: 1,
//                          ),
//                        ),
//                      ),
//                      // box to debug the initial screen size
//                      Center(
//                        child: DecoratedBox(
//                          decoration: BoxDecoration(
//                              color: Colors.black12
//                          ),
//                          child: Container(
//                            width: MediaQuery
//                                .of(context)
//                                .size
//                                .width,
//                            height: MediaQuery
//                                .of(context)
//                                .size
//                                .height,
//                          ),
//                        ),
//                      ),
//                      Stack(
//                          children: <Widget>[
//                            Center(
//                                child: Transform.translate(
//                                    offset: position,
//                                    child: Listener(
//                                      child: DecoratedBox(
//                                        decoration: BoxDecoration(
//                                            color: Colors.red
//                                        ),
//                                        child: Container(
//                                          width: 100,
//                                          height: 100,
//                                          child: Column(
//                                            children: <Widget>[
//                                              Text("Node",
//                                                style: TextStyle(
//                                                    color: Colors.white,
//                                                    fontSize: 18.0
//                                                ),
//                                              )
//                                            ],
//                                          ),
//                                        ),
//                                      ),
//                                      onPointerMove: (event) =>
//                                      {
//                                        setState(() =>
//                                        {
//                                          position +=
//                                              event.delta.scale(
//                                                  1 / scale, 1 / scale)
//                                        })
//                                      },
//                                    )
//                                )
//                            ),
//                          ]
//                      ),
//                    ],
//                  ),
//                ),
//              )
//          ),
//        )
//    );
//  }
//
//  Widget buildViewport() {
//    if (tree == null) {
//      resetTree();
//    }
//
//    Size size = Size(10000, 10000);
//    return Center(
//      child: PhotoView.customChild(
//        child: Stack(
//          children: <Widget>[
//            Center(
//              child: DecoratedBox(
//                decoration: BoxDecoration(
//                    color: Colors.black
//                ),
//                child: Container(
//                  width: 1,
//                  height: size.height,
//                ),
//              ),
//            ),
//            Center(
//              child: DecoratedBox(
//                decoration: BoxDecoration(
//                    color: Colors.black
//                ),
//                child: Container(
//                  width: size.width,
//                  height: 1,
//                ),
//              ),
//            ),
//            Center(
//              child: CustomPaint(
//                painter: ShapesPainter(tree),
//              ),
//            ),
//            Listener(
//              child: Stack(
//                  children: tree.getDescendants().map((item) =>
//                      Listener(
//                        child: Center(
//                            child: Transform.translate(
//                                offset: item.position.scale(1, -1),
//                                child: item.render(this)
//                            )
//                        ),
//                        onPointerDown: (event) => {
//                          print("yeah boi")
//                        },
//                      ),
//                  ).toList(),
//              ),
//              onPointerDown: (e) => {
//                print("stuff is happening in here")
//              },
//              behavior: HitTestBehavior.translucent,
//            ),
//
//          ],
//        ),
//        childSize: size,
//        backgroundDecoration: BoxDecoration(color: inZoomMode ? Colors.grey : Colors.white),
//        initialScale: PhotoViewComputedScale.contained,
//        controller: controller,
//        customSize: size,
//        scaleStateCycle: (scale) => getScale(scale),
//      ),
//    );
//  }
//
//  PhotoViewScaleState getScale(PhotoViewScaleState prev) {
//    setState(() {
//      inZoomMode = !inZoomMode;
//    });
//    return prev;
//  }
//}

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


class BetterApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return BetterAppState();
  }
}

class BetterAppState extends State<BetterApp> {
  Matrix4 matrix = Matrix4.identity();
  Matrix4 matrix2 = Matrix4.identity();
  ValueNotifier<int> notifier = ValueNotifier(0);

  bool check = false;
  Root tree;

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

  @override
  Widget build(BuildContext context) {
    if (tree == null) {
      resetTree();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Better App'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          Size s = constraints.biggest;
          double side = 1000;
          matrix.leftTranslate((s.width - side) / 2, (s.height - side) / 2);
          return MatrixGestureDetector(
            focalPointAlignment: Alignment(0, 0),
            clipChild: false,
            onMatrixUpdate: (m, tm, sm, rm) {
              print(m.getTranslation());
              Matrix4 ma = MatrixGestureDetector.compose(matrix, tm, sm, null);
              print(ma.getTranslation());
              print(matrix.getTranslation());
              if (ma.getTranslation().distanceTo(matrix.getTranslation()) > 1) {
                matrix = MatrixGestureDetector.compose(matrix, tm, sm, null);
                matrix2 = MatrixGestureDetector.compose(matrix, tm, sm, null);
                matrix2.translate(300.0);

                var angle = MatrixGestureDetector
                    .decomposeToValues(m)
                    .rotation;
                notifier.value++;
              }
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.topLeft,
              color: Color(0xff444444),
              child: AnimatedBuilder(
                animation: notifier,
                builder: (ctx, child) {
                  return Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Stack(
                          children: tree.getDescendants().map((n) =>
                              n.render(matrix, notifier)
                          ).toList()
//                    children: <Widget>[
//                      Transform(
//                        transform: matrix,
//                        child: Container(
//                            width: side,
//                            height: side,
//                            decoration: BoxDecoration(
//                              color: Colors.red,
//                              border: Border.all(
//                                color: Colors.white30,
//                                width: 20,
//                              ),
//                              borderRadius: BorderRadius.all(
//                                  Radius.circular(10)),
//                            ),
//                            child: Center(
//                              child: Column(children: [Text(
//                                'Node #1',
//                                textAlign: TextAlign.center,
//                                style: Theme
//                                    .of(ctx)
//                                    .textTheme
//                                    .display1
//                                    .apply(
//                                  color: Colors.white,
//                                ),
//                              ),
//                                Checkbox(
//                                  onChanged: (v) =>
//                                  {
//                                    check = v,
//                                    notifier.value++
//                                  },
//                                  value: check,
//                                )
//                              ]
//                              ),
//                            )
//                        ),
//                      ),
//                      Transform(
//                        transform: matrix2,
//                        child: Container(
//                            width: side,
//                            height: side,
//                            decoration: BoxDecoration(
//                              color: Colors.blue,
//                              border: Border.all(
//                                color: Colors.white30,
//                                width: 20,
//                              ),
//                              borderRadius: BorderRadius.all(
//                                  Radius.circular(10)),
//                            ),
//                            child: Center(
//                              child: Column(
//                                  children: [
//                                    Text(
//                                      'Node #2',
//                                      textAlign: TextAlign.center,
//                                      style: Theme
//                                          .of(ctx)
//                                          .textTheme
//                                          .display1
//                                          .apply(
//                                        color: Colors.white,
//                                      ),
//                                    ),
//                                    Checkbox(
//                                      onChanged: (v) =>
//                                      {
//                                        check = v,
//                                        notifier.value++
//                                      },
//                                      value: check,
//                                    )
//                                  ]
//                              ),
//                            )
//                        ),
//                      )
//                    ],
                      )
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}





class TransformDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text('Transform Demo'),
      ),
      body: MatrixGestureDetector(
        onMatrixUpdate: (m, tm, sm, rm) {
          notifier.value = m;
        },
        child: AnimatedBuilder(
          animation: notifier,
          builder: (ctx, child) {
            return Transform(
              transform: notifier.value,
              child: Stack(
                children: <Widget>[
                  Container(
                    color: Colors.white30,
                  ),
                  Positioned.fill(
                    child: Container(
                      transform: notifier.value,
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: Icon(
                          Icons.favorite,
                          color: Colors.deepPurple.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    decoration: FlutterLogoDecoration(),
                    padding: EdgeInsets.all(32),
                    alignment: Alignment(0, -0.5),
                    child: Text(
                      'use your two fingers to translate / rotate / scale ...',
                      style: Theme.of(context).textTheme.display2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class TransformDemo2 extends StatefulWidget {
  @override
  _TransformDemo2State createState() => _TransformDemo2State();
}

class _TransformDemo2State extends State<TransformDemo2> {
  Matrix4 matrix;
  ValueNotifier<Matrix4> notifier;
  Boxer boxer;

  @override
  void initState() {
    super.initState();
    matrix = Matrix4.identity();
    notifier = ValueNotifier(matrix);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TransformDemo Demo 2'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          var width = constraints.biggest.width / 1.5;
          var height = constraints.biggest.height / 2.0;
          var dx = (constraints.biggest.width - width) / 2;
          var dy = (constraints.biggest.height - height) / 2;
          matrix.leftTranslate(dx, dy);
          boxer = Boxer(Offset.zero & constraints.biggest,
              Rect.fromLTWH(0, 0, width, height));
          return MatrixGestureDetector(
            shouldRotate: true,
            onMatrixUpdate: (m, tm, sm, rm) {
              matrix = MatrixGestureDetector.compose(matrix, tm, sm, null);
              boxer.clamp(matrix);
              notifier.value = matrix;
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.topLeft,
              color: Colors.deepPurple,
              child: AnimatedBuilder(
                builder: (ctx, child) {
                  return Transform(
                    transform: matrix,
                    child: Container(
                      width: width,
                      height: height,
                      decoration: BoxDecoration(
                          color: Colors.white30,
                          border: Border.all(
                            color: Colors.black45,
                            width: 20,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(40))),
                      child: Center(
                        child: Text(
                          'you can move & scale me',
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.display1,
                        ),
                      ),
                    ),
                  );
                },
                animation: notifier,
              ),
            ),
          );
        },
      ),
    );
  }
}

class Boxer {
  final Rect bounds;
  final Rect src;
  Rect dst;

  Boxer(this.bounds, this.src);

  void clamp(Matrix4 m) {
    dst = MatrixUtils.transformRect(m, src);
    if (bounds.left <= dst.left &&
        bounds.top <= dst.top &&
        bounds.right >= dst.right &&
        bounds.bottom >= dst.bottom) {
      // bounds contains dst
      return;
    }

    if (dst.width > bounds.width || dst.height > bounds.height) {
      Rect intersected = dst.intersect(bounds);
      FittedSizes fs = applyBoxFit(BoxFit.contain, dst.size, intersected.size);

      vector.Vector3 t = vector.Vector3.zero();
      intersected = Alignment.center.inscribe(fs.destination, intersected);
      if (dst.width > bounds.width)
        t.y = intersected.top;
      else
        t.x = intersected.left;

      var scale = fs.destination.width / src.width;
      vector.Vector3 s = vector.Vector3(scale, scale, 0);
      m.setFromTranslationRotationScale(t, vector.Quaternion.identity(), s);
      return;
    }

    if (dst.left < bounds.left) {
      m.leftTranslate(bounds.left - dst.left, 0.0);
    }
    if (dst.top < bounds.top) {
      m.leftTranslate(0.0, bounds.top - dst.top);
    }
    if (dst.right > bounds.right) {
      m.leftTranslate(bounds.right - dst.right, 0.0);
    }
    if (dst.bottom > bounds.bottom) {
      m.leftTranslate(0.0, bounds.bottom - dst.bottom);
    }
  }
}

class TransformDemo3 extends StatefulWidget {
  @override
  _TransformDemo3State createState() => _TransformDemo3State();
}

class _TransformDemo3State extends State<TransformDemo3> {
  static const Color color0 = Color(0xff00aa00);
  static const Color color1 = Color(0xffeeaa00);
  static const Color color2 = Color(0xffaa0000);
  static const double radius0 = 0.0;

  Matrix4 matrix = Matrix4.identity();
  double radius = radius0;
  Color color = color0;
  ValueNotifier<int> notifier = ValueNotifier(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TransformDemo Demo 3'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          Size s = constraints.biggest;
          double side = s.shortestSide * 0.666;
          matrix.leftTranslate((s.width - side) / 2, (s.height - side) / 2);
          TweenSequence colorTween = TweenSequence([
            TweenSequenceItem(
                tween: ColorTween(begin: color0, end: color1), weight: 1),
            TweenSequenceItem(
                tween: ColorTween(begin: color1, end: color2), weight: 1),
          ]);
          Tween radiusTween = Tween<double>(begin: radius0, end: side / 2);
          return MatrixGestureDetector(
            onMatrixUpdate: (m, tm, sm, rm) {
              matrix = MatrixGestureDetector.compose(matrix, tm, sm, null);

              var angle = MatrixGestureDetector.decomposeToValues(m).rotation;
              double t = (1 - cos(2 * angle)) / 2;

              radius = radiusTween.transform(t);
              color = colorTween.transform(t);
              notifier.value++;
            },
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.topLeft,
              color: Color(0xff444444),
              child: AnimatedBuilder(
                animation: notifier,
                builder: (ctx, child) {
                  return Transform(
                    transform: matrix,
                    child: Container(
                      width: side,
                      height: side,
                      decoration: BoxDecoration(
                        color: color,
                        border: Border.all(
                          color: Colors.white30,
                          width: 20,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(radius)),
                      ),
                      child: Center(
                        child: Text(
                          'you can move & scale me (and "rotate" too)',
                          textAlign: TextAlign.center,
                          style: Theme.of(ctx).textTheme.display1.apply(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class TransformDemo4 extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => TransformDemo4State();
}

class TransformDemo4State extends State<TransformDemo4>
    with TickerProviderStateMixin {
  ValueNotifier<Matrix4> notifier = ValueNotifier(Matrix4.identity());
  bool shouldScale = true;
  bool shouldRotate = true;
  AnimationController controller;

  Alignment focalPoint = Alignment.center;

  Animation<Alignment> focalPointAnimation;
  List items = [
    Alignment.topLeft,
    Alignment.topCenter,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.center,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomCenter,
    Alignment.bottomRight,
  ]
      .map(
        (alignment) => DropdownMenuItem<Alignment>(
      value: alignment,
      child: Text(
        alignment.toString(),
      ),
    ),
  )
      .toList();

  @override
  void initState() {
    super.initState();
    controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    focalPointAnimation = makeFocalPointAnimation(focalPoint, focalPoint);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      appBar: AppBar(
        title: Text('Transform Demo 4'),
      ),
      body: Column(
        children: makeControls() + makeMainWidget(getBody()),
      ),
    );
  }

  Body getBody() {
    String lbl = 'use your fingers to ';
    if (shouldRotate && shouldScale)
      return Body(lbl + 'rotate / scale', Icons.crop_rotate, Color(0x6600aa00));
    if (shouldRotate)
      return Body(lbl + 'rotate', Icons.crop_rotate, Color(0x6600aa00));
    if (shouldScale)
      return Body(lbl + 'scale', Icons.transform, Color(0x660000aa));
    return Body('you have to select at least one checkbox above', Icons.warning,
        Color(0x66aa0000));
  }

  Animation<Alignment> makeFocalPointAnimation(Alignment begin, Alignment end) {
    return controller.drive(AlignmentTween(begin: begin, end: end));
  }

  List<Widget> makeControls() => [
    ListTile(
      title: Text('focal point'),
      trailing: DropdownButton(
        onChanged: (value) {
          setState(() {
            focalPointAnimation =
                makeFocalPointAnimation(focalPointAnimation.value, value);
            focalPoint = value;
            controller.forward(from: 0.0);
          });
        },
        value: focalPoint,
        items: items,
      ),
    ),
    CheckboxListTile(
      value: shouldScale,
      onChanged: (bool value) {
        setState(() {
          shouldScale = value;
        });
      },
      title: Text('scale'),
    ),
    CheckboxListTile(
      value: shouldRotate,
      onChanged: (bool value) {
        setState(() {
          shouldRotate = value;
        });
      },
      title: Text('rotate'),
    ),
  ];

  List<Widget> makeMainWidget(Body body) => [
    Expanded(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: MatrixGestureDetector(
          onMatrixUpdate: (m, tm, sm, rm) {
            notifier.value = m;
          },
          shouldTranslate: false,
          shouldScale: shouldScale,
          shouldRotate: shouldRotate,
          focalPointAlignment: focalPoint,
          clipChild: false,
          child: CustomPaint(
            foregroundPainter: FocalPointPainter(focalPointAnimation),
            child: AnimatedBuilder(
              animation: notifier,
              builder: (ctx, child) => makeTransform(ctx, child, body),
            ),
          ),
        ),
      ),
    )
  ];

  Widget makeTransform(BuildContext context, Widget child, Body body) {
    return Transform(
      transform: notifier.value,
      child: GridPaper(
        color: Color(0xaa0000ff),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: 4.0, color: Color(0xaa00cc00)),
            borderRadius: BorderRadius.all(Radius.circular(32.0)),
          ),
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 400),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
              alignment: focalPoint,
            ),
            switchInCurve: Curves.ease,
            switchOutCurve: Curves.ease,
            child: Stack(
              key: ValueKey('$shouldRotate-$shouldScale'),
              fit: StackFit.expand,
              children: <Widget>[
                FittedBox(
                  child: Icon(
                    body.icon,
                    color: body.color,
                  ),
                ),
                Container(
                  alignment: Alignment(0, -0.5),
                  child: Text(
                    body.label,
                    style: Theme.of(context).textTheme.display2,
                    textAlign: TextAlign.center,
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

class Body {
  String label;
  IconData icon;
  Color color;

  Body(this.label, this.icon, this.color);
}

class FocalPointPainter extends CustomPainter {
  Animation<Alignment> focalPointAnimation;
  Path cross;
  Paint foregroundPaint;

  FocalPointPainter(this.focalPointAnimation)
      : super(repaint: focalPointAnimation) {
    foregroundPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6
      ..color = Colors.white70;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cross == null) {
      initCross(size);
    }

    Offset translation = focalPointAnimation.value.alongSize(size);
    canvas.translate(translation.dx, translation.dy);
    canvas.drawPath(cross, foregroundPaint);
  }

  @override
  bool hitTest(Offset position) => true;

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  void initCross(Size size) {
    var s = size.shortestSide / 8;
    cross = Path()
      ..moveTo(-s, 0)
      ..relativeLineTo(s * 0.75, 0)
      ..moveTo(s, 0)
      ..relativeLineTo(-s * 0.75, 0)
      ..moveTo(0, s)
      ..relativeLineTo(0, -s * 0.75)
      ..addOval(Rect.fromCircle(center: Offset.zero, radius: s * 0.85));
  }
}