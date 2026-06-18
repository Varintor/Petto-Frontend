import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/pet_entity.dart';
import '../widgets/pet_form_widgets.dart';

/// Feature 1 - UC: Add / Edit Pet Profile.
///
/// Returns the resulting [PetEntity] via Navigator.pop. Fields mirror the
/// backend `pet_profiles` schema (name, species, breed, gender, dob, weight).
class PetFormScreen extends StatefulWidget {
  final PetEntity? initial;

  const PetFormScreen({super.key, this.initial});

  bool get isEdit => initial != null;

  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _breed;
  late final TextEditingController _weight;
  String? _species;
  String? _gender;
  DateTime? _dob;

  static const _speciesOptions = ['dog', 'cat', 'rabbit', 'bird', 'other'];
  static const _speciesLabels = {
    'dog': 'สุนัข',
    'cat': 'แมว',
    'rabbit': 'กระต่าย',
    'bird': 'นก',
    'other': 'อื่นๆ',
  };

  @override
  void initState() {
    super.initState();
    final p = widget.initial;
    _name = TextEditingController(text: p?.name ?? '');
    _breed = TextEditingController(text: p?.breed ?? '');
    _weight = TextEditingController(text: p?.weightKg?.toString() ?? '');
    _species = p?.species;
    _gender = p?.gender;
    _dob = p?.dateOfBirth;
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(DateTime.now().year - 1),
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final pet = PetEntity(
      id: widget.initial?.id,
      name: _name.text.trim(),
      species: _species,
      breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
      gender: _gender,
      dateOfBirth: _dob,
      weightKg: double.tryParse(_weight.text.trim()),
    );
    // TODO: persist via PetRepository (POST/PUT /pets) once wired.
    Navigator.of(context).pop(pet);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isEdit ? 'แก้ไขข้อมูลน้อง' : 'เพิ่มสัตว์เลี้ยง',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.appBackgroundGradient,
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(24, 12, 24, 40 + keyboardInset),
            children: [
              PettoTextField(
                controller: _name,
                label: 'ชื่อสัตว์เลี้ยง',
                icon: Icons.badge_outlined,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
              ),
              const SizedBox(height: 16),
              _label('ชนิดสัตว์'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _speciesOptions.map((s) {
                  final selected = _species == s;
                  return ChoiceChip(
                    label: Text(_speciesLabels[s]!),
                    selected: selected,
                    onSelected: (_) => setState(() => _species = s),
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: selected ? Colors.white : AppTheme.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: AppTheme.warmSurfaceColor.withValues(alpha: 0.7),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              PettoTextField(
                controller: _breed,
                label: 'สายพันธุ์ (ถ้ามี)',
                icon: Icons.pets_outlined,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _genderSelector('male', 'ผู้', Icons.male)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _genderSelector('female', 'เมีย', Icons.female),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDob,
                child: AbsorbPointer(
                  child: PettoTextField(
                    controller: TextEditingController(
                      text: _dob == null
                          ? ''
                          : '${_dob!.day}/${_dob!.month}/${_dob!.year}',
                    ),
                    label: 'วันเกิด',
                    icon: Icons.cake_outlined,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              PettoTextField(
                controller: _weight,
                label: 'น้ำหนัก (กก.)',
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 28),
              PettoPrimaryButton(
                label: widget.isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มสัตว์เลี้ยง',
                onPressed: _save,
                icon: Icons.check,
              ),
              if (widget.isEdit) ...[
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () {
                    // TODO: DELETE /pets/{id} once wired. For now just signal back.
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppTheme.dangerColor,
                  ),
                  label: const Text(
                    'ลบสัตว์เลี้ยงนี้',
                    style: TextStyle(
                      fontFamily: AppTheme.sansFontFamily,
                      color: AppTheme.dangerColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontFamily: AppTheme.sansFontFamily,
      color: AppTheme.secondaryText,
      fontWeight: FontWeight.w700,
      fontSize: 14,
    ),
  );

  Widget _genderSelector(String value, String label, IconData icon) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? AppTheme.secondaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppTheme.secondaryColor
                : AppTheme.warmSurfaceColor.withValues(alpha: 0.7),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: selected ? Colors.white : AppTheme.mutedText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.sansFontFamily,
                color: selected ? Colors.white : AppTheme.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
