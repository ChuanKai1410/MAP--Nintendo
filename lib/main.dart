import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

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

class _GameScreenState extends State<GameScreen> {
  Room currentRoom = Room.pokemon;
  int position = 0; 

  List<Offset> kirbyPositions = [];
  List<Offset> marioPositions = [];
  
  final Random _random = Random();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _enterKirbyRoom() {
    kirbyPositions.clear();
    for (int i = 0; i < 3; i++) {
      kirbyPositions.add(Offset(_random.nextDouble(), _random.nextDouble()));
    }
    setState(() {
      currentRoom = Room.kirby;
    });
  }

  void _enterMarioRoom() {
    marioPositions.clear();
    for (int i = 0; i < 5; i++) {
      marioPositions.add(Offset(_random.nextDouble(), _random.nextDouble()));
    }
    setState(() {
      currentRoom = Room.mario;
    });
  }

  void _moveLeft() {
    if (currentRoom == Room.pokemon) {
      if (position > -3) {
        setState(() {
          position--;
        });
      }
      if (position <= -3) {
        _enterMarioRoom();
      }
    } else if (currentRoom == Room.kirby) {
       setState(() {
         currentRoom = Room.pokemon;
         position = 2; 
       });
    }
  }

  void _moveRight() {
    if (currentRoom == Room.pokemon) {
      if (position < 3) {
        setState(() {
          position++;
        });
      }
      if (position >= 3) {
        _enterKirbyRoom();
      }
    } else if (currentRoom == Room.mario) {
       setState(() {
         currentRoom = Room.pokemon;
         position = -2;
       });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _moveLeft();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _moveRight();
            }
          }
        },
        child: LayoutBuilder(
          builder: (context, constraints) {
             if (currentRoom == Room.kirby) {
               return _buildKirbyRoom(constraints);
             } else if (currentRoom == Room.mario) {
               return _buildMarioRoom(constraints);
             }
             return _buildPokemonRoom(constraints);
          }
        ),
      ),
    );
  }

  Widget _buildPokemonRoom(BoxConstraints constraints) {
    double stepSize = constraints.maxWidth / 8;

    return Stack(
      children: [
         Container(
           decoration: const BoxDecoration(
             gradient: LinearGradient(
               colors: [Color(0xFFa1c4fd), Color(0xFFc2e9fb)],
               begin: Alignment.topCenter,
               end: Alignment.bottomCenter,
             ),
             image: DecorationImage(
               image: AssetImage('images/Pokemon.jpg'),
               fit: BoxFit.cover,
               opacity: 0.4,
             ),
           )
         ),
         
         Positioned(
           left: constraints.maxWidth * 0.2, top: constraints.maxHeight * 0.3,
           child: const _CharacterCard(name: 'Pikachu', emoji: '⚡', color: Color(0xFFF6C839), assetPath: 'images/Pikachu.webp'),
         ),
         Positioned(
           right: constraints.maxWidth * 0.2, top: constraints.maxHeight * 0.4,
           child: const _CharacterCard(name: 'Charizard', emoji: '🔥', color: Color(0xFFE47044), assetPath: 'images/Charizard.webp'),
         ),
         
         const Align(
           alignment: Alignment.centerLeft,
           child: _Door(label: 'Mario Room'),
         ),
         const Align(
           alignment: Alignment.centerRight,
           child: _Door(label: 'Kirby Room'),
         ),
         
         AnimatedPositioned(
           duration: const Duration(milliseconds: 200),
           curve: Curves.easeOut,
           bottom: 50,
           left: (constraints.maxWidth / 2) - 50 + (position * stepSize), 
           child: const _CharacterCard(name: 'Trainer', emoji: '🏃', color: Color(0xFF5D9CEC), assetPath: 'images/Pokemon_Trainer.webp'),
         ),
         
         Align(
             alignment: Alignment.topCenter,
             child: Padding(
                 padding: const EdgeInsets.all(40),
                 child: Container(
                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                   decoration: BoxDecoration(
                     color: Colors.white70,
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text("Pokémon Room\nMove: Left / Right Arrow Keys\nStep $position / ±3 to Change Rooms", 
                       textAlign: TextAlign.center, 
                       style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                   ),
                 )
             )
         )
      ]
    );
  }

  Widget _buildKirbyRoom(BoxConstraints constraints) {
    List<String> kirbyChars = ['Kirby', 'Keeby', 'Kaiby'];
    List<Color> kirbyColors = [Colors.pinkAccent, Colors.yellow[600]!, Colors.blueAccent];
    List<String> kirbyAssets = [
      'images/kirby.png',
      'images/Keeby.webp',
      'images/kaiby.png'
    ];
    
    return Stack(
      children: [
        Container(
           decoration: const BoxDecoration(
             gradient: LinearGradient(
               colors: [Color(0xFFff9a9e), Color(0xFFfecfef)],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
             image: DecorationImage(
               image: AssetImage('images/Kirby.jpg'),
               fit: BoxFit.cover,
               opacity: 0.4,
             ),
           )
        ),
        
        ...List.generate(kirbyPositions.length, (index) {
           return Positioned(
             left: kirbyPositions[index].dx * (constraints.maxWidth - 120),
             top: kirbyPositions[index].dy * (constraints.maxHeight - 140) + 20,
             child: _CharacterCard(name: kirbyChars[index%3], emoji: '🌟', color: kirbyColors[index%3], assetPath: kirbyAssets[index%3]),
           );
        }),
        
        const Align(
           alignment: Alignment.centerLeft,
           child: _Door(label: 'Exit'),
        ),
        
        Align(
           alignment: Alignment.centerLeft,
           child: Padding(
             padding: const EdgeInsets.only(left: 80.0),
             child: const _CharacterCard(name: 'Trainer', emoji: '🏃', color: Color(0xFF5D9CEC), assetPath: 'images/Pokemon_Trainer.webp'),
           ),
        ),

        Align(
             alignment: Alignment.topCenter,
             child: Padding(
                 padding: const EdgeInsets.all(40),
                 child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                     decoration: BoxDecoration(
                         color: Colors.white70,
                         borderRadius: BorderRadius.circular(20),
                     ),
                     child: const Text("Kirby Room\nPress LEFT Arrow to go back!", 
                         textAlign: TextAlign.center, 
                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)
                     ),
                 )
             )
        )
      ],
    );
  }

  Widget _buildMarioRoom(BoxConstraints constraints) {
    List<String> marioChars = ['Mario', 'Luigi', 'Yoshi', 'Peach', 'Shy Guy'];
    List<String> marioEmojis = ['🍄', '🐢', '🦖', '👑', '👻'];
    List<Color> marioColors = [Colors.redAccent, Colors.green, Colors.lightGreen, Colors.pinkAccent, Colors.red];
    List<String> marioAssets = [
       'images/Mario.webp',
       'images/Luigi.webp',
       'images/Yoshi.webp',
       'images/Peach.webp',
       'images/Shy_Guy.webp',
    ];

    return Stack(
      children: [
        Container(
           decoration: const BoxDecoration(
             gradient: LinearGradient(
               colors: [Color(0xFFfdfbfb), Color(0xFFebedee)],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
             ),
             image: DecorationImage(
               image: AssetImage('images/WMario.webp'),
               fit: BoxFit.cover,
               opacity: 0.4,
             ),
           )
        ),
        
        ...List.generate(marioPositions.length, (index) {
           return Positioned(
             left: marioPositions[index].dx * (constraints.maxWidth - 120),
             top: marioPositions[index].dy * (constraints.maxHeight - 140) + 20,
             child: _CharacterCard(name: marioChars[index%5], emoji: marioEmojis[index%5], color: marioColors[index%5], assetPath: marioAssets[index%5]),
           );
        }),
        
        const Align(
           alignment: Alignment.centerRight,
           child: _Door(label: 'Exit'),
        ),
        
        Align(
           alignment: Alignment.centerRight,
           child: Padding(
             padding: const EdgeInsets.only(right: 80.0),
             child: const _CharacterCard(name: 'Trainer', emoji: '🏃', color: Color(0xFF5D9CEC), assetPath: 'images/Pokemon_Trainer.webp'),
           ),
        ),

        Align(
             alignment: Alignment.topCenter,
             child: Padding(
                 padding: const EdgeInsets.all(40),
                 child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                     decoration: BoxDecoration(
                         color: Colors.black54,
                         borderRadius: BorderRadius.circular(20),
                     ),
                     child: const Text("Mario Room\nPress RIGHT Arrow to go back!", 
                         textAlign: TextAlign.center, 
                         style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)
                     ),
                 )
             )
        )
      ],
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