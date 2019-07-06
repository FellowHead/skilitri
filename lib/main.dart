import 'dart:math';

import 'package:flutter/material.dart';
import 'package:skilitri/tree.dart';
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
        primarySwatch: Colors.teal,
      ),
      home: Skilitri()
    );
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


class Skilitri extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return SkilitriState();
  }
}

class SkilitriState extends State<Skilitri> {
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

  Widget buildNode(Node n) {
    Matrix4 ma = matrix.clone();
    ma.translate(n.position.dx, -n.position.dy);

    return Transform(
        transform: ma,
        child: MatrixGestureDetector(
            shouldRotate: false,
            shouldScale: false,
            onMatrixUpdate: (m, tm, sm, rm) {
              Matrix4 change = tm;
              //print(MatrixGestureDetector.decomposeToValues(matrix));
              double sc = MatrixGestureDetector
                  .decomposeToValues(matrix)
                  .scale;
              //change.multiplyTranspose(matrix);
              n.position += Offset(change
                  .getTranslation()
                  .x / sc, -change
                  .getTranslation()
                  .y / sc);
              notifier.value++;
            },
            child: Center(
              child: n.render(notifier),
            )
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    //return buildSmol();

    if (tree == null) {
      resetTree();
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('skilitri'),
        ),
        body: Column(
            children: [
              Container(
                child: Row(
                  children: <Widget>[
                    MaterialButton(
                      onPressed: () =>
                      {
                        resetTree(),
                        notifier.value++
                      },
                      child: Text('Reset tree'),
                    )
                  ],
                ),
                height: 50,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (ctx, constraints) {
                    return MatrixGestureDetector(
                        onMatrixUpdate: (m, tm, sm, rm) {
                          matrix =
                              MatrixGestureDetector.compose(
                                  matrix, tm, sm, null);
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
                                  return Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            buildCanvas(),
                                            Stack(
                                              children: tree.getDescendants()
                                                  .map((n) =>
                                                  buildNode(n)
                                              ).toList(),
                                            )
                                          ]
                                      )
                                  );
                                }
                            )
                        )
                    );
                  },
                ),
              ),
            ]
        )
    );
  }

  Matrix4 matrix = Matrix4.identity();
  ValueNotifier<int> notifier = ValueNotifier(0);
  vector.Vector3 nodePosition = vector.Vector3(50, 0, 0);

  Widget buildSmol() {
    return Scaffold(
      appBar: AppBar(
        title: Text('Node Diagram Demo'),
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          return MatrixGestureDetector(
            shouldRotate: false,
            onMatrixUpdate: (m, tm, sm, rm) {
              matrix = MatrixGestureDetector.compose(matrix, tm, sm, null);
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
                  return Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: Stack( // a stack in which all nodes are built
                        children: <Widget>[
                          buildCenter(),
                          // build a node...
                          buildNodeOld()
                        ],
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

  Widget buildNodeOld() {
    // create a clone of the main matrix and translate it by the node's position
    Matrix4 ma = matrix.clone();
    ma.translate(nodePosition.x, nodePosition.y);

    return Transform(
        transform: ma,
        child: MatrixGestureDetector(
            shouldRotate: false,
            shouldScale: false,
            onMatrixUpdate: (m, tm, sm, rm) {
              Matrix4 change = tm;
              double sc = MatrixGestureDetector
                  .decomposeToValues(matrix)
                  .scale;
              nodePosition += change.getTranslation() / sc;
              notifier.value++;
            },
            // design a node holding a bool variable ('check')...
            child: Container(
                decoration: BoxDecoration(
                    color: Colors.blue
                ),
                child: Container(
                  width: 200,
                  height: 100,
                  child: Column(
                    children: <Widget>[
                      Text("Node",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.0
                        ),
                      ),
                      Checkbox(
                        onChanged: (v) =>
                        {
                          check = v,
                          notifier.value++ // refresh view
                        },
                        value: check,
                      )
                    ],
                  ),
                )
            )
        )
    );
  }

  Widget buildCenter() {
    return Transform(
        transform: matrix,
        child: Stack(
          children: <Widget>[
            // vertical line
            Center(
                child: Container(
                    width: 1,
                    height: 250,
                    decoration: BoxDecoration(color: Colors.white)
                )
            ),
            // horizontal line
            Center(
                child: Container(
                    width: 250,
                    height: 1,
                    decoration: BoxDecoration(color: Colors.white)
                )
            ),
          ],
        )
    );
  }

  Widget buildCanvas() {
    return Transform(
      transform: matrix,
      child: Center(
        child: CustomPaint(
          painter: ShapesPainter(tree),
        ),
      ),
    );
  }
}