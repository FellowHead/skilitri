import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:skilitri/tree.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
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
        primaryColorLight: Color(0xff90ffa0),
        primaryColor: Color(0xff60dcaf),
        primaryColorDark: Color(0xffd0e0e0),
        backgroundColor: Color(0xffa0a0a0),
        //buttonColor: Color(0xff6070c0)
      ),
      home: Skilitri()
    );
  }
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
  Matrix4 matrix = Matrix4.identity();
  ValueNotifier<int> notifier = ValueNotifier(0);
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
                displayInfo(n)
              },
              onDragStop()
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
                  child: n.render(context, notifier, getSelectionType(n)),
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
        body: ScoreBody(score: 0)
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
    } on FileSystemException {
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
      msg: "Saved",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Color(0x60000000),
      timeInSecForIos: 1,
    );
  }

  Future<bool> _onWillPop() {
    exitSelectionMode();
    return Future<bool>.value(false);
  }

  @override
  Widget build(BuildContext context) {
    //return buildSmol();

    if (tree == null) {
      resetTree();
    }

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
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
                      onPointerUp: (lol) =>
                      {
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
                                        print('well bois we did it, overflow is no more')
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
                              displayInfo(selection.first)
                            })
                          } : null,
                          icon: Icon(
                              Icons.info_outline
                          ),
                        ),
                      ],
                    ),
                    height: inSelectionMode ? 50 : 0,
                  ),
                ]
            )
        )
    );
  }

  void onDragStop() {
    if (dragged != null) {
      dragged.isDragged = false;
      notifier.value++;
    }
  }

  void displayInfo(Node n) {
    Navigator.push(context, MaterialPageRoute(
      builder: (ctx) => NodeInfo(node: n),
      settings: RouteSettings()
    ));
  }

  void exitSelectionMode() {
    setState(() {
      inSelectionMode = false;
      active = null;
      selection = {};
    });
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

class NodeInfo extends StatefulWidget {
  final Node node;
  final ValueNotifier<int> notif = ValueNotifier(0);

  NodeInfo({Key key, @required this.node}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return NodeInfoState();
  }
}

class NodeInfoState extends State<NodeInfo> {
  Timer timer;
  TextEditingController cTitle;

  @override
  Widget build(BuildContext context) {
    if (timer == null) {
      timer = Timer.periodic(
          Duration(seconds: 1), (Timer t) => widget.notif.value++);
      cTitle = TextEditingController(text: widget.node.title);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Node information'),
        ),
        body: AnimatedBuilder(
            animation: widget.notif, builder: (ctx, constraints) =>
        Container(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: Column(
                children: <Widget>[
                  TextField(
                      decoration: InputDecoration(
                          hintText: "Name the node..."
                      ),
                      onChanged: (s) =>
                      {
                        widget.node.title = s
                      },
                      controller: cTitle
                  ),
                  Divider(
                    height: 30.0,
                  )
                ]
                  ..addAll(widget.node.body.getInfo(context, widget.notif))
                ..add(Divider(
                      height: 30.0,
                    ))
                ..add(widget.node.getChildrenInfo(widget.notif))
              ),
            ),
            )
        )
        )
    );
  }
}