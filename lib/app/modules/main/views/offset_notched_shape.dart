import 'package:flutter/material.dart';

class OffsetNotchedShape extends NotchedShape {
  final NotchedShape shape;
  final Offset offset;

  const OffsetNotchedShape(this.shape, this.offset);

  @override
  Path getOuterPath(Rect host, Rect? guest) {
    if (guest != null) {
      guest = guest.shift(-offset);
    }
    return shape.getOuterPath(host, guest);
  }
}
