import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
//import 'package:fluttery_audio/fluttery_audio.dart';
import 'package:skilitri/tree.dart';
import 'package:matrix_gesture_detector/matrix_gesture_detector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'skilitri',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        primaryColorLight: Color(0xff90ffa0),
        primaryColor: Color(0xff60dcaf),
        primaryColorDark: Color(0xffd0e0e0),
        backgroundColor: Color(0xffa0a0a0),
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
  SkillTree tree;
  Matrix4 matrix = Matrix4.identity();
  ValueNotifier<int> notifier = ValueNotifier(0);
  bool inSelectionMode = false;
  Set<Node> selection = {};
  Node active;
  Node dragged;

  void resetTree() {
//    tree = SkillTree(
//        {
//          Node(
//              title: "Node",
//              position: Offset(0, 0),
//              body: DemoBody(),
//              children: {
//                Node(
//                    title: "Score Node #1",
//                    position: Offset(0, -100),
//                    body: ScoreBody(score: 100),
//                    children: {
//                      Node(
//                        title: "Score Node #2",
//                        position: Offset(-300, -200),
//                        body: ScoreBody(score: 5),
//                      ),
//                      Node(
//                        title: "Score Node #3",
//                        position: Offset(300, -200),
//                        body: ScoreBody(score: 63),
//                      )
//                    }
//                )
//              }
//          )
//        }
//    );

    tree = SkillTree()
      ..addNode("Node", Offset(0, 0))
      ..addNode("Nother Node", Offset(0, -200));
  }

  Widget buildNode(Node n, Function onTap, Function onLongPress, SelectionType sel) {
    Matrix4 ma = matrix.clone();
    ma.translate(n.position.dx, -n.position.dy);

    return Transform(
        transform: ma,
        child: GestureDetector(
            onTapUp: (details) => onTap(),
            onLongPressStart: (details) => onLongPress(),
            child: MatrixGestureDetector(
                shouldRotate: false,
                shouldScale: false,
                onMatrixUpdate: (m, tm, sm, rm) {
                  n.isDragged = true;
                  dragged = n;

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
                  child: n.render(context, notifier, sel),
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
    }
    return SelectionType.None;
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

  void onAddNode(Offset position, {Node parent, Node child}) {
    var controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Create new node"),
          content: Column(
            children: <Widget>[
              TextField(
                decoration: InputDecoration(
                  hintText: "Enter node name..."
                ),
                controller: controller,
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () => {
                addNode(controller.text, position, parent: parent, child: child),
                Navigator.pop(ctx)
              },
            )
          ],
        );
      }
    );
  }

  void addNode(String title, Offset position, {Node parent, Node child}) {
    Node nNode = tree.addNode(title, position);
    if (parent != null) { nNode.addParent(parent); }
    if (child != null) { nNode.addChild(child); }
    select(nNode, true);
  }

  // I/O STUFF

  _read() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      //final file = File('${directory.path}/tree.fwd');
      //final file = File('${directory.path}/baum.fwd');
      final file = File('${directory.path}/uwu.fwd');
      String text = await file.readAsString();
      print(text);
      setState(() => {
        tree = SkillTree.fromJson(jsonDecode(text))
      });
    } on FileSystemException {
      print("Can't read file");
    }
  }

  _save() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/uwu.fwd');
    final text = jsonEncode(tree.toJson());
    print(text);
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

  Widget buildViewport(Function(Node) onTap, Function(Node) onLongPress, SelectionType Function(Node) selectionType,
      Color Function(Node, Node) lineColor, {void Function() onUpdate, List<ValueNotifier> arr}) {
    if (arr != null) {
      arr.clear();
      arr.add(notifier);
    }
    if (onUpdate != null) {
      notifier.addListener(onUpdate);
    }
    return Listener(
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
                      onAddNode(
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
                                    buildCanvas(lineColor),
                                    Stack(
                                      children: tree
                                          .nodes
                                          .map((n) =>
                                          buildNode(n, () => onTap(n), () => onLongPress(n), selectionType(n))
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
    );
  }

  @override
  Widget build(BuildContext context) {
    if (tree == null) {
      resetTree();
    }

    return WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
            appBar: AppBar(
              title: Text('skilitri'),
            ),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    child: Text("boi, look at deez achievements"),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor
                    ),
                  ),
                ]..addAll(tree.getSortedAchievements().map((a) => a.render(context, this)).toList()),
              )
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
                    child: buildViewport((n) => {
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
                        setState(() => {})
                      } else {
                        n.displayInfo(context)
                      },
                      onDragStop()
                    }, (n) => {
                      Feedback.forLongPress(context),
                      select(n, true)
                    },
                        getSelectionType,
                        (n, child) {
                          return Colors.black38;
                        }
                    )
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
                          onPressed: selection.length == 2 &&
                              (selection.last.hasParent(selection.first)
                              || selection.first.hasParent(selection.last)) ? () =>
                          {
                            setState(() =>
                            {
                              if (selection.last.hasParent(selection.first)) {
                                selection.last.unlinkParent(selection.first),
                                onAddNode((selection.first.position + selection.last.position) / 2,
                                    parent: selection.first,
                                    child: selection.last
                                )
                              } else {
                                selection.first.unlinkParent(selection.last),
                                onAddNode((selection.first.position + selection.last.position) / 2,
                                    parent: selection.last,
                                    child: selection.first
                                )
                              },
                            })
                          } : null,
                          icon: Icon(
                              Icons.add
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
                                for (Node c in n.children.toSet()) {
                                  if (selection.contains(c)) {
                                    c.unlinkParent(n)
                                  }
                                }
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
                              selection.first.displayInfo(context)
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
            ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => {
              tree.addAchievementThroughUser(context, this)
            },
            child: Icon(Icons.library_add),
          ),
        )
    );
  }

  void onDragStop() {
    if (dragged != null) {
      dragged.isDragged = false;
      notifier.value++;
    }
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

  Widget buildCanvas(Color Function(Node, Node) lineColor) {
    return Transform(
      transform: matrix,
      child: Center(
        child: CustomPaint(
          painter: ShapesPainter(tree, lineColor),
        ),
      ),
    );
  }
}

class ShapesPainter extends CustomPainter {
  SkillTree root;
  Color Function(Node, Node) lineColor;

  ShapesPainter(this.root, this.lineColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.strokeWidth = 5;

    for (Node n in root.nodes) {
      for (Child c in n.children) {
        if (c is Node) {
          paint.color = lineColor(n, c);
          Offset start = c.position.scale(1, -1);
          Offset end = n.position.scale(1, -1);
          canvas.drawLine(start, end, paint);
          canvas.drawCircle(Offset.lerp(start, end, 0.7), 25, paint);
        }
      }
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}