import 'package:flutter/material.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:provider/provider.dart';

class PostCommentScreen extends StatefulWidget {
  const PostCommentScreen(
    this.postType,
    this.commentId, {
    this.opUserId,
    super.key,
  });

  final PostType postType;
  final int commentId;
  final int? opUserId;

  @override
  State<PostCommentScreen> createState() => _PostCommentScreenState();
}

class _PostCommentScreenState extends State<PostCommentScreen> {
  CommentModel? _comment;

  @override
  void initState() {
    super.initState();

    context
        .read<SettingsController>()
        .kbinAPI
        .comments
        .get(widget.postType, widget.commentId)
        .then((value) => setState(() {
              _comment = value;
            }));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Comment${_comment != null ? ' by ${_comment!.user.name}' : ''}'),
      ),
      body: _comment != null
          ? ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: OutlinedButton(
                          onPressed: () async {
                            final parentEntry = await context
                                .read<SettingsController>()
                                .kbinAPI
                                .posts
                                .get(
                                  _comment!.postId,
                                );
                            if (!mounted) return;
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (context) {
                              return PostPage(parentEntry, (newPage) {});
                            }));
                          },
                          child: const Text('Open OP'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: OutlinedButton(
                          onPressed: _comment!.rootId != null
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) {
                                      return PostCommentScreen(
                                        _comment!.postType,
                                        _comment!.rootId!,
                                      );
                                    }),
                                  );
                                }
                              : null,
                          child: const Text('Open Root'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(4),
                        child: OutlinedButton(
                          onPressed: _comment!.parentId != null
                              ? () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) {
                                      return PostCommentScreen(
                                        _comment!.postType,
                                        _comment!.parentId!,
                                      );
                                    }),
                                  );
                                }
                              : null,
                          child: const Text('Open Parent'),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: PostComment(
                    _comment!,
                    (newComment) => setState(() {
                      _comment = newComment;
                    }),
                    opUserId: widget.opUserId,
                  ),
                )
              ],
            )
          : const Center(
              child: CircularProgressIndicator(),
            ),
    );
  }
}
