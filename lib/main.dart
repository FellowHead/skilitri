import 'dart:io';
import 'dart:math';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:skilitri/tree.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';


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
        primaryColor: Color(0xff90ffa0),
        primaryColorDark: Color(0xffd0e0e0),
        backgroundColor: Color(0xffa0a0a0),
        buttonColor: Color(0xff6070c0)
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
        Offset start = n.position.scale(1, -1);
        Offset end = (n.parent as Node).position.scale(1, -1);
        canvas.drawLine(start, end, paint);
        canvas.drawCircle(Offset.lerp(start, end, 0.7), 25, paint);
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
  bool inSelectionMode = false;
  Set<Node> selection = {};
  Node active;
  Node dragged;

  void resetTree() {
    tree = Root(
        {
          Node(
              title: "Node",
              position: Offset(0, 0),
              body: DemoBody(),
              children: {
                Node(
                    title: "Score Node #1",
                    position: Offset(0, -100),
                    body: ScoreBody(score: 100),
                    children: {
                      Node(
                        title: "Score Node #2",
                        position: Offset(-300, -200),
                        body: ScoreBody(score: 5),
                      ),
                      Node(
                        title: "Score Node #3",
                        position: Offset(300, -200),
                        body: ScoreBody(score: 63),
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
        child: GestureDetector(
            onTapUp: (details) =>
            {
              //print("onTapUp on " + n.toString()),
              if (inSelectionMode) {
                if (selection.contains(n)) {
                  if (selection.length == 1) {
                    exitSelectionMode()
                  } else
                    {
                      selection.remove(n),
                      if (active == n) {
                        active = null
                      }
                    }
                } else
                  {
                    select(n, false)
                  },
                notifier.value++
              } else {

              }
            },
            onPanDown: (yeah) => {
              n.isDragged = true,
              dragged = n
            },
            dragStartBehavior: DragStartBehavior.down,
            onLongPressStart: (details) =>
            {
              Feedback.forLongPress(context),
              select(n, true)
            },
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
                  child: n.render(Theme.of(context), notifier, getSelectionType(n)),
                )
            )
        )
    );
  }

  SelectionType getSelectionType(Node n) {
    if (active == n) {
      return SelectionType.Focused;
    } else if (selection.contains(n)) {
      return SelectionType.Selected;
    } else {
      return SelectionType.None;
    }
  }

  Offset screenToView(BuildContext ctx, Offset sc) {
    Matrix4 m = matrix.clone();
    var zoom = MatrixGestureDetector.decomposeToValues(m).scale;
    m.translate(-sc.dx / zoom, (150 - sc.dy) / zoom, 0);
    return Offset(-m.getTranslation().x / zoom - 180, m.getTranslation().y / zoom + 220);
  }

  void select(Node n, bool deselectOthers) {
    setState(() =>
    {
      if (deselectOthers) {
        selection = {}
      },
      selection.add(n),
      inSelectionMode = true,
      active = n
    });
  }

  void createEmptyNode(Offset position) {
    Node n = Node(
        title: "NEW NODE",
        position: position,
        body: DemoBody()
    );
    tree.addChild(n);
    select(n, true);
    //notifier.value++;
  }

  // I/O STUFF

  _read() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/tree.fwd');
      String text = await file.readAsString();
      print(text);
      setState(() => {
        tree = Root.fromJson(jsonDecode(text))
      });
    } on FileSystemException catch(e) {
      print("Can't read file");
    }
  }

  _save() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/tree.fwd');
    final text = jsonEncode(tree.toJson());
    await file.writeAsString(text);
    print('saved');

    Fluttertoast.showToast(
      msg: "Skilltree gespeichert!",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Color(0x60000000),
      timeInSecForIos: 1,
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
                        exitSelectionMode(),
                      },
                      child: Text('Reset tree'),
                    ),
                    IconButton(
                      onPressed: () =>
                      {
                        _save()
                      },
                      icon: Icon(
                          Icons.save
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                      {
                        _read()
                      },
                      icon: Icon(
                          Icons.restore_page
                      ),
                    ),
                  ],
                ),
                height: 50,
              ),
              Expanded(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerUp: (lol) => {
                    onDragStop()
                  },
                  child: LayoutBuilder(
                    builder: (ctx, constraints) {
                      return MatrixGestureDetector(
                          onMatrixUpdate: (m, tm, sm, rm) {
                            matrix =
                                MatrixGestureDetector.compose(
                                    matrix, tm, sm, null);
                            notifier.value++;
                          },
                          child: GestureDetector(
                            onLongPressStart: (details) =>
                            {
                              Feedback.forLongPress(context),
                              if (inSelectionMode) {
                                exitSelectionMode()
                              } else
                                {
                                  createEmptyNode(
                                      screenToView(
                                          context, details.globalPosition))
                                }
                            },
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.topLeft,
                                color: Theme
                                    .of(context)
                                    .backgroundColor,
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
                                                  children: tree
                                                      .getDescendants()
                                                      .map((n) =>
                                                      buildNode(n)
                                                  ).toList(),
                                                )
                                              ]
                                          )
                                      );
                                    }
                                )
                            ),
                          )
                      );
                    },
                  ),
                ),
              ),
              // SELECTION MODE BAR
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.decelerate,
                decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                          blurRadius: 10
                      )
                    ]
                ),
                child: Row(
                  children: <Widget>[
                    MaterialButton(
                      onPressed: () =>
                      {
                        setState(() =>
                        {
                          exitSelectionMode()
                        })
                      },
                      child: Text('Exit'),
                    ),
                    IconButton(
                      onPressed: () =>
                      {
                        setState(() =>
                        {
                          for (Node n in selection) {
                            n.remove(true)
                          },
                          exitSelectionMode()
                        })
                      },
                      icon: Icon(
                          Icons.delete
                      ),
                    ),
                    IconButton(
                      onPressed: selection.length != 1 ? () =>
                      {
                        setState(() =>
                        {
                          if (active != null) {
                            for (Node n in selection) {
                              if (n != active) {
                                if (!active.getAscendants().contains(n)) {
                                  active.addChild(n),
                                } else
                                  {
                                    print('puh knappe nummer')
                                  }
                              }
                            },
                          },
                        })
                      } : null,
                      icon: Icon(
                          Icons.link
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                      {
                        setState(() =>
                        {
                          for (Node n in selection) {
                            n.setParent(tree)
                          },
                        })
                      },
                      icon: Icon(
                          Icons.link_off
                      ),
                    ),
                    IconButton(
                      onPressed: selection.length == 1 ? () =>
                      {
                        setState(() =>
                        {
                          _showDialog(selection.first)
                        })
                      } : null,
                      icon: Icon(
                          Icons.edit
                      ),
                    ),
                  ],
                ),
                height: inSelectionMode ? 50 : 0,
              ),
            ]
        )
    );
  }

  void onDragStop() {
    if (dragged != null) {
      dragged.isDragged = false;
      notifier.value++;
    }
  }

  void _showToast(BuildContext context) {
    final scaffold = Scaffold.of(context);
    scaffold.showSnackBar(
      SnackBar(
        content: const Text('Added to favorite'),
        action: SnackBarAction(
            label: 'UNDO', onPressed: scaffold.hideCurrentSnackBar),
      ),
    );
  }

  void _showActualToast() {
  }

  void _showDialog(Node n) {
    final TextEditingController controller = TextEditingController(text: n.title);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: new Text("Node bearbeiten"),
          content: Container(
            child: Column(
              children: <Widget>[
                TextField(
                  decoration: InputDecoration(
                      hintText: "Node benamseln..."
                  ),
                  onChanged: (s) => {
                    n.title = s
                  },
                  controller: controller
                )
              ],
            ),
            height: 100.0,
          ),
          actions: <Widget>[
            new FlatButton(
              child: new Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void exitSelectionMode() {
    setState(() {
      inSelectionMode = false;
      active = null;
      selection = {};
    });
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