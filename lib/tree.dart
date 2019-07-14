import 'package:flutter/material.dart';

class Root extends Parent {
  Root([Set<Node> children]) : super(children);

  @override
  String toString() {
    return "TREE ROOT";
  }

  Root.fromJson(Map<String, dynamic> json)
      : super(Parent._childrenFromJson(json));
  //toJson() => super.toJson();
}

enum SelectionType {
  None,
  Selected,
  Focused,
  Dragged
}

abstract class Parent {
  Set<Node> _children;

  Parent([Set<Node> children]) {
    if (children == null) {
      children = {};
    } else {
      for (Node n in children) {
        n.parent = this;
      }
    }
    this._children = children;
  }

  Set<Node> getDescendants() {
    Set<Node> out = Set();
    if (_children.length > 0) {
      for (Node n in _children) {
        out.addAll(n.getDescendants());
        out.add(n);
      }
    }
    return out;
  }

  void addChild(Node n) {
    //print("Adding " + n.toString() + " to " + toString());
    if (n.parent != null) {
      n.parent._children.remove(n);
    }
    n.parent = this;
    _children.add(n);
  }

  static Set<Node> _childrenFromJson(Map<String, dynamic> json) {
    return (json['children'] as List<dynamic>).map((f) => Node.fromJson(f)).toSet();
  }

  Map<String, dynamic> toJson() =>
      {
        'children': _children.map((f) => f.toJson()).toList(growable: false),
      };
}

class Node extends Parent {
  String title;
  Offset position;
  Parent parent;
  NodeBody _body;
  NodeBody get body => _body;
  bool isDragged = false;
  DateTime creationDate;

  Node({@required String title, @required Offset position, @required NodeBody body, Set<Node> children})
      : super(children) {
    this.title = title;
    this.position = position;
    creationDate = DateTime.now();
    setBody(body);
  }

  Node.fromJson(Map<String, dynamic> json)
      : title = json['title'],
        position = Offset(json['position']['x'], json['position']['y']),
        creationDate = DateTime.fromMillisecondsSinceEpoch(json['created']),
        super(Parent._childrenFromJson(json)) {
    setBody(NodeBody.decipher(json['body']));
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'position': {
          'x': position.dx,
          'y': position.dy
        },
        'created': creationDate.millisecondsSinceEpoch,
        'body': {
          'type': _body.getTypeId(),
          'content': _body.toJson()
        }
      }..addAll(super.toJson());

  void setBody(NodeBody body) {
    _body = body;
    _body._init(this);
  }

  void setParent(Parent p) {
    if (parent != null) {
      parent._children.remove(this);
    }
    if (p != null) {
      p.addChild(this);
    }
    parent = p;
  }

  Set<Parent> getAscendants() {
    Set<Parent> out = Set();
    Parent p = parent;
    while (p is Node) {
      out.add(p);
      p = (p as Node).parent;
    }
    out.add(p);
    return out;
  }

  Root getTreeRoot() {
    Parent p = parent;
    while (p is Node) {
      p = (p as Node).parent;
    }
    return p;
  }

  Widget render(ThemeData theme, ValueNotifier notifier, SelectionType sel) {
    return Container(
      width: 225,
      height: 100,
      decoration: BoxDecoration(
        color: theme.buttonColor.withOpacity(isDragged ? 1.0 : 0.75),
        border: Border.all(width: 5, color: sel == SelectionType.None ? Color(0x0) : (sel == SelectionType.Focused ? theme.primaryColor : theme.primaryColorDark)),
        boxShadow: [
          BoxShadow(
            blurRadius: 15,
            spreadRadius: 5,
            color: Colors.black26
          )
        ]
      ),
      child: Center(
        child: Column(
          children: <Widget>[
            Text(title,
              style: TextStyle(
                  color: Colors.white,
                  //fontSize: 15.0 / scale
                  fontSize: 18.0
              ),
            ),
            _body.renderBody(notifier)
          ],
        ),
      ),
    );
  }

  bool check = false;

  @override
  String toString() {
    return "Node(" + title + ")";
  }

  void remove(bool keepChildren) {
    if (keepChildren) {
      for (Node n in _children.toSet()) {
        parent.addChild(n);
      }
    } else {
      for (Node n in _children.toSet()) {
        n.remove(false);
      }
    }
    _children = {};
    parent._children.remove(this);
    parent = null;
  }

  Widget getChildrenInfo(ValueNotifier notifier) {
    List<ScoreData> data = List();
    for (Node sn in _children.where((n) => n.body is ScoreBody)) {
      (sn.body as ScoreBody).updoots.forEach((dt) => {
        data.add(ScoreData(sn, dt))
      });
    }
    data.sort((a, b) => b.count.millisecondsSinceEpoch - a.count.millisecondsSinceEpoch);
    return ListView(
      physics: NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 4.0),
      children: data.map((d) =>
          ListTile(
            title: Text(ScoreBody.dateToBeautiful(d.count)),
            onTap: () => {

            },
            leading: Text(d.node.title),
            trailing: IconButton(
              onPressed: () => {
                (d.node.body as ScoreBody).updoots.remove(d.count),
                (d.node.body as ScoreBody).score--,
                notifier.value++
              },
              icon: Icon(Icons.delete),
            ),
          )).toList(),
    );
  }
}

class ScoreData {
  Node node;
  DateTime count;

  ScoreData(this.node, this.count);
}

abstract class NodeBody {
  Node _node;

  NodeBody();

  static NodeBody decipher(Map<String, dynamic> json) {
    dynamic content = json['content'];
    switch(json['type']) {
      case 'demo':
        return DemoBody.fromJson(content);
      case 'score':
        return ScoreBody.fromJson(content);
    }
    print('UNKNOWN NODE TYPE "' + json['type'] + '"');
    return DemoBody();
  }
  
  void _init(Node node) {
    _node = node;
  }

  Widget renderBody(ValueNotifier notifier);
  List<Widget> getInfo(ValueNotifier notifier);

  NodeBody.fromJson(Map<String, dynamic> json);
  Map<String, dynamic> toJson();
  String getTypeId();
}

class DemoBody extends NodeBody {
  bool check = false;

  DemoBody() : super();

  DemoBody.fromJson(Map<String, dynamic> json)
      : check = json['check'];

  Map<String, dynamic> toJson() =>
      {
        'check': check,
      };

  @override
  Widget renderBody(ValueNotifier notifier) {
    return Column(
      children: <Widget>[
        Checkbox(
          onChanged: (v) =>
          {
            check = v,
            notifier.value++
          },
          value: check,
        ),
      ],
    );
  }

  @override
  String getTypeId() {
    return "demo";
  }

  @override
  List<Widget> getInfo(ValueNotifier notifier) {
    return [
      Text("sicko node node node node node node"),
      CheckboxListTile(
        title: Text("cha cha real smooth?"),
        controlAffinity: ListTileControlAffinity.leading,
        onChanged: (v) =>
        {
          check = v,
          notifier.value++
        },
        value: check,
      ),
    ];
  }
}

class ScoreBody extends NodeBody {
  int score;
  List<DateTime> updoots;

  ScoreBody({int score = 0}) : super() {
    this.score = score;
    updoots = List<DateTime>();
  }

  ScoreBody.fromJson(Map<String, dynamic> json)
      : score = json['score'], updoots = fromTimestamps(List.from(json['timestamps']));

  Map<String, dynamic> toJson() =>
      {
        'score': score,
        'timestamps': getTimestamps()
      };

  static List<DateTime> fromTimestamps(List<int> timestamps) {
    List<DateTime> out = List.from(timestamps.map((ts) => DateTime.fromMillisecondsSinceEpoch(ts, isUtc: true)));
    sort(out);
    return out;
  }

  List<int> getTimestamps() {
    return updoots.map((dt) => dt.millisecondsSinceEpoch).toList();
  }

  void updoot() {
    score++;
    updoots.add(DateTime.now());
    sort(updoots);
  }

  int getTotalScore() {
    int out = score;
    for (Node n in _node.getDescendants()) {
      if (n._body is ScoreBody) {
        out += (n._body as ScoreBody).score;
      }
    }
    return out;
  }

  @override
  Widget renderBody(ValueNotifier notifier) {
    return Column(
      children: <Widget>[
//        Text(getTotalScore().toString(),
//          style: TextStyle(
//              color: Colors.white,
//              fontSize: 17.0
//          ),
//        ),
        RaisedButton(
          onPressed: () => {
            updoot()
          },
          child: Text(
            getTotalScore().toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 17.0
            ),
          ),
        )
      ],
    );
  }

  @override
  String getTypeId() {
    return "score";
  }

  Duration getStudyDuration() {
    return DateTime.now().difference(_node.creationDate);
  }

  static void sort(List<DateTime> datetimes) {
    datetimes.sort((a, b) => b.millisecondsSinceEpoch - a.millisecondsSinceEpoch);
  }

  static String getWeekdayName(int wekd) {
    switch (wekd) {
      case 1: return "Monday";
      case 2: return "Tuesday";
      case 3: return "Wednesday";
      case 4: return "Thursday";
      case 5: return "Friday";
      case 6: return "Saturday";
      case 7: return "Sunday";
    }
    return "Pizza time ($wekd)";
  }

  static String _betterify(dynamic d) {
    return d.toString().padLeft(2, '0');
  }

  static String dateToBeautiful(DateTime dt) {
    return "${getWeekdayName(dt.weekday)}, ${_betterify(dt.day)}.${_betterify(dt.month)}.${dt.year}, ${_betterify(dt.hour)}:${_betterify(dt.minute)}";
  }

  @override
  List<Widget> getInfo(ValueNotifier notifier) {
    //print("getinfo");
    if (_cScore.text != score.toString()) {
      _cScore.text = score.toString();
    }

    return [
      Text(updoots.length.toString() + " counts in "
          + getStudyDuration().inDays.toString() + " days, "
          + (getStudyDuration().inHours % Duration.hoursPerDay).toString() +
          " hours"),
      Text(""),
      TextField(
          decoration: InputDecoration(
              hintText: "Enter score..."
          ),
          onChanged: (s) =>
          {
            score = int.parse(s),
            //notifier.value++
          },
          keyboardType: TextInputType.numberWithOptions(
              signed: false, decimal: false),
          controller: _cScore
      ),
      ListView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
              padding: EdgeInsets.all(4.0),
              children: updoots.map((dt) =>
                  ListTile(
                    title: Text(dateToBeautiful(dt)),
                    onTap: () => {

                    },
                    trailing: IconButton(
                      onPressed: () => {
                        updoots.remove(dt),
                        score--,
                        notifier.value++
                      },
                      icon: Icon(Icons.delete),
                    ),
                  )).toList(),
            ),
    ];
  }
  TextEditingController _cScore = TextEditingController();
}