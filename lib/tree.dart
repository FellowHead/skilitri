import 'dart:async';
import 'dart:io';

//import 'package:audio_recorder/audio_recorder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:fluttertoast/fluttertoast.dart';
//import 'package:fluttery_audio/fluttery_audio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

class Tree {
  Set<Node> nodes = {};
  Map<Node, List<int>> _childMap;

  Tree([Set<Node> nodes]) {
    if (nodes != null) {
      for (Node n in nodes.toSet()) {
        n.tree = this;
        for (Node d in n.getDescendants()) {
          d.tree = this;
          if (!nodes.contains(d)) {
            nodes.add(d);
          }
        }
      }
      this.nodes = nodes;
    }
  }

  @override
  String toString() {
    return "TREE ROOT";
  }

  Tree.fromJson(Map<String, dynamic> json) {
    _childMap = {};
    nodes = (json['nodes'] as List<dynamic>).map((f) => Node.fromJson(f, this)).toSet();

    _childMap.forEach((node, childrenIDs) {
      childrenIDs.forEach((i) => {
        node.addChild(nodes.firstWhere((n) => n._id == i))
      });
    });
  }

  void _rearrangeIds() {
    Node._idCounter = 0;
    nodes.forEach((n) => {
      n._id = Node._idCounter++
    });
  }

  Map<String, dynamic> toJson() {
    _rearrangeIds();
    return {
      'nodes': nodes.map((f) => f.toJson()).toList()
    };
  }
}

enum SelectionType {
  None,
  Selected,
  Focused,
  Dragged
}

class Node {
  String title;
  Offset position;
  Set<Node> _children = {};
  Set<Node> get children => _children;
  Set<Node> _parents = {};
  NodeBody _body;
  NodeBody get body => _body;
  bool isDragged = false;
  DateTime creationDate;
  Tree tree;
  int _id;
  static int _idCounter = 0;

  void unlinkChild(Node n) {
    _children.remove(n);
    n._parents.remove(this);
  }

  void unlinkParent(Node n) {
    _parents.remove(n);
    n._children.remove(this);
  }

  void addChild(Node n) {
    n._parents.add(this);
    _children.add(n);
  }

  void clearParents() {
    for (Node p in _parents) {
      p._children.remove(this);
    }
    _parents.clear();
  }

  Node({@required String title, @required Offset position, @required NodeBody body, Set<Node> children}) {
    _id = _idCounter;
    _idCounter++;

    this.title = title;
    this.position = position;
    creationDate = DateTime.now();
    setBody(body);

    if (children == null) {
      children = {};
    } else {
      if (tree != null) {
        tree.nodes.addAll(children);
      }
      for (Node n in children) {
        n._parents.add(this);
      }
    }
    this._children = children;
  }

  Node.fromJson(Map<String, dynamic> json, Tree tree)
      : _id = json['id'],
        title = json['title'],
        position = Offset(json['position']['x'], json['position']['y']),
        creationDate = DateTime.fromMillisecondsSinceEpoch(json['created']),
        _children = {} {
    this.tree = tree;
    tree._childMap.putIfAbsent(this, () => List<int>.from(json['children']));
    setBody(NodeBody.decipher(json['body']));
  }

  Map<String, dynamic> toJson() => {
        'id': _id,
        'title': title,
        'position': {
          'x': position.dx,
          'y': position.dy
        },
        'created': creationDate.millisecondsSinceEpoch,
        'body': {
          'type': _body.getTypeId(),
          'content': _body.toJson()
        },
        'children': _children.map((f) => f._id).toList(growable: false),
      };

  void setBody(NodeBody body) {
    _body = body;
    _body._init(this);
  }

  void addParent(Node n) {
    n.addChild(this);
  }

  Set<Node> getAscendants() {
    Set<Node> out = Set();
    if (_parents.length > 0) {
      for (Node n in _parents) {
        out.addAll(n.getAscendants());
        out.add(n);
      }
    }
    return out;
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

  Widget render(BuildContext context, ValueNotifier notifier, SelectionType sel) {
    ThemeData theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
          color: Color(0xff7030d0).withOpacity(isDragged ? 1.0 : 0.75),
          border: Border.all(width: 5,
              color: sel == SelectionType.None ? Color(0x0) : (sel ==
                  SelectionType.Focused ? theme.primaryColor : theme
                  .primaryColorDark)),
          boxShadow: [
            BoxShadow(
                blurRadius: 25,
                spreadRadius: 5,
                color: Colors.black26
            )
          ],
          borderRadius: BorderRadius.all(Radius.circular(10.0))
      ),
      child: Center(
        widthFactor: 1.0,
          heightFactor: 1.0,
          child: Container(
            padding: EdgeInsets.all(16.0).copyWith(top: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(title,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.0
                  ),
                ),
                _body.renderBody(context, notifier)
              ],
            ),
          )
      ),
    );
  }

  void displayInfo(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
        builder: (ctx) => NodeInfo(node: this),
        settings: RouteSettings()
    ));
  }

  bool check = false;

  @override
  String toString() {
    return "Node($title : $_id)";
  }

  void remove(bool keepChildren) {
    if (keepChildren) {
      for (Node n in _children.toSet()) {
        for (Node p in _parents) {
          p.addChild(n);
        }
      }
    } else {
      for (Node n in _children.toSet()) {
        n.remove(false);
      }
    }
    _children = {};
    for (Node p in _parents) {
      p._children.remove(this);
    }
    tree.nodes.remove(this);
    _parents = null;
  }

  Widget getChildrenInfo(BuildContext context, ValueNotifier notifier) {
    List<ScoreData> data = List();
    for (Node sn in getDescendants().where((n) => n.body is ScoreBody)) {
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
              d.node.displayInfo(context)
            },
            leading: Text(d.node.title),
//            trailing: IconButton(
//              onPressed: () => {
//                (d.node.body as ScoreBody).updoots.remove(d.count),
//                (d.node.body as ScoreBody).score--,
//                notifier.value++
//              },
//              icon: Icon(Icons.delete),
//            ),
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
      case ScoreBody.TYPENAME:
        return ScoreBody.fromJson(content);
      case MediaBody.TYPENAME:
        return MediaBody.fromJson(content);
    }
    print('UNKNOWN NODE TYPE "' + json['type'] + '"');
  }
  
  void _init(Node node) {
    _node = node;
  }

  Widget renderBody(BuildContext context, ValueNotifier notifier);
  List<Widget> getInfo(BuildContext context, ValueNotifier notifier);

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
  Widget renderBody(BuildContext context, ValueNotifier notifier) {
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
  List<Widget> getInfo(BuildContext context, ValueNotifier notifier) {
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
  static const TYPENAME = "score";

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
  Widget renderBody(BuildContext context, ValueNotifier notifier) {
    return Column(
      children: <Widget>[
        RaisedButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onPressed: () => {
            updoot()
          },
          child: Text(
            getTotalScore().toString()
          ),
        )
      ],
    );
  }

  @override
  String getTypeId() {
    return TYPENAME;
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
  List<Widget> getInfo(BuildContext context, ValueNotifier notifier) {
    if (_cScore.text != score.toString() && !(FocusScope.of(context).focusedChild.toString().contains("Edit"))) {
      _cScore.text = score.toString();
    }

    return [
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
      Text(updoots.length.toString() + " counts"),
      Text("Total: " + getTotalScore().toString()),
      Text(getStudyDuration().inDays.toString() + " days, "
          + (getStudyDuration().inHours % Duration.hoursPerDay).toString() + " hours"),
      RaisedButton(
        onPressed: () => {
          showDatePicker(
              context: context,
              initialDate: DateTime.now().subtract(Duration(days: 1)),
              firstDate: DateTime.fromMillisecondsSinceEpoch(0),
              lastDate: DateTime.now().add(Duration(days: 7)),
          ).then((d) => {
            if (d != null) {
              showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now()
              ).then((v) => {
                if (v != null) {
                  updoots.add(d.add(Duration(hours: v.hour, minutes: v.minute))),
                  score++,
                  notifier.value++
                },
              })
            },
          })
        },
        child: Text('Add count'),
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

class MediaBody extends NodeBody {
  static const TYPENAME = "media";
  List<MediaItem> items;

  MediaBody() : super() {
    items = [];
  }

  @override
  List<Widget> getInfo(BuildContext context, ValueNotifier notifier) {
    return [
      ListView(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        padding: EdgeInsets.all(4.0),
        children: items.map((mi) =>
            ListTile(
              title: mi.getInfoPreview(context, notifier),
              onTap: () =>
              {
                Navigator.push(context, MaterialPageRoute(
                  builder: (ctx) => MediaPost(item: mi),
                ))
              },
              trailing: IconButton(
                onPressed: () => {
                  items.remove(mi),
                  notifier.value++
                },
                icon: Icon(Icons.delete),
              ),
            )).toList(),
      ),
    ];
  }

  @override
  String getTypeId() {
    return TYPENAME;
  }

  void addItem(MediaItem item, BuildContext context) {
    items.add(item);
    Navigator.push(context, MaterialPageRoute(
      builder: (ctx) => MediaPost(item: item),
    ));
  }

  void showSelection(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text("Record some shiz"),
          content: Container(
            child: Center(
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.photo_camera),
                    onPressed: () => {
                      addItem(ImagesItem.throughUser(ImageSource.camera, context), context)
                    }
                  ),
                  IconButton(
                      icon: Icon(Icons.photo),
                      onPressed: () => {
                        addItem(ImagesItem.throughUser(ImageSource.gallery, context), context)
                      }
                  ),
                  IconButton(
                    icon: Icon(Icons.mic),
                    onPressed: () => {
                      addItem(AudioItem.throughUser(context), context)
                    },
                  )
                ],
              ),
            ),
          ),
          actions: <Widget>[
            FlatButton(
              onPressed: () => {
                Navigator.of(ctx).pop()
              },
              child: Text("Cancel"),
            )
          ],
        );
      }
    );
  }

  @override
  Widget renderBody(BuildContext context, ValueNotifier notifier) {
    return RaisedButton(
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onPressed: () => {
        showSelection(context)
      },
      child: Text(
        "Record something"
      ),
    );
  }

  static List<MediaItem> loadItems(List<dynamic> json) {
    return json.map((it) => MediaItem._decipher(it)).toList();
  }

  MediaBody.fromJson(Map<String, dynamic> json)
      : items = loadItems(json['items']);

  Map<String, dynamic> toJson() =>
      {
        'items': items.map((mi) => mi.toJson()).toList(growable: false)
      };
}

abstract class MediaItem {
  String comment;
  //double rating = 0.0;
  DateTime creationDate;

  MediaItem([this.creationDate]) {
    if (creationDate == null) {
      creationDate = DateTime.now();
    }
  }

  MediaItem._js(json)
      : creationDate = DateTime.fromMillisecondsSinceEpoch(json['created']),
        //file = File(json['path']),
        comment = json['comment'];
        //rating = json['rating'];
  
  Map<String, dynamic> _addSpecifics();
  Widget getPostPreview(BuildContext context, ValueNotifier notif);
  Widget getInfoPreview(BuildContext context, ValueNotifier notif);
  String _getType();
  DateTime getLastModified();

  static MediaItem _decipher(Map<String, dynamic> json) {
    switch (json['type']) {
      case ImagesItem.TYPENAME: return ImagesItem.fromJson(json);
    }
    print("error? no media item created from json");
  }

  Map<String, dynamic> toJson() =>
      {
        'type': _getType(),
        'created': creationDate.millisecondsSinceEpoch,
        'comment': comment,
        //'rating': rating,
      }..addAll(_addSpecifics());
}

abstract class SingleMediaItem extends MediaItem {
  File file;

  SingleMediaItem(this.file, [DateTime created]) : super(created);

  //SingleMediaItem.fromJson(Map<String, dynamic> json) : super._js(json);

  @override
  DateTime getLastModified() {
    return file.lastModifiedSync();
  }

  @override
  Map<String, dynamic> _addSpecifics() => {
    'path': file.path
  };
}

class VideoItem extends SingleMediaItem {
  static const String TYPENAME = "video";

  VideoItem(File file) : super(file);

  VideoItem.throughUser(ImageSource source, BuildContext context) : super(null) {
    recVideo(source, context, null);
  }

  @override
  String _getType() {
    return TYPENAME;
  }

  Future recVideo(ImageSource source, BuildContext context, ValueNotifier notif) async {
    var video = await ImagePicker.pickVideo(source: source);
    Navigator.pop(context);
    if (video != null) {
      file = video;
      if (notif != null) {
        notif.value++;
      }
    }
  }

  VideoPlayerController controller;

  @override
  Widget getInfoPreview(BuildContext context, ValueNotifier notif) {
    return null;
  }

  @override
  Widget getPostPreview(BuildContext context, ValueNotifier notif) {
    if (controller == null) {
      controller = VideoPlayerController.file(file)..initialize().then((_) => notif.value++);
    }

    return controller.value.initialized ? AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: VideoPlayer(
        controller
      )
    ) : Container();
  }

}

class AudioItem extends SingleMediaItem {
  static const String TYPENAME = "audio";

  AudioItem(File file) : super(file);

  AudioItem.throughUser(BuildContext context) : super(null) {
    recAudio(context);
  }

  Future recAudio(BuildContext context) async {
    //bool hasPermissions = await AudioRecorder.hasPermissions;
    //final directory = await getApplicationDocumentsDirectory();
    final directory = Directory("/storage/emulated/0/Android/data/me.fellowhead.skilitri/files");

    FlutterSound flutterSound = FlutterSound();
    String path = await flutterSound.startRecorder(null, androidEncoder: AndroidEncoder.AMR_WB);

//    await AudioRecorder.start(path: '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.aac',
//        audioOutputFormat: AudioOutputFormat.AAC);

    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text("Recording audio..."),
            content: Column(
              children: <Widget>[
                FlatButton(
                    onPressed: () =>
                    {
//                      AudioRecorder.stop().then((rec) =>
//                      {
//                        file = File(rec.path),
//                        Navigator.pop(ctx)
//                      })
                      flutterSound.stopRecorder().then((s) => {
                        print("Stopped recorder... $s")
                      })
                    },
                    child: Text("Stop")
                )
              ],
            ),
          );
        }
    );

//    Fluttertoast.showToast(
//      msg: "Added media",
//      toastLength: Toast.LENGTH_SHORT,
//      gravity: ToastGravity.BOTTOM,
//      backgroundColor: Color(0x60000000),
//      timeInSecForIos: 1,
//    );
  }

  @override
  String _getType() {
    return TYPENAME;
  }

  bool isPlaying() {
    //return player.state == AudioPlayerState.PLAYING;
    return true;
  }

  @override
  Widget getInfoPreview(BuildContext context, ValueNotifier notif) {
    //print(player.state);

//    return Audio(
//      audioUrl: "http://techslides.com/demos/samples/sample.aac",
//      playbackState: PlaybackState.playing,
//      child: Container(
//          height: 25,
//          child: Row(
//            children: <Widget>[
//              IconButton(
//                onPressed: () => {
////                if (isPlaying()) {
////                  player.stop()
////                } else {
////                  player.preload(Uri.file(file.path).toString()).then((l) => {
////                    player.stop().then((uff) => {
////                      player.play(Uri.file(file.path).toString())
////                    })
////                  }),
////                },
//                  notif.value++
//                },
//                icon: Icon(isPlaying() ? Icons.pause : Icons.play_arrow),
//              )
//            ],
//          )
//      ),
//    );
    return null;
  }

  @override
  Widget getPostPreview(BuildContext context, ValueNotifier notif) {
    // TODO: implement getPostPreview
    return null;
  }
}

class ImagesItem extends MediaItem {
  static const String TYPENAME = "images";
  List<File> files;

  ImagesItem(this.files) : super();

  ImagesItem.throughUser(ImageSource source, BuildContext context) : super() {
    files = List<File>();
    getImage(source, context, null);
  }

  ImagesItem.fromJson(Map<String, dynamic> json)
      : files = List<File>.from(json['paths'].map((f) => File(f))),
        super._js(json);

  @override
  String _getType() {
    return TYPENAME;
  }

  @override
  Map<String, dynamic> _addSpecifics() =>
      {
        'paths': files.map((f) => f.path).toList()
      };

  Future getImage(ImageSource source, BuildContext context, ValueNotifier notif) async {
    var image = await ImagePicker.pickImage(source: source);
    Navigator.pop(context);
    if (image != null) {
      files.add(image);
      if (notif != null) {
        notif.value++;
      }
    }
  }

  @override
  Widget getPostPreview(BuildContext context, ValueNotifier notif) {
    double height = 200;
    //ValueNotifier nf = ValueNotifier(0);
    bool _canDeleteSource = false;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: files.map((f) =>
        // ignore: unnecessary_cast
        GestureDetector(
          child: Padding(child: Image.file(f, height: height), padding: EdgeInsets.only(right: 10.0)),
          onLongPressStart: (details) =>
          {
            _canDeleteSource = f.path.contains("skilitri"),
            Feedback.forLongPress(context),
            showDialog(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: Text("Remove image..."),
//                    content: CheckboxListTile(
//                        value: _deleteSelectionCompletely,
//                        onChanged: (v) => {
//                          _deleteSelectionCompletely = v,
//
//                        },
//                        title: Text("Remove image from device")
//                    ),
                    content: _canDeleteSource ? FlatButton(
                      child: Text("Delete forever (pls don't)"),
                      onPressed: () =>
                      {
                        files.remove(f),
                        f.delete(),
                        Navigator.pop(ctx)
                      },
                    ) : null,
                    actions: <Widget>[
                      FlatButton(
                        child: Text("Cancel"),
                        onPressed: () =>
                        {
                          Navigator.pop(ctx)
                        },
                      ),
                      FlatButton(
                        child: Text("Remove"),
                        onPressed: () =>
                        {
                          files.remove(f),
//                          if (_deleteSelectionCompletely) {
//                            f.delete()
//                          },
                          Navigator.pop(ctx)
                        },
                      ),
                    ],
                  );
                }
            )
          },
        ) as Widget).toList()
          ..add(IconButton(
            icon: Icon(Icons.add),
            padding: EdgeInsets.all(height / 4),
            onPressed: () =>
            {
              showDialog(
                  context: context,
                  builder: (ctx) {
                    return AlertDialog(
                      title: Text("Add photo from..."),
                      content: Row(
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.photo_camera),
                            onPressed: () =>
                            {
                              getImage(ImageSource.camera, ctx, notif)
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.photo),
                            onPressed: () =>
                            {
                              getImage(ImageSource.gallery, ctx, notif)
                            },
                          ),
                        ],
                      ),
                    );
                  }
              )
            },
          )),
      ),
    );
  }

  @override
  Widget getInfoPreview(BuildContext context, ValueNotifier notif) {
    return Container(
      height: 50,
      child: Row(
        children: files.map((f) =>
            Padding(
                child: Image.file(f, height: 50),
              padding: EdgeInsets.only(right: 5.0),
            )
        ).toList(),
      )
    );
  }

  @override
  DateTime getLastModified() {
    return (files.toList(growable: false)
      ..sort((a,b) =>
            b.lastModifiedSync().millisecondsSinceEpoch
          - a.lastModifiedSync().millisecondsSinceEpoch
      )).first.lastModifiedSync();
  }
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
                                  hintText: "Enter node name..."
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
                          ..addAll(
                              widget.node.body.getInfo(context, widget.notif))
                          ..add(Divider(
                            height: 30.0,
                          ))
                          ..add(widget.node.getChildrenInfo(context, widget.notif))
                    ),
                  ),
                )
            )
        )
    );
  }
}



class MediaPost extends StatefulWidget {
  final MediaItem item;
  final ValueNotifier<int> notif = ValueNotifier(0);

  MediaPost({Key key, @required this.item}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return MediaPostState();
  }
}

class MediaPostState extends State<MediaPost> {
  Timer timer;
  TextEditingController cDescription;

  @override
  Widget build(BuildContext context) {
    if (timer == null) {
      timer = Timer.periodic(
          Duration(seconds: 1), (Timer t) => widget.notif.value++);
      cDescription = TextEditingController(text: widget.item.comment);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Edit media item'),
        ),
        body: AnimatedBuilder(
            animation: widget.notif, builder: (ctx, constraints) =>
            Container(
                child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: Column(
                                  children: <Widget>[
                                    Container(
                                        child: widget.item.getPostPreview(
                                            ctx, widget.notif)
                                    ),
                                    TextField(
                                        decoration: InputDecoration(
                                            hintText: "Add a comment..."
                                        ),
                                        onChanged: (s) =>
                                        {
                                          widget.item.comment = s
                                        },
                                        controller: cDescription
                                    ),
//                                    Slider.adaptive(value: widget.item.rating,
//                                        onChanged: (v) =>
//                                        {
//                                          widget.item.rating = v,
//                                          widget.notif.value++
//                                        })
                                  ]
                              ),
                            )
                        ),
                      ),
                      Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            FlatButton(
                                onPressed: () =>
                                {
                                  Navigator.pop(context)
                                },
                                child: Text("OK")
                            )
                          ],
                        ),
                      )
                    ]
                )
            )
        )
    );
  }
}