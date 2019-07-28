import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:skilitri/theme.dart';
import 'package:skilitri/tree.dart';

import 'main.dart';

class EditAchievement extends StatefulWidget {
  final AchievementNode achievement;

  EditAchievement(this.achievement);

  @override
  _EditAchievementState createState() => _EditAchievementState();
}

class _EditAchievementState extends State<EditAchievement> {
  TextEditingController _comment;

  @override
  initState() {
    _comment = TextEditingController(text: widget.achievement.title);
    super.initState();
  }

  void eventuallyAddItem(MediaItem mi) {
    if (mi != null) {
      widget.achievement.addItem(mi);
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () {
        if (widget.achievement.title == "" && !widget.achievement.hasItems) {
          print("deleting because of no comment");
          widget.achievement.remove(false);
          Navigator.pop(context, true);
        } else {
          Navigator.pop(context);
        }
        return Future<bool>.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text("Edit achievement"),
        ),
        body: Container(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  TextField(
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    controller: _comment,
                    onChanged: (s) => {widget.achievement.title = clearEnd(s)},
                    onEditingComplete: () =>
                        {_comment.text = clearEnd(_comment.text)},
                    decoration: InputDecoration(hintText: "Add a comment..."),
                  ),
                  Divider(),
                  buildMediaCol(),
                  Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      IconButton(
                        onPressed: () => {
                          ImageItem.throughUser(context).then(eventuallyAddItem)
                        },
                        icon: Icon(Icons.image),
                      ),
                      IconButton(
                        onPressed: () => {
                          //widget.achievement.mediaItems.add(VideoItem.throughUser(context))
                        },
                        icon: Icon(Icons.videocam),
                      ),
                      IconButton(
                        onPressed: () => {
                          AudioItem.throughUser(context).then(eventuallyAddItem)
                        },
                        icon: Icon(Icons.mic),
                      ),
                      IconButton(
                        onPressed: () => {
                          //widget.achievement.mediaItems.add(VideoItem.throughUser(context))
                        },
                        icon: Icon(Icons.insert_drive_file),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
        persistentFooterButtons: <Widget>[
          FlatButton(
            shape: StadiumBorder(),
            child: Text("Delete", style: TextStyle(color: invalid)),
            onPressed: () => {
              widget.achievement.remove(false),
              Navigator.pop(context, true)
            },
          ),
          FlatButton(
            shape: StadiumBorder(),
            child: Row(
              children: <Widget>[
                Icon(Icons.link),
                Text(
                    "${widget.achievement.getAscendants().length} (${widget.achievement.numParents}) connections")
              ],
            ),
            onPressed: () => {
              AudioItem.maybeShutUp(),
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (ctx) =>
                          LinkAchievement(achievement: widget.achievement)))
            },
          ),
        ],
      ),
    );
  }

  ValueNotifier notif = ValueNotifier(0);

  Widget buildMediaCol() {
    if (!widget.achievement.hasItems) {
      return Text("No media");
    }
    return AnimatedBuilder(
        animation: notif,
        builder: (ctx, child) {
          return Column(
            children: widget.achievement
                .copyItems()
                .map((mi) => Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: GestureDetector(
                          onLongPressStart: (details) => {
                                Feedback.forLongPress(context),
                                showDialog(
                                    context: context,
                                    builder: (ctx) {
                                      return AlertDialog(
                                        title: Text("Media item options"),
                                        actions: <Widget>[
                                          FlatButton.icon(
                                            icon: Icon(Icons.delete_forever),
                                            onPressed: () => {
                                              mi.delete(notif: notif),
                                              Navigator.pop(ctx)
                                            },
                                            label: Text("Delete"),
                                          )
                                        ],
                                      );
                                    })
                              },
                          child: mi.getPostPreview(context, notif)),
                    ))
                .toList(),
          );
        });
  }
}

class LinkAchievement extends StatefulWidget {
  final AchievementNode achievement;

  const LinkAchievement({Key key, this.achievement}) : super(key: key);

  @override
  _LinkAchievementState createState() => _LinkAchievementState();
}

class _LinkAchievementState extends State<LinkAchievement> {
  List<ValueNotifier> notifs = [];
  Set<Parent> asc;

  void computeAsc() {
    asc = widget.achievement.getAscendants();
  }

  @override
  Widget build(BuildContext context) {
    computeAsc();

    return Scaffold(
      appBar: AppBar(
        title: Text("Select connections"),
      ),
      body: SkilitriState.instance.buildViewport(
          (n) => {
                if (widget.achievement.hasParent(n))
                  {n.unlinkChild(widget.achievement)}
                else
                  {n.addChild(widget.achievement)},
                computeAsc(),
                notifs[0].value++
              },
          null,
          getSelectionType, (n, child) {
        if (asc.contains(child)) {
          return Colors.white;
        }
        return Colors.black38;
      }, arr: notifs),
      floatingActionButton: FloatingActionButton(
        onPressed: () => {Navigator.pop(context, true)},
        child: Icon(Icons.done),
      ),
    );
  }

  SelectionType getSelectionType(Node n) {
    if (widget.achievement.hasParent(n)) {
      return SelectionType.Focused;
    } else if (asc.contains(n)) {
      return SelectionType.Selected;
    }
    return SelectionType.None;
  }
}
