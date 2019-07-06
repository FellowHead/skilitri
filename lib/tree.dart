import 'package:flutter/material.dart';

import 'main.dart';

class Root extends Parent {
  State state;

  Root(State state, [Set<Node> children]) : super(children) {
    this.state = state;
  }
}

class Parent {
  Set<Node> children;

  Parent([Set<Node> children]) {
    if (children == null) {
      children = {};
    } else {
      for (Node n in children) {
        n.parent = this;
      }
    }
    this.children = children;
  }

  Set<Node> getDescendants() {
    Set<Node> out = Set();
    if (children.length > 0) {
      for (Node n in children) {
        out.addAll(n.getDescendants());
      }
    }
    if (this is Node) {
      out.add(this);
    }
    return out;
  }
}

class Node extends Parent {
  String title;
  Offset position;
  Parent parent;

  Node({@required String title, @required Offset position, Set<Node> children})
      : super(children) {
    this.title = title;
    this.position = position;
  }

  Root getTreeRoot() {
    Parent p = parent;
    while (p is Node) {
      p = (p as Node).parent;
    }
    return p;
  }

  Widget render(MainViewState state) {
    return Listener(
      child: DecoratedBox(
        decoration: BoxDecoration(
            color: Colors.red
        ),
        child: Container(
          width: 100,
          height: 100,
          child: Column(
            children: <Widget>[
              Text(title,
                style: TextStyle(
                    color: Colors.white,
                    //fontSize: 15.0 / scale
                    fontSize: 18.0
                ),
              ),
              Expanded(
                child: renderBody(state),
              ),
            ],
          ),
        ),
      ),
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => {
        state.setState(() => {
          state.inZoomMode = false
        })
      },
      onPointerUp: (event) => {
        state.setState(() => {
          state.inZoomMode = true
        })
      },
      onPointerMove: (event) => {
        state.setState(() => {
          position += event.delta.scale(1 / state.scale, -1 / state.scale)
        })
      },
    );
  }

  bool check = false;

  Widget renderBody(MainViewState state) {
    return Column(
      children: <Widget>[
        Listener(
          onPointerUp: (event) => {
            if (!state.inZoomMode) {
              print(DateTime.now().millisecondsSinceEpoch),
              state.setState(() => {
                check = !check,
              })
            }
          },
          child: Checkbox(
            onChanged: (v) => {
            },
            value: check,
          ),
        ),
      ],
    );
  }
}

class ScoreNode extends Node {
  int score;

  ScoreNode({@required String title, int score = 0, @required Offset position, Set<Node> children}) : super(title: title, position: position, children: children) {
    this.score = score;
  }

  int getTotalScore() {
    int out = score;
    for (Node n in getDescendants()) {
      if (n is ScoreNode) {
        out += n.score;
      }
    }
    return out;
  }

  @override
  Widget renderBody(State state) {
    return Column(
      children: <Widget>[
        Text(getTotalScore().toString(),
          style: TextStyle(
              color: Colors.white,
              fontSize: 17.0
          ),
        ),
      ],
    );
  }
}

class EnumNode extends Node {

}