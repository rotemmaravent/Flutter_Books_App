import 'package:flutter/material.dart';
import 'book_list_screen.dart';

const _navy = Color(0xFF2D3250);
const _coral = Color(0xFFFF7B5E);
const _mint = Color(0xFFA8E6CF);
const _lavender = Color(0xFFC3AED6);
const _peach = Color(0xFFFFB347);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFormat = 'PDF';

  static const _ageGroups = [
    _AgeGroup(range: '0–4', emoji: '🌱', color: _mint),
    _AgeGroup(range: '4–8', emoji: '🦋', color: _lavender),
    _AgeGroup(range: '8–12', emoji: '🌟', color: _peach),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 36),
              const Text(
                "Pick an\nage group",
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: _navy,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 28),
              _FormatToggle(
                selected: _selectedFormat,
                onChanged: (f) => setState(() => _selectedFormat = f),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: _ageGroups.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, i) {
                    final group = _ageGroups[i];
                    return _AgeCard(group: group, format: _selectedFormat);
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormatToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FormatToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _FormatChip(
            label: 'PDF',
            icon: Icons.picture_as_pdf_rounded,
            isSelected: selected == 'PDF',
            onTap: () => onChanged('PDF'),
          ),
          _FormatChip(
            label: 'Word',
            icon: Icons.description_rounded,
            isSelected: selected == 'Word',
            onTap: () => onChanged('Word'),
          ),
        ],
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FormatChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _coral : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : _navy.withValues(alpha: 0.4),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isSelected ? Colors.white : _navy.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeCard extends StatelessWidget {
  final _AgeGroup group;
  final String format;

  const _AgeCard({required this.group, required this.format});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookListScreen(
              ageGroup: group.range.replaceAll('–', '-'),
              format: format,
              themeColor: group.color,
            ),
          ),
        );
      },
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _navy.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              decoration: BoxDecoration(
                color: group.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Text(group.emoji, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ages ${group.range}',
                    style: const TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _navy,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to browse books',
                    style: TextStyle(
                      fontFamily: 'Nunito',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _navy.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _navy.withValues(alpha: 0.25),
              size: 28,
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }
}

class _AgeGroup {
  final String range;
  final String emoji;
  final Color color;

  const _AgeGroup({required this.range, required this.emoji, required this.color});
}
