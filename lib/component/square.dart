import 'package:chessgame/component/piece.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../values/colors.dart';

class Square extends StatelessWidget {
  final bool isWhite;
  final ChessPiece? piece;
  final bool isSelected;
  final bool isValidMoves;
  final void Function()? onTap;

  const Square({
    super.key,
    required this.isWhite,
    required this.piece,
    required this.isSelected,
    required this.isValidMoves,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color? squareColor;

    //if selected, square is green
    if (isSelected) {
      squareColor = Colors.green;
    } else if (isValidMoves) {
      squareColor = Colors.green.shade300;
    } else {
      squareColor = isWhite ? Color(0xFF928C8C) : Color(0xFF964D22);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: squareColor,
        margin: EdgeInsets.all(isValidMoves ? 8 : 0),
        child: piece != null
            ? Image.asset(
                piece!.imagePath,
                color: piece!.isWhite ? Colors.white : Colors.black,
              )
            : null,
      ),
    );
  }
}
