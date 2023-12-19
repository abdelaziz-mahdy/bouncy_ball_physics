class CustomOffset{
  double dx;
  double dy;
  CustomOffset(this.dx,this.dy);
  /// Binary addition operator.
  ///
  /// Returns an offset whose [dx] value is the sum of the [dx] values of the
  /// two operands, and whose [dy] value is the sum of the [dy] values of the
  /// two operands.
  ///
  /// See also [translate].
  CustomOffset operator +(CustomOffset other) => CustomOffset(dx + other.dx, dy + other.dy);

}

class CustomSize{
  double width;
  double height;
  CustomSize(this.width,this.height);
}