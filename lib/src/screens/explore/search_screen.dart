import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:interstellar/src/models/comment.dart';
import 'package:interstellar/src/models/old/magazine.dart';
import 'package:interstellar/src/models/old/user.dart';
import 'package:interstellar/src/models/post.dart';
import 'package:interstellar/src/screens/explore/user_screen.dart';
import 'package:interstellar/src/screens/feed/post_comment.dart';
import 'package:interstellar/src/screens/feed/post_comment_screen.dart';
import 'package:interstellar/src/screens/feed/post_item.dart';
import 'package:interstellar/src/screens/feed/post_page.dart';
import 'package:interstellar/src/screens/settings/settings_controller.dart';
import 'package:interstellar/src/utils/utils.dart';
import 'package:interstellar/src/widgets/avatar.dart';
import 'package:interstellar/src/widgets/wrapper.dart';
import 'package:provider/provider.dart';

import 'magazine_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({
    super.key,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String search = "";

  final PagingController<int, dynamic> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    _pagingController.addPageRequestListener(_fetchPage);
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newPage =
          await context.read<SettingsController>().kbinAPI.search.get(
                page: pageKey,
                search: search,
              );

      // Check BuildContext
      if (!mounted) return;

      final isLastPage =
          newPage.pagination.currentPage == newPage.pagination.maxPage;

      if (isLastPage) {
        _pagingController.appendLastPage(newPage.items);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newPage.items, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          initialValue: search,
          onFieldSubmitted: (newSearch) {
            setState(() {
              search = newSearch;
            });
            _pagingController.refresh();
          },
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.all(12),
            border: OutlineInputBorder(),
            label: Text("Search"),
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          PagedSliverList(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<dynamic>(
                itemBuilder: (context, item, index) {
              onClick() {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) {
                    switch (item) {
                      case DetailedUserModel item:
                        return UserScreen(
                          item.userId,
                          initData: item,
                          onUpdate: (newValue) {
                            var newList = _pagingController.itemList;
                            newList![index] = newValue;
                            setState(() {
                              _pagingController.itemList = newList;
                            });
                          },
                        );
                      case DetailedMagazineModel item:
                        return MagazineScreen(
                          item.magazineId,
                          initData: item,
                          onUpdate: (newValue) {
                            var newList = _pagingController.itemList;
                            newList![index] = newValue;
                            setState(() {
                              _pagingController.itemList = newList;
                            });
                          },
                        );
                      case PostModel item:
                        return PostPage(item, (newValue) {
                          var newList = _pagingController.itemList;
                          newList![index] = newValue;
                          setState(() {
                            _pagingController.itemList = newList;
                          });
                        });
                      case CommentModel item:
                        return PostCommentScreen(item.postType, item.id);
                      case _:
                        throw "Unrecognized search item";
                    }
                  }),
                );
              }

              return Wrapper(
                shouldWrap: item is! CommentModel,
                parentBuilder: (child) => Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(onTap: onClick, child: child),
                ),
                child: switch (item) {
                  PostModel item => PostItem(
                      item,
                      (newValue) {
                        var newList = _pagingController.itemList;
                        newList![index] = newValue;
                        setState(() {
                          _pagingController.itemList = newList;
                        });
                      },
                    ),
                  CommentModel item => Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      child: PostComment(
                        item,
                        (newValue) {
                          var newList = _pagingController.itemList;
                          newList![index] = newValue;
                          setState(() {
                            _pagingController.itemList = newList;
                          });
                        },
                        onClick: onClick,
                      ),
                    ),
                  DetailedUserModel item => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        if (item.avatar?.storageUrl != null)
                          Avatar(
                            item.avatar!.storageUrl,
                            radius: 16,
                          ),
                        Container(
                            width:
                                8 + (item.avatar?.storageUrl != null ? 0 : 32)),
                        Expanded(
                            child: Text(item.username,
                                overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: ButtonStyle(
                            foregroundColor: MaterialStatePropertyAll(
                                item.isFollowedByUser == true
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : null),
                          ),
                          onPressed: whenLoggedIn(context, () async {
                            var newValue = await context
                                .read<SettingsController>()
                                .kbinAPI
                                .users
                                .putFollow(
                                    item.userId, !item.isFollowedByUser!);
                            var newList = _pagingController.itemList;
                            newList![index] = newValue;
                            setState(() {
                              _pagingController.itemList = newList;
                            });
                          }),
                          child: Row(
                            children: [
                              const Icon(Icons.group),
                              Text(' ${intFormat(item.followersCount)}'),
                            ],
                          ),
                        )
                      ]),
                    ),
                  DetailedMagazineModel item => Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        if (item.icon?.storageUrl != null)
                          Avatar(item.icon!.storageUrl, radius: 16),
                        Container(
                            width:
                                8 + (item.icon?.storageUrl != null ? 0 : 32)),
                        Expanded(
                            child: Text(item.name,
                                overflow: TextOverflow.ellipsis)),
                        const Icon(Icons.feed),
                        Container(
                          width: 4,
                        ),
                        Text(intFormat(item.entryCount)),
                        const SizedBox(width: 12),
                        const Icon(Icons.comment),
                        Container(
                          width: 4,
                        ),
                        Text(intFormat(item.entryCommentCount)),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          style: ButtonStyle(
                            foregroundColor: MaterialStatePropertyAll(
                                item.isUserSubscribed == true
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primaryContainer
                                    : null),
                          ),
                          onPressed: whenLoggedIn(context, () async {
                            var newValue = await context
                                .read<SettingsController>()
                                .kbinAPI
                                .magazines
                                .putSubscribe(
                                    item.magazineId, !item.isUserSubscribed!);
                            var newList = _pagingController.itemList;
                            newList![index] = newValue;
                            setState(() {
                              _pagingController.itemList = newList;
                            });
                          }),
                          child: Row(
                            children: [
                              const Icon(Icons.group),
                              Text(' ${intFormat(item.subscriptionsCount)}'),
                            ],
                          ),
                        )
                      ]),
                    ),
                  _ => const Text("Unknown"),
                },
              );
            }),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
