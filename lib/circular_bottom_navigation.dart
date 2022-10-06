library circular_bottom_navigation;

import 'dart:core';
import 'dart:math';

import 'package:circular_bottom_navigation/tab_item.dart';
import 'package:flutter/material.dart';

typedef CircularBottomNavSelectedCallback = Function(int? selectedPos);

class CircularBottomNavigation extends StatefulWidget {
  final List<TabItem> tabItems;
  final int selectedPos;
  final int lengthOfCart;
  final double barHeight;
  final Color barBackgroundColor;
  final double circleSize;
  final double circleStrokeWidth;
  final double iconsSize;
  final Color selectedIconColor;
  final Color unSelectedIconColor;
  final Color normalIconColor;
  final Duration animationDuration;
  final List<BoxShadow>? backgroundBoxShadow;
  final TextStyle cartStyle;
  final CircularBottomNavSelectedCallback? selectedCallback;
  final CircularBottomNavigationController? controller;

  CircularBottomNavigation(
    this.tabItems, {
    this.selectedPos = 0,
    this.barHeight = 60,
    this.barBackgroundColor = Colors.white,
    this.circleSize = 58,
    this.circleStrokeWidth = 4,
    this.iconsSize = 32,
    this.selectedIconColor = Colors.white,
    this.normalIconColor = Colors.grey,
    this.animationDuration = const Duration(milliseconds: 300),
    this.selectedCallback,
    this.controller,
        this.cartStyle=const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
        this.lengthOfCart=2, this.unSelectedIconColor = Colors.white,
    backgroundBoxShadow,
  })  : backgroundBoxShadow = backgroundBoxShadow ?? [const BoxShadow(color: Colors.grey, blurRadius: 2.0)],
        assert(tabItems.length != 0, "tabItems is required");

  @override
  State<StatefulWidget> createState() => _CircularBottomNavigationState();
}

class _CircularBottomNavigationState extends State<CircularBottomNavigation> with TickerProviderStateMixin {
  Curve _animationsCurve = const Cubic(0.27, 1.21, .77, 1.09);

  late AnimationController itemsController;
  late Animation<double> selectedPosAnimation;
  late Animation<double> itemsAnimation;
  late List<double> _itemsSelectedState;
  int? selectedPos;
  int? previousSelectedPos;
  CircularBottomNavigationController? _controller;


  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller;
      previousSelectedPos = selectedPos = _controller!.value;
    } else {
      previousSelectedPos = selectedPos = widget.selectedPos;
      _controller = CircularBottomNavigationController(selectedPos);
    }

    _controller!.addListener(_newSelectedPosNotify);

    _itemsSelectedState = List.generate(widget.tabItems.length, (index) {
      return selectedPos == index ? 1.0 : 0.0;
    });

    itemsController = AnimationController(vsync: this, duration: widget.animationDuration);
    itemsController.addListener(() {
      setState(() {
        _itemsSelectedState.asMap().forEach((i, value) {
          if (i == previousSelectedPos) {
            _itemsSelectedState[previousSelectedPos!] = 1.0 - itemsAnimation.value;
          } else if (i == selectedPos) {
            _itemsSelectedState[selectedPos!] = itemsAnimation.value;
          } else {
            _itemsSelectedState[i] = 0.0;
          }
        });
      });
    });

    selectedPosAnimation = makeSelectedPosAnimation(selectedPos!.toDouble(), selectedPos!.toDouble());

    itemsAnimation =
        Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: itemsController, curve: _animationsCurve));
  }

  Animation<double> makeSelectedPosAnimation(double begin, double end) {
    return Tween(begin: begin, end: end).animate(CurvedAnimation(parent: itemsController, curve: _animationsCurve));
  }

  void onSelectedPosAnimate() {
    setState(() {});
  }

  void _newSelectedPosNotify() {
    _setSelectedPos(widget.controller!.value);
  }

  @override
  Widget build(BuildContext context) {
    double maxShadowHeight = (widget.backgroundBoxShadow ?? []).isNotEmpty
        ? widget.backgroundBoxShadow!.map((e) => e.blurRadius).reduce(max)
        : 0.0;
    double fullWidth = MediaQuery.of(context).size.width;
    double fullHeight = widget.barHeight + (widget.circleSize / 2) + widget.circleStrokeWidth + maxShadowHeight;
    double sectionsWidth = fullWidth / widget.tabItems.length;

    //Create the boxes Rect
    List<Rect> boxes = [];
    widget.tabItems.asMap().forEach((i, tabItem) {
      double left = i * sectionsWidth;
      double top = fullHeight - widget.barHeight;
      double right = left + sectionsWidth;
      double bottom = fullHeight;
      boxes.add(Rect.fromLTRB(left, top, right, bottom));
    });

    List<Widget> children = [];

    // This is the full view transparent background (have free space for circle)
    children.add(SizedBox(
      width: fullWidth,
      height: fullHeight,
    ));

    // This is the bar background (bottom section of our view)
    children.add(
      Positioned(
        child: Container(
          width: fullWidth,
          height: widget.barHeight,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10)),
            color: const Color(0xFF3DCEA6),
            boxShadow: widget.backgroundBoxShadow,
          ),
        ),
        top: fullHeight - widget.barHeight,
        left: 0,
      ),
    );

    // This is the circle handle
    children.add(
      Positioned(
        child: Container(
          width: widget.circleSize,
          height: widget.circleSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
              border: Border.fromBorderSide(
                BorderSide(color: Colors.black12),
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.black45, blurRadius:1 , spreadRadius: -1),
                BoxShadow(color: Colors.white, blurRadius: 5, spreadRadius: -1),
              ]),
        ),
        left: (selectedPosAnimation.value * sectionsWidth) + (sectionsWidth / 2) - (widget.circleSize / 2),
        top: maxShadowHeight,
      ),
    );

    //Here are the Icons and texts of items
    boxes.asMap().forEach((int pos, Rect r) {
      // Icon
      Color iconColor = pos == selectedPos ? widget.selectedIconColor : widget.normalIconColor;
      double scaleFactor = pos == selectedPos ? 1.0 : 1.0;
      children.add(
        Positioned(
          child: Transform.scale(
            scale: scaleFactor,
            child: Column(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      widget.tabItems[pos].icon,
                      size: widget.iconsSize,
                      color: iconColor,
                    ),
                    pos==0?Positioned(
                      right: -2,
                      top: -5,
                      child: widget.lengthOfCart>0?Container(height: 17,width: 17,decoration: BoxDecoration(
                          color: iconColor,borderRadius: BorderRadius.circular(12)
                      ),
                        child: Padding(
                          padding: const EdgeInsets.all(1.0),
                          child: Center(child: Text(
                              '${widget.lengthOfCart}',style:TextStyle(color: pos == selectedPos?Colors.white:widget.selectedIconColor,fontSize: 12,fontWeight: FontWeight.bold))),
                        ),
                      ):Offstage()
                    ):  Offstage()
                  ],
                ),
                pos == selectedPos? const Offstage():  Center(
                  child: Text(
                    widget.tabItems[pos].title,
                    textAlign: TextAlign.center,
                    style: widget.tabItems[pos].labelStyle.copyWith(fontSize: 12,color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
          left: r.center.dx - (widget.iconsSize / 2),
          top: r.center.dy -
              (widget.iconsSize /1.6) -
              (_itemsSelectedState[pos] * (pos==0?(widget. barHeight / 2.3) :(widget. barHeight / 2.1) + widget.circleStrokeWidth)),
        ),
      );

      // Text
      double textHeight = fullHeight - widget.circleSize;
      double opacity = _itemsSelectedState[pos];
      if (opacity < 0.0) {
        opacity = 0.0;
      } else if (opacity > 1.0) {
        opacity = 1.0;
      }
      children.add(Positioned(
        child: SizedBox(
          width: r.width,
          height: textHeight,
          child: Center(
            child: Text(
              widget.tabItems[pos].title,
              textAlign: TextAlign.center,
              style: widget.tabItems[pos].labelStyle,
            ),
          ),
        ),
        left: r.left,
        top: r.top +
            (widget.circleSize / 2) -
            (widget.circleStrokeWidth * 2) +
            ((1.0 - _itemsSelectedState[pos]) * textHeight),
      ));

      if (pos != selectedPos) {
        children.add(
          Positioned.fromRect(
            child: GestureDetector(
              onTap: () {
                _controller!.value = pos;
              },
            ),
            rect: r,
          ),
        );
      }
    });

    return Stack(
      clipBehavior: Clip.none,
      children: children,
    );
  }

  void _setSelectedPos(int? pos) {
    previousSelectedPos = selectedPos;
    selectedPos = pos;

    itemsController.forward(from: 0.0);

    selectedPosAnimation = makeSelectedPosAnimation(previousSelectedPos!.toDouble(), selectedPos!.toDouble());
    selectedPosAnimation.addListener(onSelectedPosAnimate);

    if (widget.selectedCallback != null) {
      widget.selectedCallback!(selectedPos);
    }
  }

  @override
  void dispose() {
    super.dispose();
    itemsController.dispose();
    _controller!.removeListener(_newSelectedPosNotify);
  }
}

class CircularBottomNavigationController extends ValueNotifier<int?> {
  CircularBottomNavigationController(int? value) : super(value);
}
