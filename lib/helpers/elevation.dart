import 'package:flutter/material.dart';

extension Elevate on Widget {
  Elevated elevate(num i) => Elevation(
    child: this,
    elevation: i,
  );
}

abstract class Elevated {
  const Elevated({required this.elevation});
  final num elevation;
  Widget call();
}

class Elevation extends Elevated {
  const Elevation({elevation, required this.child}) : super(elevation: elevation);
  final Widget child;

  @override
  Widget call() => child;
}

abstract class AxisZInterface<T extends Elevated> {
  const AxisZInterface(this.childrenZ);
  final List<T> childrenZ;
}

class StackZ extends Stack implements AxisZInterface<Elevation> {
  StackZ({required this.childrenZ}) : super();
  @override
  final List<Elevation> childrenZ;

  @override
  List<Widget> get children {
    childrenZ.sort((a, b) => a.elevation.compareTo(b.elevation));
    return <Widget>[for (Elevated e in childrenZ) e()];
  }
}
