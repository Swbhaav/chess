
import 'package:chessgame/component/piece.dart';
import 'package:chessgame/component/square.dart';
import 'package:chessgame/helper/helper.dart';

import 'package:chessgame/pages/authPages/login.dart';
import 'package:chessgame/pages/authPages/register.dart';
import 'package:chessgame/services/auth/auth_service.dart';
import 'package:chessgame/values/colors.dart';
import 'package:flutter/material.dart';

import 'component/dead_piece.dart';

class GameBoard extends StatefulWidget {
  GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  AuthService _authService = AuthService();
  //Creating a game Board using 2D list
  late List<List<ChessPiece?>> board;

  //The Currently selected piece
  ChessPiece? selectedPiece;

  //When nothing is selected
  int selectedRow = -1;
  int selectedCol = -1;

  // List of valid moves for current piece
  // each move is represented as list of 2 elements: row and column
  List<List<int>> validMoves = [];

  // A list of taken white pieces
  List<ChessPiece> whitePieceTaken = [];

  // A list of taken black pieces
  List<ChessPiece> blackPieceTaken = [];

  // A boolean to indicate whose turn it is
  bool isWhiteTurn = true;

  //initial position of kings (keep track of this to make later to see if checkmate)
  List<int> whiteKingPosition = [7, 4];
  List<int> blackKingPosition = [0, 4];
  bool checkStatus = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  // INITIALIZE BOARD
  void _initializeBoard() {
    // Initializing the board with nulls
    List<List<ChessPiece?>> newBoard = List.generate(
      8,
      (index) => List.generate(8, (index) => null),
    );

    // Pawn Place
    for (int i = 0; i < 8; i++) {
      newBoard[1][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: false,
        imagePath: 'lib/images/white-pawn.png',
      );

      newBoard[6][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: true,
        imagePath: 'lib/images/white-pawn.png',
      );
    }

    //Rook Position
    newBoard[0][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      imagePath: 'lib/images/white-rook.png',
    );
    newBoard[0][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      imagePath: 'lib/images/white-rook.png',
    );
    newBoard[7][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      imagePath: 'lib/images/white-rook.png',
    );
    newBoard[7][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      imagePath: 'lib/images/white-rook.png',
    );

    //Knight Position
    newBoard[0][1] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.knight,
      imagePath: 'lib/images/white-knight.png',
    );
    newBoard[0][6] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.knight,
      imagePath: 'lib/images/white-knight.png',
    );
    newBoard[7][1] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.knight,
      imagePath: 'lib/images/white-knight.png',
    );
    newBoard[7][6] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.knight,
      imagePath: 'lib/images/white-knight.png',
    );

    // Place Bishop
    newBoard[0][2] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/white-bishop.png',
    );
    newBoard[0][5] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/white-bishop.png',
    );
    newBoard[7][2] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/white-bishop.png',
    );
    newBoard[7][5] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/white-bishop.png',
    );

    //Place Queens
    newBoard[0][3] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.queen,
      imagePath: 'lib/images/white-queen.png',
    );

    newBoard[7][3] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.queen,
      imagePath: 'lib/images/white-queen.png',
    );

    //Place king
    newBoard[0][4] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.king,
      imagePath: 'lib/images/white-king.png',
    );
    newBoard[7][4] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.king,
      imagePath: 'lib/images/white-king.png',
    );

    board = newBoard;
  }

  // USER SELECTED A PIECE
  void pieceSelected(int row, int col) {
    setState(() {
      // No piece has been selected yet, this is the first selection
      if (selectedPiece == null && board[row][col] != null) {
        if (board[row][col]!.isWhite == isWhiteTurn) {
          selectedPiece = board[row][col];
          selectedRow = row;
          selectedCol = col;
          validMoves = calculateRealValidMoves(row, col, selectedPiece, true);
          // If in check, filter moves that don't actually get out of check
          if (checkStatus) {
            validMoves = validMoves.where((move) {
              return simulatedMoveIsSafe(
                selectedPiece!,
                row,
                col,
                move[0],
                move[1],
              );
            }).toList();
          }
        }
      }
      // There is a piece already selected, but user can select another one of their pieces
      else if (board[row][col] != null &&
          board[row][col]!.isWhite == selectedPiece?.isWhite) {
        selectedPiece = board[row][col];
        selectedRow = row;
        selectedCol = col;
        validMoves = calculateRealValidMoves(row, col, selectedPiece, true);
      }
      //if there is a piece selected and user taps on a square that is valid move, move
      else if (selectedPiece != null &&
          validMoves.any((element) => element[0] == row && element[1] == col)) {
        movePiece(row, col);
      }
    });
  }

  // Calculating Raw valid moves
  List<List<int>> calculateRawValidMoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];

    if (piece == null) {
      return [];
    }

    // different directions based on their color
    int direction = piece!.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPieceType.pawn:
        // Pawns can move forward if the square is not occupied
        if (isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          candidateMoves.add([row + direction, col]);
        }

        // pawns can move 2 square forward if they are at their initial positions
        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (isInBoard(row + 2 * direction, col) &&
              board[row + 2 * direction][col] == null) {
            candidateMoves.add([row + 2 * direction, col]);
          }
        }

        // pawns can kill diagonally
        if (isInBoard(row + direction, col - 1) &&
            board[row + direction][col - 1] != null &&
            board[row + direction][col - 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col - 1]);
        }
        if (isInBoard(row + direction, col + 1) &&
            board[row + direction][col + 1] != null &&
            board[row + direction][col + 1]!.isWhite != piece.isWhite) {
          candidateMoves.add([row + direction, col + 1]);
        }

        break;
      case ChessPieceType.rook:
        // Horizontal and vertical direction
        var directions = [
          [-1, 0], // up
          [1, 0], //down
          [0, -1], //left
          [0, 1], //right
        ];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            //checking if there is another piece
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); // kill
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.knight:
        var KnightMoves = [
          [-2, -1], // up 2 left 1
          [-2, 1], // up 2 right 1
          [-1, -2], // up 1 left 2
          [-1, 2], // up 1 right 2
          [1, -2], // down 1 left 2
          [1, 2], //down 1 right 2
          [2, -1], // down 2 left 1
          [2, 1], //down2 right 1
        ];

        for (var move in KnightMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]); // Capture
            }
            continue; //Blocked by our piece
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;
      case ChessPieceType.bishop:
        var directions = [
          [-1, -1], // up left
          [-1, 1], //up right
          [1, -1], //down left
          [1, 1], //down right
        ];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }
            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]);
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }

        break;
      case ChessPieceType.queen:
        //all eight directions : up, down, left, right, and all 4 diagonals
        var directions = [
          [-1, 0], //up
          [1, 0], // down
          [0, -1], // left
          [0, 1], //right
          [-1, -1], // up left
          [-1, 1], // up right
          [1, -1], // down left
          [1, 1], // down right
        ];

        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) {
              break;
            }

            if (board[newRow][newCol] != null) {
              if (board[newRow][newCol]!.isWhite != piece.isWhite) {
                candidateMoves.add([newRow, newCol]); //capture
              }
              break;
            }
            candidateMoves.add([newRow, newCol]);
            i++;
          }
        }
        break;
      case ChessPieceType.king:
        var directions = [
          [-1, 0], //up
          [1, 0], // down
          [0, -1], // left
          [0, 1], //right
          [-1, -1], // up left
          [-1, 1], // up right
          [1, -1], // down left
          [1, 1], // down right
        ];

        for (var direction in directions) {
          var newRow = row + direction[0];
          var newCol = col + direction[1];
          if (!isInBoard(newRow, newCol)) {
            continue;
          }
          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]);
            }
            continue;
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;

      default:
    }
    return candidateMoves;
  }

  // Calculate real valid move
  List<List<int>> calculateRealValidMoves(
    int row,
    int col,
    ChessPiece? piece,
    bool checkSimulation,
  ) {
    List<List<int>> realValidMoves = [];
    List<List<int>> candidateMoves = calculateRawValidMoves(row, col, piece);

    // after generating all candidate moves, filter out any that would result in a check
    if (checkSimulation) {
      for (var move in candidateMoves) {
        int endRow = move[0];
        int endCol = move[1];
        // this will simulate if it's safe
        if (simulatedMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realValidMoves.add(move);
        }
      }
    } else {
      realValidMoves = candidateMoves;
    }
    return realValidMoves;
  }

  void movePiece(int newRow, int newCol) {
    // Capture logic remains the same
    if (board[newRow][newCol] != null) {
      var capturedPiece = board[newRow][newCol];
      if (capturedPiece!.isWhite) {
        whitePieceTaken.add(capturedPiece);
      } else {
        blackPieceTaken.add(capturedPiece);
      }
    }

    // King position update
    if (selectedPiece!.type == ChessPieceType.king) {
      if (selectedPiece!.isWhite) {
        whiteKingPosition = [newRow, newCol];
      } else {
        blackKingPosition = [newRow, newCol];
      }
    }

    // Make the move
    board[newRow][newCol] = selectedPiece;
    board[selectedRow][selectedCol] = null;

    // Check for check/checkmate
    bool opponentInCheck = isInCheck(!isWhiteTurn);
    bool opponentCheckmate = opponentInCheck && isCheckmate(!isWhiteTurn);

    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
      checkStatus = opponentInCheck;
    });

    isWhiteTurn = !isWhiteTurn;

    // Show game over if checkmate
    if (opponentCheckmate) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("CHECKMATE!"),
          content: Text(selectedPiece!.isWhite ? "White wins!" : "Black wins!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
              child: const Text('Play Again'),
            ),
          ],
        ),
      );
    } else if (opponentInCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Check!"), duration: Duration(seconds: 2)),
      );
    }
  }

  bool squareIsAttacked(int row, int col, bool byWhite) {
    for (int r = 0; r < 8; r++) {
      for (int c = 0; c < 8; c++) {
        ChessPiece? piece = board[r][c];
        if (piece != null && piece.isWhite == byWhite) {
          List<List<int>> moves = calculateRawValidMoves(r, c, piece);
          for (var move in moves) {
            if (move[0] == row && move[1] == col) {
              return true;
            }
          }
        }
      }
    }
    return false;
  }

  //Checking if king is in check
  bool isInCheck(bool isWhite) {
    // Find king position
    List<int> kingPos = isWhite ? whiteKingPosition : blackKingPosition;

    // If the king's square is attacked by the opponent → in check
    return squareIsAttacked(kingPos[0], kingPos[1], !isWhite);
  }

  //Simulate a future move to see if it's safe (Doesn't put your own king under Attack!)
  bool simulatedMoveIsSafe(
    ChessPiece piece,
    int startRow,
    int startCol,
    int endRow,
    int endCol,
  ) {
    //Save the current board state
    ChessPiece? originalDestinationPiece = board[endRow][endCol];
    //if the piece is the king, save it's current position and update to the new one
    List<int>? originalKingPosition;
    if (piece.type == ChessPieceType.king) {
      originalKingPosition = piece.isWhite
          ? whiteKingPosition
          : blackKingPosition;

      // update the king position
      if (piece.isWhite) {
        whiteKingPosition = [endRow, endCol];
      } else {
        blackKingPosition = [endRow, endCol];
      }
    }
    // simulate the move
    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    // check if our king is under attack
    bool kingInCheck = isInCheck(piece.isWhite);

    //restore board to original state
    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    //if the piece was the king, restore it original position
    if (piece.type == ChessPieceType.king) {
      if (piece.isWhite) {
        whiteKingPosition = originalKingPosition!;
      } else {
        blackKingPosition = originalKingPosition!;
      }
    }

    //if king is in check = true, means it's not a safe move. safe move =false
    return !kingInCheck;
  }

  //check if check mate
  bool isCheckmate(bool isWhite) {
    // Must be in check to be checkmate
    if (!isInCheck(isWhite)) return false;

    // Check all pieces of current color
    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];
        if (piece == null || piece.isWhite != isWhite) continue;

        // Get all possible moves for this piece
        List<List<int>> moves = calculateRealValidMoves(row, col, piece, true);

        // Test each move to see if it gets out of check
        for (var move in moves) {
          // Simulate the move
          ChessPiece? original = board[move[0]][move[1]];
          List<int>? originalKingPos;

          if (piece.type == ChessPieceType.king) {
            originalKingPos = isWhite
                ? List.from(whiteKingPosition)
                : List.from(blackKingPosition);

            if (isWhite)
              whiteKingPosition = [move[0], move[1]];
            else
              blackKingPosition = [move[0], move[1]];
          }

          board[move[0]][move[1]] = piece;
          board[row][col] = null;

          bool stillInCheck = isInCheck(isWhite);

          // Undo the move
          board[row][col] = piece;
          board[move[0]][move[1]] = original;

          if (piece.type == ChessPieceType.king) {
            if (isWhite)
              whiteKingPosition = originalKingPos!;
            else
              blackKingPosition = originalKingPos!;
          }

          // If any move gets out of check, not checkmate
          if (!stillInCheck) return false;
        }
      }
    }

    // No moves get out of check - it's checkmate
    return true;
  }

  //Reset To new Game
  void resetGame() {
    Navigator.pop(context);
    _initializeBoard();
    checkStatus = false;
    whitePieceTaken.clear();
    blackPieceTaken.clear();
    whiteKingPosition = [7, 4];
    blackKingPosition = [0, 4];
    isWhiteTurn = true;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.grey[500],
        title: Text('Chess Game'),
        elevation: 0,

        toolbarHeight: 32,
        actions: [
          IconButton(onPressed: () => delete(context), icon: Icon(Icons.delete)),
          IconButton(
            onPressed: () => logout(context),
            icon: Icon(Icons.logout),
          ),

        ],
      ),
      body: Column(
        children: [
          //White pieces taken
          Expanded(
            child: GridView.builder(
              itemCount: whitePieceTaken.length,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) => DeadPieces(
                imagePath: whitePieceTaken[index].imagePath,
                isWhite: true,
              ),
            ),
          ),

          //Game Status
          Text(checkStatus ? 'check' : ''),

          //Chess Board
          Expanded(
            // This flex property allows us to make this expanded 3X larger than other
            flex: 3,
            child: GridView.builder(
              itemCount: 8 * 8,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) {
                // get the row and column position
                int row = index ~/ 8;
                int col = index % 8;

                //checking if square is selected
                bool isSelected = selectedRow == row && selectedCol == col;

                // Check if Square is valid move or not
                bool isValidMove = false;
                for (var position in validMoves) {
                  //compare row and col
                  if (position[0] == row && position[1] == col) {
                    isValidMove = true;
                  }
                }

                return Square(
                  isSelected: isSelected,
                  isWhite: isWhite(index),
                  piece: board[row][col],
                  isValidMoves: isValidMove,
                  onTap: () => pieceSelected(row, col),
                );
              },
            ),
          ),
          //Black pieces taken
          Expanded(
            child: GridView.builder(
              itemCount: blackPieceTaken.length,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) => DeadPieces(
                imagePath: blackPieceTaken[index].imagePath,
                isWhite: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void logout(BuildContext context) async {
    try {
      await _authService.signOut();

      // Navigate to login page after successful sign out
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      // Show error message if sign out fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sign out: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void delete(BuildContext context) async{
    try{
      await _authService.deleteAccount();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => RegisterPage()),
            (route) => false, // Remove all previous routes
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Account Deleted Successfully')));
    }catch(e){
      throw Exception(e);
    }
  }
}
