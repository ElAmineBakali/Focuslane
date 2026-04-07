class RouteIntent {
  const RouteIntent({
    required this.route,
    this.arguments,
    this.replace = false,
  });

  final String route;
  final Object? arguments;
  final bool replace;
}
