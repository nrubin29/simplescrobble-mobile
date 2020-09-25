import 'dart:async';

import 'package:finale/components/image_component.dart';
import 'package:finale/components/loading_component.dart';
import 'package:finale/types/generic.dart';
import 'package:flutter/material.dart';

enum DisplayType { list, grid }

class DisplayComponent<T extends Displayable> extends StatefulWidget {
  final List<T> items;
  final PagedRequest<T> request;
  final Stream<PagedRequest<T>> requestStream;

  final void Function(T item) secondaryAction;

  final DisplayType displayType;
  final bool displayNumbers;
  final bool displayImages;
  final bool displayPeriodSelector;
  final bool displayCircularImages;

  DisplayComponent(
      {Key key,
      this.items,
      this.request,
      this.requestStream,
      this.secondaryAction,
      this.displayType = DisplayType.list,
      this.displayNumbers = false,
      this.displayImages = true,
      this.displayPeriodSelector = false,
      this.displayCircularImages = false})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _DisplayComponentState<T>();
}

class _DisplayComponentState<T extends Displayable>
    extends State<DisplayComponent<T>> with AutomaticKeepAliveClientMixin {
  var items = List<T>();
  int page = 1;
  String period = '7day';
  bool didInitialRequest = false;
  bool hasMorePages = true;

  final _scrollController = ScrollController();

  PagedRequest<T> _request;
  StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();

    if (widget.items != null) {
      items = widget.items;
      didInitialRequest = true;
      return;
    }

    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _getMoreItems();
      }
    });

    if (widget.request != null) {
      _request = widget.request;
      _getInitialItems();
    } else {
      _subscription = widget.requestStream?.listen((newRequest) {
        setState(() {
          _request = newRequest;
          _getInitialItems();
        });
      });
    }
  }

  Future<void> _getInitialItems() async {
    items = [];

    try {
      final initialItems = await _request.doRequest(20, 1, period: period);
      setState(() {
        if (initialItems.isEmpty) {
          hasMorePages = false;
        } else {
          items = initialItems;
          page = 2;
          didInitialRequest = true;
        }
      });
    } catch (_) {
      setState(() {
        hasMorePages = false;
      });
    }
  }

  Future<void> _getMoreItems() async {
    if (!hasMorePages) return;

    try {
      final moreItems = await _request.doRequest(20, page, period: period);
      setState(() {
        if (moreItems.isEmpty) {
          hasMorePages = false;
        } else {
          items.addAll(moreItems);
          page += 1;
        }
      });
    } catch (_) {
      setState(() {
        hasMorePages = false;
      });
    }
  }

  void _onTap(T item) {
    if (item.detailWidget != null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => item.detailWidget));
    }
  }

  Widget _listItemBuilder(BuildContext context, int index) {
    final item = items[index];
    return ListTile(
      visualDensity: VisualDensity.compact,
      title: Text(
          (widget.displayNumbers ? '${index + 1}. ' : '') + item.displayTitle),
      onTap: () {
        _onTap(item);
      },
      subtitle:
          item.displaySubtitle != null ? Text(item.displaySubtitle) : null,
      leading: widget.displayImages
          ? ImageComponent(
              displayable: item,
              quality: ImageQuality.low,
              isCircular: widget.displayCircularImages,
            )
          : null,
      trailing: IntrinsicWidth(
          child: Row(
        children: [
          if (item.displayTrailing != null)
            Text(item.displayTrailing,
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          if (widget.secondaryAction != null)
            IconButton(
                icon: Icon(Icons.add),
                onPressed: () {
                  widget.secondaryAction(item);
                })
        ],
      )),
    );
  }

  Widget _gridTileBuilder(BuildContext context, int index) {
    final item = items[index];
    return GridTile(
      header: widget.secondaryAction != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                    icon: Icon(Icons.add),
                    color: Colors.white,
                    onPressed: () {
                      widget.secondaryAction(item);
                    })
              ],
            )
          : null,
      footer: Container(
          margin: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.displayTitle,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white)),
              if (item.displaySubtitle != null)
                Text(item.displaySubtitle,
                    style: TextStyle(fontSize: 13, color: Colors.white)),
              if (item.displayTrailing != null)
                Text(item.displayTrailing,
                    style: TextStyle(fontSize: 13, color: Colors.white))
            ],
          )),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (widget.displayImages)
            ImageComponent(displayable: item, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
              begin: FractionalOffset.topCenter,
              end: FractionalOffset.bottomCenter,
              colors: [
                Colors.grey.withOpacity(0),
                Colors.black.withOpacity(0.75)
              ],
            )),
          )
        ],
      ),
    );
  }

  Widget _gridItemBuilder(BuildContext context, int index) {
    final item = items[index];

    if (item.detailWidget != null) {
      return InkWell(
          onTap: () {
            _onTap(item);
          },
          child: _gridTileBuilder(context, index));
    }

    return _gridTileBuilder(context, index);
  }

  Widget _mainBuilder(BuildContext context) {
    if (items.isEmpty) {
      // The Stack is a hack to make the RefreshIndicator work.
      return Stack(children: [ListView(), Center(child: Text("No results."))]);
    }

    return CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        shrinkWrap: true,
        controller: _scrollController,
        slivers: [
          if (widget.displayType == DisplayType.list)
            SliverList(
                delegate: SliverChildBuilderDelegate(_listItemBuilder,
                    childCount: items.length)),
          if (widget.displayType == DisplayType.grid)
            SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 250),
                delegate: SliverChildBuilderDelegate(_gridItemBuilder,
                    childCount: items.length)),
          // TODO: If there aren't enough items to fill the screen (i.e. artist
          //  grid on iPad Pro 12.9-inch), the loading indicator shouldn't be
          //  displayed unless the user swipes up - though having to swipe up
          //  when the screen isn't full is kind of awkward.
          if (_request != null && hasMorePages)
            SliverToBoxAdapter(
                child: ListTile(
                    leading: CircularProgressIndicator(),
                    title: Text('Loading...')))
        ]);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!didInitialRequest) {
      return LoadingComponent();
    }

    return RefreshIndicator(
        onRefresh: _getInitialItems,
        child: widget.displayPeriodSelector
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.only(right: 10),
                    child: DropdownButton<String>(
                      value: period,
                      items: {
                        '7 days': '7day',
                        '1 month': '1month',
                        '3 months': '3month',
                        '6 months': '6month',
                        '12 months': '12month',
                        'Overall': 'overall'
                      }
                          .entries
                          .map((e) => DropdownMenuItem(
                              value: e.value, child: Text(e.key)))
                          .toList(),
                      onChanged: (value) {
                        if (value != period) {
                          setState(() {
                            period = value;
                            _getInitialItems();
                          });
                        }
                      },
                    ),
                  ),
                  Expanded(child: _mainBuilder(context))
                ],
              )
            : _mainBuilder(context));
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _subscription?.cancel();
  }

  @override
  bool get wantKeepAlive => true;
}
