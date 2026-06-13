import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pet_entity.dart';
import '../../../health_assessment/presentation/screens/home_screen.dart';
import 'pet_form_screen.dart';

/// Feature 1 - UC: Pet Profile Management (list / add / edit).
///
/// Holds pets in local state for now so the UI is fully browsable. Swap the
/// in-memory list for a PetRepository (GET/POST/PUT/DELETE /pets) later.
class PetProfileScreen extends StatefulWidget {
  const PetProfileScreen({super.key});

  @override
  State<PetProfileScreen> createState() => _PetProfileScreenState();
}

class _PetProfileScreenState extends State<PetProfileScreen> {
  final List<PetEntity> _pets = [
    PetEntity(
      id: 1,
      name: 'Milo',
      species: 'cat',
      breed: 'Scottish Fold',
      gender: 'male',
      dateOfBirth: DateTime(2023, 3, 10),
      weightKg: 4.2,
    ),
  ];

  Future<void> _openForm({PetEntity? pet, int? index}) async {
    final result = await Navigator.of(context).push<PetEntity>(
      MaterialPageRoute(builder: (_) => PetFormScreen(initial: pet)),
    );
    if (result == null) return;
    setState(() {
      if (index != null) {
        _pets[index] = result;
      } else {
        _pets.add(result);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'สัตว์เลี้ยงของฉัน',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const HomeScreen())),
            icon: const Icon(
              Icons.home_outlined,
              color: AppTheme.secondaryText,
            ),
            tooltip: 'ไปหน้าหลัก',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: _pets.isEmpty
            ? _emptyState()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                itemCount: _pets.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 14),
                itemBuilder: (_, i) => _PetCard(
                  pet: _pets[i],
                  onTap: () => _openForm(pet: _pets[i], index: i),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'เพิ่มสัตว์เลี้ยง',
          style: TextStyle(
            fontFamily: AppTheme.displayFontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: AppTheme.mutedText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'ยังไม่มีสัตว์เลี้ยง',
            style: TextStyle(
              fontFamily: AppTheme.displayFontFamily,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'กดปุ่ม + เพื่อเพิ่มน้องตัวแรกของคุณ',
            style: TextStyle(
              fontFamily: AppTheme.sansFontFamily,
              color: AppTheme.mutedText,
            ),
          ),
        ],
      ),
    );
  }
}

class _PetCard extends StatelessWidget {
  final PetEntity pet;
  final VoidCallback onTap;

  const _PetCard({required this.pet, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCat = (pet.species ?? '').toLowerCase().contains('cat');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.glassCardDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                isCat ? Icons.pets : Icons.cruelty_free,
                color: AppTheme.primaryColor,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontFamily: AppTheme.displayFontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (pet.breed != null && pet.breed!.isNotEmpty) pet.breed,
                      pet.ageLabel,
                      if (pet.weightKg != null) '${pet.weightKg} กก.',
                    ].whereType<String>().join(' • '),
                    style: const TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: AppTheme.mutedText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.mutedText),
          ],
        ),
      ),
    );
  }
}
