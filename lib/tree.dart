import 'dart:async';
import 'dart:io';

//import 'package:audio_recorder/audio_recorder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_sound/android_encoder.dart';
import 'package:flutter_sound/flutter_sound.dart';
//import 'package:fluttery_audio/fluttery_audio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:skilitri/theme.dart';
import 'package:video_player/video_player.dart';

import 'achievements.dart';

class Achievement extends TreeNeeder with Child {
  String comment = "";
  List<MediaItem> mediaItems = [];

  Achievement(SkillTree tree) : super(tree);

  Map<String, dynamic> toJson() =>
      super.toJson()
        ..addAll({
          'comment': comment,
          'media': mediaItems.map((mi) => mi.toJson()).toList(growable: false)
        });

  Achievement.fromJson(Map<String, dynamic> json, SkillTree tree)
      : comment = json['comment'],
        mediaItems = List.from(json['media'])
            .map((m) => MediaItem._decipher(m))
            .toList(),
        super.fromJson(json, tree);

  ListTile render(BuildContext context) {
    return ListTile(
      title: Column(
        children: <Widget>[
          Text(SkillTree.dateToBeautiful(creationDate), style: TextStyle(color: Colors.black38),),
          Text(
            comment,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      onTap: () =>
      {
        Navigator.push(context, MaterialPageRoute(
            builder: (ctx) => EditAchievement(this)
        )).then((res) => {
          if (res != null) {

          }
        })
      },
    );
  }

  void remove() {
    for (Node p in _parents) {
      p.children.remove(this);
    }
    tree.achievements.remove(this);
    _parents = null;
  }

  @override
  String toString() {
    return "Achievement($comment)";
  }
}

class SkillTree {
  Set<Node> nodes = {};
  Map<Node, List<int>> _childMap;
  Set<Achievement> achievements = {};

  Map<int, Child> _ids = Map();

  List<Achievement> getSortedAchievements() {
    return achievements.toList(growable: false)..sort(
            (a, b) => b.creationDate.millisecondsSinceEpoch - a.creationDate.millisecondsSinceEpoch);
  }

  SkillTree();

  Future<Achievement> addAchievementThroughUser(BuildContext context) async {
    Achievement ach = Achievement(this);
    dynamic result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EditAchievement(ach))
    );
    if (result == null) {
      achievements.add(ach);
      print("added :thumbsup:");
      return ach;
    } else {
      return null;
    }
  }

  Node addNode(String title, Offset position) {
    Node n = Node(title: title, position: position, tree: this);
    nodes.add(n);
    return n;
  }

  SkillTree.fromJson(Map<String, dynamic> json) {
    _childMap = {};
    nodes = (json['nodes'] as List<dynamic>).map((f) => Node.fromJson(f, this)).toSet();
    achievements = (json['achievements'] as List<dynamic>).map((f) => Achievement.fromJson(f, this)).toSet();

    _childMap.forEach((ch, childrenIDs) {
      childrenIDs.forEach((i) => {
        ch.addChild(_ids[i])
      });
    });
  }

  void _rearrangeIds() {
    int _counter = 0;
    _ids = Map();
    _ids.addEntries(nodes.map((n) => MapEntry(_counter++, n)));
    _ids.addEntries(achievements.map((n) => MapEntry(_counter++, n)));
  }

  Map<String, dynamic> toJson() {
    _rearrangeIds();
    return {
      'nodes': nodes.map((f) => f.toJson()).toList(growable: false),
      'achievements': achievements.map((a) => a.toJson()).toList(growable: false)
    };
  }

  Set<Achievement> getConnectedAchievements(Node n) {
    return n.getDescendants().where((ch) => ch is Achievement);
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
}

enum SelectionType {
  None,
  Selected,
  Focused,
  Dragged
}

class TreeNeeder {
  SkillTree tree;
  DateTime creationDate;

  TreeNeeder(this.tree) {
    creationDate = DateTime.now();
  }

  Duration getStudyDuration() {
    return DateTime.now().difference(creationDate);
  }

  int _getIdAsChild() {
    return tree._ids.entries
        // ignore: unrelated_type_equality_checks
        .firstWhere((entry) => entry.value == this)
        .key;
  }

  TreeNeeder.fromJson(Map<String, dynamic> json, this.tree)
      : creationDate = DateTime.fromMillisecondsSinceEpoch(
      json['created']) {
    tree._ids.putIfAbsent(json['id'], () => this as Child);
  }

  Map<String, dynamic> toJson() =>
      {
        'id': _getIdAsChild(),
        'created': creationDate.millisecondsSinceEpoch,
      };
}

class Parent extends TreeNeeder {
  Set<Child> children = {};

  Parent(SkillTree tree, [this.children]) : super(tree) {
    if (children == null) {
      children = {};
    } else {
      if (tree != null) {
        tree.nodes.addAll(children.where((ch) => ch is Node));
      }
      for (Node n in children) {
        n._parents.add(this);
      }
    }
    this.children = children;
  }

  void addChild(Child n) {
    n._parents.add(this);
    children.add(n);
  }

  Set<Child> getDescendants() {
    Set<Child> out = Set();
    if (children.length > 0) {
      for (Child c in children) {
        if (c is Parent) {
          out.addAll((c as Parent).getDescendants());
        }
        out.add(c);
      }
    }
    return out;
  }

  Parent.fromJson(Map<String, dynamic> json, SkillTree tree) : super.fromJson(json, tree) {
    tree._childMap.putIfAbsent(this, () => List<int>.from(json['children']));
  }
}

class Child { // possible child of multiple things
  Set<Parent> _parents = {};

  Parent getFirstParent() => _parents.first;
  bool hasParent(Parent p) => _parents.contains(p);
  int get numParents => _parents.length;

  Set<Parent> getAscendants() {
    Set<Parent> out = Set();
    if (_parents.length > 0) {
      for (Node n in _parents) {
        out.addAll(n.getAscendants());
        out.add(n);
      }
    }
    return out;
  }

  void clearParents() {
    for (Parent p in _parents) {
      p.children.remove(this);
    }
    _parents.clear();
  }
}

class Node extends Parent with Child { // aka Skill
  String title;
  Offset position;
  bool isDragged = false;

  void unlinkChild(Child n) {
    children.remove(n);
    n._parents.remove(this);
  }

  void unlinkParent(Parent n) {
    _parents.remove(n);
    n.children.remove(this);
  }

  Node({@required String title, @required Offset position, @required SkillTree tree, Set<Node> children}) : super(tree, children) {
    this.title = title;
    this.position = position;
    creationDate = DateTime.now();
  }

  Node.fromJson(Map<String, dynamic> json, SkillTree tree)
      : title = json['title'],
        position = Offset(json['position']['x'], json['position']['y']),
        super.fromJson(json, tree);

  Map<String, dynamic> toJson() => super.toJson()..addAll({
        'title': title,
        'position': {
          'x': position.dx,
          'y': position.dy
        },
        'children': children.map((f) => (f as TreeNeeder)._getIdAsChild()).toList(growable: false),
      });

  void addParent(Node n) {
    n.addChild(this);
  }

  Widget render(BuildContext context, ValueNotifier notifier, SelectionType sel) {
    return Container(
      decoration: BoxDecoration(
          color: nodeColor.withOpacity(isDragged ? 1.0 : 0.75),
          border: Border.all(width: 5,
              color: sel == SelectionType.None ? Color(0x0) : (sel ==
                  SelectionType.Focused ? nodeFocused : nodeSelected)),
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
            padding: EdgeInsets.all(32.0),
            child: Text(title,
              style: TextStyle(
                  color: nodeTitle,
                  fontSize: 20.0
              ),
            ),
          )
      ),
    );
  }

  void displayInfo(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(
        builder: (ctx) => NodeInfo(node: this)
    ));
  }

  bool check = false;

  @override
  String toString() {
    return "Node($title)";
  }

  void remove(bool keepChildren) {
    if (keepChildren) {
      for (Child c in children.toSet()) {
        for (Node p in _parents) {
          p.addChild(c);
        }
      }
    } else {
      for (Child c in children.toSet()) {
        if (c is Node) {
          c.remove(false);
        }
      }
    }
    for (Child c in children.toSet()) {
      c._parents.remove(this);
    }
    children = {};
    for (Node p in _parents) {
      p.children.remove(this);
    }
    tree.nodes.remove(this);
    _parents = null;
  }

  Widget getChildrenInfo(BuildContext context, ValueNotifier notifier) {
    List<Achievement> data = List.from(getDescendants().where((a) => a is Achievement));
    if (data.length == 0) {
      return Text("No connected achievements");
    }
    data.sort((a, b) => b.creationDate.millisecondsSinceEpoch - a.creationDate.millisecondsSinceEpoch);
    return Column(
      children: data.map((d) =>
          ListTile(
            title: Container(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: d.mediaItems.map((mi) => mi.getInfoPreview(context, notifier)).toList(),
              ),
            ),
            onTap: () => {
              Navigator.push(context, MaterialPageRoute(
                builder: (ctx) => EditAchievement(d)
              ))
            },
            leading: Container(
              width: 100,
                child: Text(d.comment, overflow: TextOverflow.fade,)
            ),
          )).toList(),
    );
  }
}


abstract class MediaItem {
  MediaItem();
  
  Map<String, dynamic> _addSpecifics();
  Widget getPostPreview(BuildContext context, ValueNotifier notif);
  Widget getInfoPreview(BuildContext context, ValueNotifier notif);
  String _getType();
  DateTime getLastModified();

  static MediaItem _decipher(Map<String, dynamic> json) {
    switch (json['type']) {
      case ImageItem.TYPENAME: return ImageItem.fromJson(json);
    }
    print("error? no media item created from json");
  }

  Map<String, dynamic> toJson() =>
      {
        'type': _getType(),
      }..addAll(_addSpecifics());
}

abstract class FileMediaItem extends MediaItem {
  File file;

  FileMediaItem(this.file) : super();

  FileMediaItem.fromJson(Map<String, dynamic> json) : file = File(json['path']), super();

  @override
  DateTime getLastModified() {
    return file.lastModifiedSync();
  }

  @override
  Map<String, dynamic> _addSpecifics() => {
    'path': file.path
  };
}

class VideoItem extends FileMediaItem {
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

class AudioItem extends FileMediaItem {
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

class ImageItem extends FileMediaItem {
  static const String TYPENAME = "image";

  ImageItem(File file) : super(file);

  ImageItem.throughUser(BuildContext context, {void Function(ImageItem) whenDone}) : super(null) {
    showDialog(
        context: context,
        builder: (ctx) {
          return SimpleDialog(
            title: Text("Add photo"),
            children: <Widget>[
              IconButton(
                onPressed: () => {
                  getImage(ImageSource.camera, context, null).then(whenDone),
                  Navigator.pop(ctx),
                },
                icon: Icon(Icons.camera),
              ),
              IconButton(
                onPressed: () => {
                  getImage(ImageSource.gallery, context, null).then(whenDone),
                  Navigator.pop(ctx),
                },
                icon: Icon(Icons.photo_library),
              )
            ],
          );
        }
    );
  }

  ImageItem.fromJson(Map<String, dynamic> json) : super.fromJson(json);

  @override
  String _getType() {
    return TYPENAME;
  }

  Future<ImageItem> getImage(ImageSource source, BuildContext context, ValueNotifier notif) async {
    var image = await ImagePicker.pickImage(source: source);
    if (image != null) {
      file = image;
      if (notif != null) {
        notif.value++;
      }
      return this;
    }
    return null;
  }

  @override
  Widget getPostPreview(BuildContext context, ValueNotifier notif) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black,
          width: 1.0
        ),
        borderRadius: BorderRadius.circular(5.0)
      ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Image.file(file, height: 200),
        )
    );
  }

  @override
  Widget getInfoPreview(BuildContext context, ValueNotifier notif) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.0),
      child: Image.file(file, height: 50),
    );
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
                        ]..add(widget.node.getChildrenInfo(context, widget.notif))
                    ),
                  ),
                )
            )
        )
    );
  }
}