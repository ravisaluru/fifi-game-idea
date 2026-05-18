import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/character.dart';
import '../models/game_state.dart';
import '../widgets/shimmer_button.dart';

class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late Character _character;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _character = availableCharacters[0].copyWith();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _selectCharacter(int index) {
    setState(() {
      _selectedIndex = index;
      _character = availableCharacters[index].copyWith(
        outfitColor: _character.outfitColor,
        accessory: _character.accessory,
      );
    });
  }

  void _pickColor(Color color) {
    setState(() => _character = _character.copyWith(outfitColor: color));
  }

  void _pickAccessory(AccessoryType acc) {
    setState(() => _character = _character.copyWith(
      accessory: _character.accessory == acc ? AccessoryType.none : acc,
    ));
  }

  void _confirm(BuildContext context) {
    context.read<GameState>().selectCharacter(_character);
    Navigator.pushReplacementNamed(context, '/world-select');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A237E), Color(0xFF7B1FA2), Color(0xFFAD1457)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Choose Your Hero!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black45)],
                  ),
                ),
              ),

              // Big character preview
              AnimatedBuilder(
                animation: _bounceAnim,
                builder: (context, _) => Transform.translate(
                  offset: Offset(0, _bounceAnim.value),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _character.outfitColor.withValues(alpha: 0.3),
                      border: Border.all(color: _character.outfitColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: _character.outfitColor.withValues(alpha: 0.5),
                          blurRadius: 20,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_character.emoji,
                            style: const TextStyle(fontSize: 52)),
                        if (_character.accessory != AccessoryType.none)
                          Text(
                            accessoryEmojis[_character.accessory]!,
                            style: const TextStyle(fontSize: 20),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              Text(
                _character.displayName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              // Character carousel
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: availableCharacters.length,
                  itemBuilder: (context, i) {
                    final c = availableCharacters[i];
                    final selected = i == _selectedIndex;
                    return GestureDetector(
                      onTap: () => _selectCharacter(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: selected ? 72 : 60,
                        height: selected ? 72 : 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.1),
                          border: Border.all(
                            color: selected
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(c.emoji,
                              style: TextStyle(fontSize: selected ? 36 : 28)),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Outfit color picker
              const Text('Outfit Color',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: outfitColors.map((color) {
                  final selected = _character.outfitColor == color;
                  return GestureDetector(
                    onTap: () => _pickColor(color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: selected ? 40 : 32,
                      height: selected ? 40 : 32,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 8)]
                            : [],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Accessory picker
              const Text('Accessory',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: AccessoryType.values.map((acc) {
                  final selected = _character.accessory == acc;
                  return GestureDetector(
                    onTap: () => _pickAccessory(acc),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: selected
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(accessoryEmojis[acc]!,
                            style: const TextStyle(fontSize: 26)),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const Spacer(),

              // Let's Go button
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: ShimmerButton(
                  onTap: () => _confirm(context),
                  child: Container(
                    width: 200,
                    height: 64,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        "Let's Go! 🚀",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
