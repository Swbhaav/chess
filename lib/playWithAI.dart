import 'package:chess/chess.dart' as chess_lib;
import 'package:chessgame/component/piece.dart';
import 'package:chessgame/component/square.dart';
import 'package:chessgame/helper/helper.dart';
import 'package:chessgame/values/colors.dart';
import 'package:flutter/material.dart';
import 'package:stockfish/stockfish.dart';
import 'component/dead_piece.dart';

class PlayWithAI extends StatefulWidget {
  PlayWithAI({super.key});

  @override
  State<PlayWithAI> createState() => _PlayWithAIState();
}

class _PlayWithAIState extends State<PlayWithAI> {
  // creating a stockfish instance
  late Stockfish stockfish;
  late chess_lib.Chess chessBoard;

  //Creating a game Board using 2D list
  late List<List<ChessPiece?>> board;

  //The Currently selected piece
  ChessPiece? selectedPiece;

  //When nothing is selected
  int selectedRow = -1;
  int selectedCol = -1;

  // List of valid moves for current piece
  List<List<int>> validMoves = [];

  // A list of taken white pieces
  List<ChessPiece> whitePieceTaken = [];

  // A list of taken black pieces
  List<ChessPiece> blackPieceTaken = [];

  // A boolean to indicate whose turn it is (true = white to move)
  bool isWhiteTurn = true;

  //initial position of kings
  List<int> whiteKingPosition = [7, 4];
  List<int> blackKingPosition = [0, 4];
  bool checkStatus = false;

  // AI state management
  bool stockfishReady = false;
  bool isAIThinking = false;

  @override
  void initState() {
    super.initState();
    _initializeBoard();
    stockfish = Stockfish();
    chessBoard = chess_lib.Chess();
    _setupStockfish();
  }

  void _setupStockfish() {
    // Listen to Stockfish state changes
    stockfish.state.addListener(() {
      print('Stockfish State: ${stockfish.state.value}');
      if (stockfish.state.value == StockfishState.ready && !stockfishReady) {
        stockfish.stdin = 'uci';
      }
    });

    // Listen to Stockfish output
    stockfish.stdout.listen((message) {
      print('Stockfish: $message');

      if (message.contains('uciok')) {
        stockfish.stdin = 'isready';
      } else if (message.contains('readyok')) {
        setState(() {
          stockfishReady = true;
        });
        print('✓ Stockfish is ready!');
      } else if (message.startsWith('bestmove')) {
        _handleStockfishMove(message);
      }
    });
  }

  @override
  void dispose() {
    stockfish.stdin = 'quit';
    stockfish.dispose();
    super.dispose();
  }

  // INITIALIZE BOARD
  void _initializeBoard() {
    List<List<ChessPiece?>> newBoard = List.generate(
      8,
      (index) => List.generate(8, (index) => null),
    );

    // Pawn Place
    for (int i = 0; i < 8; i++) {
      // Black pawns (row 1)
      newBoard[1][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: false,
        imagePath: 'lib/images/black-pawn.png',
      );

      // White pawns (row 6)
      newBoard[6][i] = ChessPiece(
        type: ChessPieceType.pawn,
        isWhite: true,
        imagePath: 'lib/images/white-pawn.png',
      );
    }

    // Black back rank (row 0)
    newBoard[0][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      imagePath: 'lib/images/black-rook.png',
    );
    newBoard[0][1] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.knight,
      imagePath: 'lib/images/black-knight.png',
    );
    newBoard[0][2] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/black-bishop.png',
    );
    newBoard[0][3] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.queen,
      imagePath: 'lib/images/black-queen.png',
    );
    newBoard[0][4] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.king,
      imagePath: 'lib/images/black-king.png',
    );
    newBoard[0][5] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/black-bishop.png',
    );
    newBoard[0][6] = ChessPiece(
      isWhite: false,
      type: ChessPieceType.knight,
      imagePath: 'lib/images/black-knight.png',
    );
    newBoard[0][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: false,
      imagePath: 'lib/images/black-rook.png',
    );

    // White back rank (row 7)
    newBoard[7][0] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      imagePath: 'lib/images/white-rook.png',
    );
    newBoard[7][1] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.knight,
      imagePath: 'lib/images/white-knight.png',
    );
    newBoard[7][2] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/white-bishop.png',
    );
    newBoard[7][3] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.queen,
      imagePath: 'lib/images/white-queen.png',
    );
    newBoard[7][4] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.king,
      imagePath: 'lib/images/white-king.png',
    );
    newBoard[7][5] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.bishop,
      imagePath: 'lib/images/white-bishop.png',
    );
    newBoard[7][6] = ChessPiece(
      isWhite: true,
      type: ChessPieceType.knight,
      imagePath: 'lib/images/white-knight.png',
    );
    newBoard[7][7] = ChessPiece(
      type: ChessPieceType.rook,
      isWhite: true,
      imagePath: 'lib/images/white-rook.png',
    );

    board = newBoard;

    // Reset chess_lib board to starting position
    chessBoard = chess_lib.Chess();

    // Reset king positions to default
    whiteKingPosition = [7, 4];
    blackKingPosition = [0, 4];
  }

  // USER SELECTED A PIECE
  void pieceSelected(int row, int col) {
    // Don't allow moves during AI's turn or when AI is thinking
    if (!isWhiteTurn || isAIThinking) return;

    setState(() {
      // No piece has been selected yet, this is the first selection
      if (selectedPiece == null && board[row][col] != null) {
        if (board[row][col]!.isWhite == isWhiteTurn) {
          selectedPiece = board[row][col];
          selectedRow = row;
          selectedCol = col;
          validMoves = calculateRealValidMoves(row, col, selectedPiece, true);

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
        // Use new movePiece signature: fromRow, fromCol, toRow, toCol
        movePiece(selectedRow, selectedCol, row, col);
      }
    });
  }

  // Calculating Raw valid moves
  List<List<int>> calculateRawValidMoves(int row, int col, ChessPiece? piece) {
    List<List<int>> candidateMoves = [];

    if (piece == null) {
      return [];
    }

    int direction = piece.isWhite ? -1 : 1;

    switch (piece.type) {
      case ChessPieceType.pawn:
        if (isInBoard(row + direction, col) &&
            board[row + direction][col] == null) {
          candidateMoves.add([row + direction, col]);
        }

        if ((row == 1 && !piece.isWhite) || (row == 6 && piece.isWhite)) {
          if (isInBoard(row + 2 * direction, col) &&
              board[row + 2 * direction][col] == null &&
              board[row + direction][col] == null) {
            candidateMoves.add([row + 2 * direction, col]);
          }
        }

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
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
        ];
        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) break;

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

      case ChessPieceType.knight:
        var knightMoves = [
          [-2, -1],
          [-2, 1],
          [-1, -2],
          [-1, 2],
          [1, -2],
          [1, 2],
          [2, -1],
          [2, 1],
        ];
        for (var move in knightMoves) {
          var newRow = row + move[0];
          var newCol = col + move[1];
          if (!isInBoard(newRow, newCol)) continue;

          if (board[newRow][newCol] != null) {
            if (board[newRow][newCol]!.isWhite != piece.isWhite) {
              candidateMoves.add([newRow, newCol]);
            }
            continue;
          }
          candidateMoves.add([newRow, newCol]);
        }
        break;

      case ChessPieceType.bishop:
        var directions = [
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1],
        ];
        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) break;

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
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1],
        ];
        for (var direction in directions) {
          var i = 1;
          while (true) {
            var newRow = row + i * direction[0];
            var newCol = col + i * direction[1];
            if (!isInBoard(newRow, newCol)) break;

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

      case ChessPieceType.king:
        var directions = [
          [-1, 0],
          [1, 0],
          [0, -1],
          [0, 1],
          [-1, -1],
          [-1, 1],
          [1, -1],
          [1, 1],
        ];
        for (var direction in directions) {
          var newRow = row + direction[0];
          var newCol = col + direction[1];
          if (!isInBoard(newRow, newCol)) continue;

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

    if (checkSimulation) {
      for (var move in candidateMoves) {
        int endRow = move[0];
        int endCol = move[1];
        if (simulatedMoveIsSafe(piece!, row, col, endRow, endCol)) {
          realValidMoves.add(move);
        }
      }
    } else {
      realValidMoves = candidateMoves;
    }
    return realValidMoves;
  }

  // New movePiece signature that explicitly passes from & to
  void movePiece(
    int fromRow,
    int fromCol,
    int toRow,
    int toCol, {
    bool isAiMove = false,
  }) {
    // Basic validations
    ChessPiece? moving = board[fromRow][fromCol];
    if (moving == null) return;

    // If it's a player's move, ensure it is their turn
    if (!isAiMove && moving.isWhite != isWhiteTurn) return;

    // Capture logic
    ChessPiece? capturedPiece = board[toRow][toCol];
    if (capturedPiece != null) {
      if (capturedPiece.isWhite) {
        whitePieceTaken.add(capturedPiece);
      } else {
        blackPieceTaken.add(capturedPiece);
      }
    }

    // Keep track of old king pos in case we need to revert
    List<int>? originalKingPosition;
    if (moving.type == ChessPieceType.king) {
      originalKingPosition = moving.isWhite
          ? List.from(whiteKingPosition)
          : List.from(blackKingPosition);
      if (moving.isWhite) {
        whiteKingPosition = [toRow, toCol];
      } else {
        blackKingPosition = [toRow, toCol];
      }
    }

    // Make the move on visual board
    board[toRow][toCol] = moving;
    board[fromRow][fromCol] = null;

    // Update chess library board using algebraic coordinates
    String fromAlg = _coordsToAlgebraic(fromRow, fromCol);
    String toAlg = _coordsToAlgebraic(toRow, toCol);

    try {
      // Use a map with from/to to make the move in chess.dart
      var result = chessBoard.move({'from': fromAlg, 'to': toAlg});

      if (result == null) {
        // if chess.dart rejected the move, revert visual board and king pos
        board[fromRow][fromCol] = moving;
        board[toRow][toCol] = capturedPiece;
        if (moving.type == ChessPieceType.king) {
          if (moving.isWhite)
            whiteKingPosition = originalKingPosition!;
          else
            blackKingPosition = originalKingPosition!;
        }
        return;
      }
    } catch (e) {
      print('Error making move in chessBoard: $e');
    }

    bool currentPlayerIsWhite = moving.isWhite;

    // Switch turns
    isWhiteTurn = !isWhiteTurn;

    // Check for check/checkmate
    bool opponentInCheck = isInCheck(isWhiteTurn);
    bool opponentCheckmate = opponentInCheck && isCheckmate(isWhiteTurn);

    setState(() {
      selectedPiece = null;
      selectedRow = -1;
      selectedCol = -1;
      validMoves = [];
      checkStatus = opponentInCheck;
    });

    // Show game over if checkmate
    if (opponentCheckmate) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("CHECKMATE!"),
          content: Text(currentPlayerIsWhite ? "White wins!" : "Black wins!"),
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

    // Trigger AI move after player moves
    if (!isWhiteTurn && !opponentCheckmate && stockfishReady) {
      Future.delayed(Duration(milliseconds: 300), () {
        _makeAiMove();
      });
    }
  }

  String _coordsToAlgebraic(int row, int col) {
    String file = String.fromCharCode('a'.codeUnitAt(0) + col);
    String rank = (8 - row).toString();
    return '$file$rank';
  }

  // Request AI move from Stockfish
  void _makeAiMove() async {
    if (!stockfishReady || isAIThinking || isWhiteTurn) return;

    setState(() {
      isAIThinking = true;
    });

    try {
      String fen = chessBoard.fen;
      print('Requesting AI move for FEN: $fen');

      stockfish.stdin = 'setoption name Skill Level value 10';
      stockfish.stdin = 'position fen $fen';
      stockfish.stdin = 'go movetime 1000';
    } catch (e) {
      print('Error requesting AI move: $e');
      setState(() {
        isAIThinking = false;
      });
    }
  }

  // Handle the best move from Stockfish
  void _handleStockfishMove(String message) {
    if (!message.startsWith('bestmove')) return;

    try {
      String bestMove = message.split(' ')[1];
      if (bestMove == '(none)' || bestMove.isEmpty) {
        setState(() {
          isAIThinking = false;
        });
        return;
      }

      print('AI chose move: $bestMove');

      // Parse UCI move
      int fromCol = bestMove.codeUnitAt(0) - 'a'.codeUnitAt(0);
      int fromRow = 8 - int.parse(bestMove[1]);
      int toCol = bestMove.codeUnitAt(2) - 'a'.codeUnitAt(0);
      int toRow = 8 - int.parse(bestMove[3]);

      // Execute the AI move directly using the new movePiece signature
      setState(() {
        isAIThinking = false;
      });

      movePiece(fromRow, fromCol, toRow, toCol, isAiMove: true);
    } catch (e) {
      print('Error handling Stockfish move: $e');
      setState(() {
        isAIThinking = false;
      });
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

  bool isInCheck(bool isWhite) {
    List<int> kingPos = isWhite ? whiteKingPosition : blackKingPosition;
    return squareIsAttacked(kingPos[0], kingPos[1], !isWhite);
  }

  bool simulatedMoveIsSafe(
    ChessPiece piece,
    int startRow,
    int startCol,
    int endRow,
    int endCol,
  ) {
    ChessPiece? originalDestinationPiece = board[endRow][endCol];
    List<int>? originalKingPosition;

    if (piece.type == ChessPieceType.king) {
      originalKingPosition = piece.isWhite
          ? List.from(whiteKingPosition)
          : List.from(blackKingPosition);
      if (piece.isWhite) {
        whiteKingPosition = [endRow, endCol];
      } else {
        blackKingPosition = [endRow, endCol];
      }
    }

    board[endRow][endCol] = piece;
    board[startRow][startCol] = null;

    bool kingInCheck = isInCheck(piece.isWhite);

    board[startRow][startCol] = piece;
    board[endRow][endCol] = originalDestinationPiece;

    if (piece.type == ChessPieceType.king) {
      if (piece.isWhite) {
        whiteKingPosition = originalKingPosition!;
      } else {
        blackKingPosition = originalKingPosition!;
      }
    }

    return !kingInCheck;
  }

  bool isCheckmate(bool isWhite) {
    if (!isInCheck(isWhite)) return false;

    for (int row = 0; row < 8; row++) {
      for (int col = 0; col < 8; col++) {
        ChessPiece? piece = board[row][col];
        if (piece == null || piece.isWhite != isWhite) continue;

        List<List<int>> moves = calculateRealValidMoves(row, col, piece, true);

        for (var move in moves) {
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

          board[row][col] = piece;
          board[move[0]][move[1]] = original;

          if (piece.type == ChessPieceType.king) {
            if (isWhite)
              whiteKingPosition = originalKingPos!;
            else
              blackKingPosition = originalKingPos!;
          }

          if (!stillInCheck) return false;
        }
      }
    }

    return true;
  }

  void resetGame() {
    _initializeBoard();
    chessBoard = chess_lib.Chess();
    checkStatus = false;
    whitePieceTaken.clear();
    blackPieceTaken.clear();
    whiteKingPosition = [7, 4];
    blackKingPosition = [0, 4];
    isWhiteTurn = true;
    isAIThinking = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        title: Text('Play vs AI'),
        elevation: 0,
        toolbarHeight: 40,
        actions: [
          IconButton(
            onPressed: resetGame,
            icon: Icon(Icons.refresh),
            tooltip: 'New Game',
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
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (checkStatus)
                  Text(
                    'CHECK!',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                if (isAIThinking)
                  Row(
                    children: [
                      if (checkStatus) SizedBox(width: 16),
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('AI is thinking...'),
                    ],
                  ),
                if (!stockfishReady && !isAIThinking)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Initializing AI...'),
                    ],
                  ),
              ],
            ),
          ),

          //Chess Board
          Expanded(
            flex: 3,
            child: GridView.builder(
              itemCount: 8 * 8,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemBuilder: (context, index) {
                int row = index ~/ 8;
                int col = index % 8;

                bool isSelected = selectedRow == row && selectedCol == col;

                bool isValidMove = false;
                for (var position in validMoves) {
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
}
