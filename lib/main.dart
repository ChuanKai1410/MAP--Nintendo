import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:flutter/scheduler.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Nintendo Rooms',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const GameScreen(),
    );
  }
}

enum Room { pokemon, kirby, mario }

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class CharacterState {
  Offset pos;
  Offset vel;
  bool isCaught;
  String name; 
  String emoji; 
  Color color; 
  String? assetPath;

  CharacterState({
    required this.pos, 
    required this.vel, 
    this.isCaught = false, 
    required this.name, 
    required this.emoji, 
    required this.color, 
    this.assetPath
  });
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  Room currentRoom = Room.pokemon;
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;
  bool _isInitialized = false;
  Size _screenSize = Size.zero;

  final Set<LogicalKeyboardKey> _pressedKeys = {};
  Offset _trainerPos = Offset.zero;
  final List<Offset> _trainerHistory = []; 
  
  List<CharacterState> _characters = [];
  final Map<Room, List<CharacterState>> _roomCharacters = {
    Room.pokemon: [],
    Room.kirby: [],
    Room.mario: [],
  };
  final Map<Room, bool> _roomCompleted = {
    Room.pokemon: false,
    Room.kirby: false,
    Room.mario: false,
  };

  final FocusNode _focusNode = FocusNode();
  final Random _random = Random();
  bool _isDoorOpen = false;
  bool _showCongrats = false;

  Rect get leftDoorRect => Rect.fromLTWH(10, _screenSize.height / 2 - 75, 60, 150);
  Rect get rightDoorRect => Rect.fromLTWH(_screenSize.width - 70, _screenSize.height / 2 - 75, 60, 150);
  Rect get titleRect => Rect.fromLTWH(_screenSize.width / 2 - 180, 0, 360, 150);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _ticker.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _initGame(Size size) {
    _screenSize = size;
    _trainerPos = Offset(size.width / 2, size.height / 2);
    _enterRoom(Room.pokemon);
    _isInitialized = true;
  }

  void _enterRoom(Room room, [bool spawnRight = true]) {
    if (_characters.isNotEmpty && _characters.every((c) => c.isCaught)) {
        _roomCompleted[currentRoom] = true;
    }

    currentRoom = room;
    _characters = _roomCharacters[room]!;
    _trainerHistory.clear();
    _isDoorOpen = false;
    _showCongrats = false;
    
    if (spawnRight) {
       _trainerPos = Offset(_screenSize.width - 200, _screenSize.height / 2 - 60);
    } else {
       _trainerPos = Offset(100, _screenSize.height / 2 - 60);
    }

    if (_characters.isEmpty) {
      if (room == Room.pokemon) {
        _addChars(room, ['Pikachu', 'Charizard'], ['⚡', '🔥'], [const Color(0xFFF6C839), const Color(0xFFE47044)], ['images/Pikachu.webp', 'images/Charizard.webp']);
      } else if (room == Room.kirby) {
        _addChars(room, ['Kirby', 'Keeby', 'Kaiby'], ['🌟','🌟','🌟'], [Colors.pinkAccent, Colors.yellow[600]!, Colors.blueAccent], ['images/kirby.png', 'images/Keeby.webp', 'images/kaiby.png']);
      } else {
        _addChars(room, ['Mario', 'Luigi', 'Yoshi', 'Peach', 'Shy Guy'], ['🍄', '🐢', '🦖', '👑', '👻'], [Colors.redAccent, Colors.green, Colors.lightGreen, Colors.pinkAccent, Colors.red], ['images/Mario.webp', 'images/Luigi.webp', 'images/Yoshi.webp', 'images/Peach.webp', 'images/Shy_Guy.webp']);
      }
      _characters = _roomCharacters[room]!;
    }

    if (_roomCompleted[room] == true) {
       _isDoorOpen = true; 
       double startX = _screenSize.width / 2 - (_characters.length * 110) / 2;
       for (int i = 0; i < _characters.length; i++) {
          _characters[i].pos = Offset(startX + i * 110 + 5, _screenSize.height / 2 - 60);
          _characters[i].vel = Offset.zero;
          _characters[i].isCaught = true; 
       }
    }
  }

  void _addChars(Room room, List<String> names, List<String> emojis, List<Color> colors, List<String> assets) {
     for (int i=0; i<names.length; i++) {
        Offset startPos = _findValidSpawn();
        double angle = _random.nextDouble() * 2 * pi;
        Offset startVel = Offset(cos(angle), sin(angle)) * 100.0;
        _roomCharacters[room]!.add(CharacterState(
          pos: startPos, vel: startVel, name: names[i], emoji: emojis[i], color: colors[i], assetPath: assets[i]
        ));
     }
  }

  Offset _findValidSpawn() {
    for (int i=0; i<100; i++) {
      Offset test = Offset(_random.nextDouble() * (_screenSize.width - 150) + 25, _random.nextDouble() * (_screenSize.height - 170) + 25);
      Rect r = Rect.fromLTWH(test.dx, test.dy, 100, 120);
      bool valid = true;
      for (Rect obs in [titleRect, leftDoorRect, rightDoorRect, Rect.fromLTWH(_trainerPos.dx - 100, _trainerPos.dy - 100, 300, 320)]) {
        if (r.overlaps(obs)) {
          valid = false;
        }
      }
      if (valid) {
        return test;
      }
    }
    return Offset(_screenSize.width/2, _screenSize.height/2);
  }

  void _tick(Duration elapsed) {
    if (!_isInitialized) return;
    double dt = (elapsed - _lastTime).inMicroseconds / 1000000.0;
    _lastTime = elapsed;
    if (dt > 0.1) dt = 0.1; 
    
    double dx = 0; double dy = 0;
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowUp) || _pressedKeys.contains(LogicalKeyboardKey.keyW)) dy -= 1;
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowDown) || _pressedKeys.contains(LogicalKeyboardKey.keyS)) dy += 1;
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowLeft) || _pressedKeys.contains(LogicalKeyboardKey.keyA)) dx -= 1;
    if (_pressedKeys.contains(LogicalKeyboardKey.arrowRight) || _pressedKeys.contains(LogicalKeyboardKey.keyD)) dx += 1;

    if (dx != 0 || dy != 0) {
      double len = sqrt(dx*dx + dy*dy);
      _trainerPos += Offset(dx/len * 200.0 * dt, dy/len * 200.0 * dt);
      
      _trainerPos = Offset(
        _trainerPos.dx.clamp(0.0, _screenSize.width - 100.0),
        _trainerPos.dy.clamp(0.0, _screenSize.height - 120.0),
      );

      if (_trainerHistory.isEmpty || (_trainerHistory.first - _trainerPos).distance > 5) {
         _trainerHistory.insert(0, _trainerPos);
         if (_trainerHistory.length > 500) _trainerHistory.removeLast();
      }
    }

    Rect trainerRect = Rect.fromLTWH(_trainerPos.dx, _trainerPos.dy, 100, 120);
    bool allCaught = _characters.every((c) => c.isCaught);

    if (allCaught && !_isDoorOpen) {
      _isDoorOpen = true;
      _showCongrats = true;
      Future.delayed(const Duration(seconds: 3), () {
         if (mounted) setState(() => _showCongrats = false);
      });
    }

    if (allCaught) {
       if (currentRoom == Room.pokemon && trainerRect.overlaps(leftDoorRect)) {
         _enterRoom(Room.mario, true);
       } else if (currentRoom == Room.pokemon && trainerRect.overlaps(rightDoorRect)) {
         _enterRoom(Room.kirby, false);
       } else if (currentRoom == Room.kirby && trainerRect.overlaps(leftDoorRect)) {
         _enterRoom(Room.pokemon, true);
       } else if (currentRoom == Room.mario && trainerRect.overlaps(rightDoorRect)) {
         _enterRoom(Room.pokemon, false);
       }
    }

    int caughtIndex = 1;
    for (var c in _characters) {
      if (!c.isCaught) {
        Rect cRect = Rect.fromLTWH(c.pos.dx, c.pos.dy, 100, 120);
        if (cRect.overlaps(trainerRect)) {
          c.isCaught = true;
          continue;
        }

        Offset nextPos = c.pos + c.vel * dt;
        Rect nextRect = Rect.fromLTWH(nextPos.dx, nextPos.dy, 100, 120);
        
        bool hitX = false; bool hitY = false;

        if (nextRect.left < 0 || nextRect.right > _screenSize.width) hitX = true;
        if (nextRect.top < 0 || nextRect.bottom > _screenSize.height) hitY = true;
        
        List<Rect> activeDoors = [];
        if (currentRoom == Room.pokemon || currentRoom == Room.kirby) activeDoors.add(leftDoorRect);
        if (currentRoom == Room.pokemon || currentRoom == Room.mario) activeDoors.add(rightDoorRect);
        
        for (Rect obs in [titleRect, ...activeDoors]) {
           if (nextRect.overlaps(obs)) {
              Rect tryX = Rect.fromLTWH(nextPos.dx, c.pos.dy, 100, 120);
              if (tryX.overlaps(obs)) {
                hitX = true;
              } else {
                hitY = true;
              }
           }
        }

        if (hitX) c.vel = Offset(-c.vel.dx, c.vel.dy);
        if (hitY) c.vel = Offset(c.vel.dx, -c.vel.dy);
        
        c.pos += c.vel * dt;
        c.pos = Offset(c.pos.dx.clamp(0.0, _screenSize.width - 100.0), c.pos.dy.clamp(0.0, _screenSize.height - 120.0));
      } else {
        if (_roomCompleted[currentRoom] == true) {
           // Queue in line at center (set in _enterRoom), do not move
        } else {
           int targetHistoryIndex = caughtIndex * 15;
           if (targetHistoryIndex < _trainerHistory.length) {
             c.pos = _trainerHistory[targetHistoryIndex];
           } else if (_trainerHistory.isNotEmpty) {
             c.pos = _trainerHistory.last;
           }
           caughtIndex++;
        }
      }
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
             _pressedKeys.add(event.logicalKey);
          } else if (event is KeyUpEvent) {
             _pressedKeys.remove(event.logicalKey);
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
             if (constraints.maxWidth == 0) return const SizedBox();
             if (!_isInitialized || _screenSize.width != constraints.maxWidth || _screenSize.height != constraints.maxHeight) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _initGame(Size(constraints.maxWidth, constraints.maxHeight));
                });
                return const Center(child: CircularProgressIndicator());
             }
             return Stack(
               children: [
                 _buildBackground(),
                 if (currentRoom == Room.kirby || currentRoom == Room.pokemon) _buildDoor('left'),
                 if (currentRoom == Room.mario || currentRoom == Room.pokemon) _buildDoor('right'),
                 ..._characters.map((c) => Positioned(
                   left: c.pos.dx, top: c.pos.dy,
                   child: _CharacterCard(name: c.name, emoji: c.emoji, color: c.color, assetPath: c.assetPath),
                 )),
                 Positioned(
                   left: _trainerPos.dx, top: _trainerPos.dy,
                   child: const _CharacterCard(name: 'Trainer', emoji: '🏃', color: Color(0xFF5D9CEC), assetPath: 'images/Pokemon_Trainer.webp')
                 ),
                 _buildRoomTitle(),
                 if (_showCongrats)
                    Align(
                      alignment: Alignment.center,
                      child: IgnorePointer(
                        child: TweenAnimationBuilder(
                          tween: Tween<double>(begin: 0.1, end: 1.0),
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, double value, child) {
                             return Transform.scale(
                               scale: value,
                               child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                                  decoration: BoxDecoration(
                                     gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                                     borderRadius: BorderRadius.circular(30),
                                     boxShadow: const [
                                        BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5)
                                     ],
                                     border: Border.all(color: Colors.white, width: 4)
                                  ),
                                  child: const Column(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                        Text("🎉 CONGRATULATIONS! 🎉", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo, shadows: [Shadow(color: Colors.white, blurRadius: 5)])),
                                        SizedBox(height: 10),
                                        Text("The door is now open!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                                     ]
                                  )
                               )
                             );
                          }
                        )
                      )
                    )
               ]
             );
          }
        ),
      ),
    );
  }

  Widget _buildBackground() {
    String imagePath = 'images/Pokemon.jpg';
    List<Color> gradient = [const Color(0xFFa1c4fd), const Color(0xFFc2e9fb)];
    if (currentRoom == Room.kirby) {
       imagePath = 'images/Kirby.jpg';
       gradient = [const Color(0xFFff9a9e), const Color(0xFFfecfef)];
    } else if (currentRoom == Room.mario) {
       imagePath = 'images/WMario.webp';
       gradient = [const Color(0xFFfdfbfb), const Color(0xFFebedee)];
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover, opacity: 0.4),
      )
    );
  }

  Widget _buildDoor(String side) {
    bool isLeft = side == 'left';
    String label = isLeft ? (currentRoom == Room.pokemon ? 'Mario Room' : 'Exit') : (currentRoom == Room.pokemon ? 'Kirby Room' : 'Exit');
    return Positioned(
      left: isLeft ? 10 : null,
      right: isLeft ? null : 10,
      top: _screenSize.height / 2 - 75,
      child: _Door(label: label),
    );
  }

  Widget _buildRoomTitle() {
    String title = "Pokémon Room";
    Color bg = Colors.blueAccent;
    if (currentRoom == Room.kirby) { title = "Kirby Room"; bg = Colors.pinkAccent; }
    else if (currentRoom == Room.mario) { title = "Mario Room"; bg = Colors.redAccent; }
    
    bool allCaught = _characters.every((c) => c.isCaught);
    String subtitle = allCaught ? "The door is now open!" : "Catch all characters to unlock the door!";
    
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 360,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 5))]
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text("WASD/Arrows to catch 'em all!\n$subtitle", textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: Colors.white)),
              ]
            )
          )
        )
      )
    );
  }
}

class _CharacterCard extends StatelessWidget {
  final String name;
  final String emoji;
  final Color color;
  final String? assetPath;

  const _CharacterCard({
    required this.name,
    required this.emoji,
    required this.color,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 120,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
           if (assetPath != null)
             Expanded(
               child: Padding(
                 padding: const EdgeInsets.all(8.0),
                 child: Image.asset(
                   assetPath!,
                   fit: BoxFit.contain,
                   errorBuilder: (context, error, stackTrace) {
                     return Center(child: Text(emoji, style: const TextStyle(fontSize: 40)));
                   },
                 ),
               )
             )
           else
             Expanded(child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40)))),
           const SizedBox(height: 4),
           Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, shadows: [
             Shadow(color: Colors.black54, blurRadius: 2, offset: Offset(1,1))
           ])),
           const SizedBox(height: 4),
        ]
      )
    );
  }
}

class _Door extends StatelessWidget {
  final String label;

  const _Door({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.brown[700],
        border: Border.all(color: Colors.black87, width: 3),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
           BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(2, 2))
        ]
      ),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      )
    );
  }
}