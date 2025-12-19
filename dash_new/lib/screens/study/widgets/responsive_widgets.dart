import 'package:flutter/material.dart';

 extension SafeAreaExt on BuildContext {
  double get safeAreaBottomPadding =>
      MediaQuery.of(this).viewPadding.bottom > 0
          ? MediaQuery.of(this).viewPadding.bottom
          : 16;

  double get safeAreaTopPadding =>
      MediaQuery.of(this).viewPadding.top > 0
          ? MediaQuery.of(this).viewPadding.top
          : 0;

  bool get hasNotch =>
      MediaQuery.of(this).viewPadding.top > 24;

  bool get hasNavigationBar =>
      MediaQuery.of(this).viewPadding.bottom > 0;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;
}

 class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final double horizontal;
  final double vertical;
  final bool includeBottom;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.horizontal = 12,
    this.vertical = 12,
    this.includeBottom = false,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = includeBottom ? context.safeAreaBottomPadding : 0;
    return Padding(
      padding: EdgeInsets.only(
        left: horizontal,
        right: horizontal,
        top: vertical,
        bottom: vertical + bottomPadding,
      ),
      child: child,
    );
  }
}

 class ResponsiveListView extends StatelessWidget {
  final ScrollPhysics? physics;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final double padding;
  final bool shrinkWrap;
  final ScrollController? controller;

  const ResponsiveListView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding = 12,
    this.physics,
    this.shrinkWrap = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = context.safeAreaBottomPadding;
    
    if (separatorBuilder != null) {
      return ListView.separated(
        physics: physics,
        controller: controller,
        padding: EdgeInsets.only(
          left: padding,
          right: padding,
          top: padding,
          bottom: padding + bottomPadding,
        ),
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder!,
        shrinkWrap: shrinkWrap,
      );
    }

    return ListView.builder(
      physics: physics,
      controller: controller,
      padding: EdgeInsets.only(
        left: padding,
        right: padding,
        top: padding,
        bottom: padding + bottomPadding,
      ),
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      shrinkWrap: shrinkWrap,
    );
  }
}

 class ResponsiveCustomScrollView extends StatelessWidget {
  final List<Widget> slivers;
  final ScrollPhysics? physics;
  final ScrollController? controller;

  const ResponsiveCustomScrollView({
    super.key,
    required this.slivers,
    this.physics,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = context.safeAreaBottomPadding;
    
    return CustomScrollView(
      physics: physics,
      controller: controller,
      slivers: [
        ...slivers,
                 SliverToBoxAdapter(
          child: SizedBox(height: bottomPadding),
        ),
      ],
    );
  }
}

 class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final double elevation;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.elevation = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}
