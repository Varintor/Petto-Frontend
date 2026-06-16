# วิธีใช้ Supabase Database ใน Petto App

## 1. สร้างตารางใน Supabase Dashboard

ไปที่ Supabase Dashboard → **SQL Editor** แล้วรันคำสั่ง SQL นี้:

```sql
-- ตาราง pets (สัตว์เลี้ยง)
CREATE TABLE IF NOT EXISTS pets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  name TEXT NOT NULL,
  species TEXT NOT NULL CHECK (species IN ('Cat', 'Dog')),
  breed TEXT,
  gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female')),
  date_of_birth DATE,
  weight_kg DECIMAL(5,2),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- เปิดใช้งาน RLS (Row Level Security)
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;

-- สร้าง Policy ให้ผู้ใช้เข้าถึงข้อมูลเฉพาะของตัวเอง
CREATE POLICY "Users can view own pets"
  ON pets FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own pets"
  ON pets FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own pets"
  ON pets FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own pets"
  ON pets FOR DELETE
  USING (auth.uid() = user_id);

-- ตาราง assessments (การประเมินสุขภาพ)
CREATE TABLE IF NOT EXISTS assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  image_url TEXT,
  symptoms TEXT,
  ai_diagnosis TEXT,
  severity_level TEXT CHECK (severity_level IN ('Low', 'Medium', 'High', 'Critical')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE assessments ENABLE ROW LEVEL SECURITY;

-- ผ่านการตรวจสอบผ่าน pets (เพราะ assessment มี pet_id ที่เชื่อมกับ pets)
CREATE POLICY "Users can view assessments of own pets"
  ON assessments FOR SELECT
  USING (
    pet_id IN (
      SELECT id FROM pets WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "Users can insert assessments for own pets"
  ON assessments FOR INSERT
  WITH CHECK (
    pet_id IN (
      SELECT id FROM pets WHERE user_id = auth.uid()
    )
  );
```

## 2. ใช้งาน Repository ใน Code

### สร้างสัตว์เลี้ยงใหม่ (ตอน Register):

```dart
import 'package:petto_application/src/features/pet_management/data/repositories/supabase_pet_repository.dart';

// ในฟังก์ชัน _handleRegisterAndCreatePet
Future<void> _handleRegisterAndCreatePet() async {
  // ... ลงทะเบียนเสร็จแล้ว ...

  try {
    final petRepo = SupabasePetRepository();

    final newPet = await petRepo.createPet(
      name: _petNameOrDefault,
      species: _species,
      breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
      gender: _gender,
      dateOfBirth: DateTime(_birthYear, _birthMonth, _birthDay),
      weightKg: double.tryParse(_weight.text.trim()),
    );

    // บันทึก pet ID ไว้ใช้ต่อ
    await auth.setPetId(newPet.id.hashCode); // หรือเก็บ UUID ไว้เลย

    _openHome();
  } catch (e) {
    setState(() => _errorMessage = 'Failed to create pet: $e');
  }
}
```

### บันทึกผลการประเมินสุขภาพ:

```dart
import 'package:petto_application/src/features/health_assessment/data/repositories/supabase_assessment_repository.dart';

// ใน HealthAssessmentController
Future<void> submitAssessment({
  required String petId,
  required String imageUrl,
  required String symptoms,
}) async {
  final assessmentRepo = SupabaseAssessmentRepository();

  final assessment = await assessmentRepo.createAssessment(
    petId: petId,
    imageUrl: imageUrl,
    symptoms: symptoms,
    // AI diagnosis จะถูกเติมโดย backend หรือ AI service
  );

  return assessment;
}
```

### ดึงข้อมูลสัตว์เลี้ยงทั้งหมดของ User:

```dart
// ดึงข้อมูล pets ทั้งหมด
final petRepo = SupabasePetRepository();
final myPets = await petRepo.getUserPets();

for (final pet in myPets) {
  print('Pet: ${pet.name} (${pet.species})');
}
```

## 3. เชื่อมต่อกับ Controller ที่มีอยู่

อัปเดต `_handleRegisterAndCreatePet` ใน `auth_onboarding_screen.dart`:

```dart
Future<void> _handleRegisterAndCreatePet() async {
  FocusManager.instance.primaryFocus?.unfocus();
  setState(() { _isLoading = true; _errorMessage = null; });

  final auth = context.read<AuthController>();

  // 1. ลงทะเบียน User
  final success = await auth.register(
    _email.text.trim(),
    _password.text,
    _ownerName.text.trim(),
  );
  if (!mounted) return;
  if (!success) {
    setState(() { _isLoading = false; _errorMessage = auth.error; });
    return;
  }

  try {
    // 2. สร้าง Pet ใน Supabase
    final petRepo = SupabasePetRepository();
    final newPet = await petRepo.createPet(
      name: _petNameOrDefault,
      species: _species,
      breed: _breed.text.trim().isEmpty ? null : _breed.text.trim(),
      gender: _gender,
      dateOfBirth: DateTime(_birthYear, _birthMonth, _birthDay),
      weightKg: double.tryParse(_weight.text.trim()),
    );

    // 3. บันทึก Pet ID
    await auth.setPetId(newPet.id.hashCode);

    _openHome();
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _errorMessage = 'Account created but failed to create pet. Error: $e';
    });
    _openHome(); // ให้เข้าใช้งานได้ก่อน แล้วค่อยเพิ่ม pet ทีหลัง
  }
}
```

## 4. Storage สำหรับรูปภาพ

ถ้าต้องการอัปโหลดรูปภาพ (เช่น รูปสัตว์เลี้ยง, รูปสำหรับประเมินสุขภาพ):

```sql
-- สร้าง Storage bucket ใน Supabase Dashboard → Storage
-- Bucket name: pet-images
-- Make it public

-- หรือใช้คำสั่ง SQL
INSERT INTO storage.buckets (id, name, public)
VALUES ('pet-images', 'pet-images', true);

-- Policy สำหรับอัปโหลดรูป
CREATE POLICY "Users can upload pet images"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'pet-images' AND auth.uid()::text = (storage.foldername(name))[1]);
```

อัปโหลดรูปใน Dart:
```dart
// อัปโหลดรูป
final file = File('path/to/image.jpg');
final fileName = '${auth.userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';

await Supabase.instance.client
    .storage
    .from('pet-images')
    .upload(fileName, file);

// ได้ URL มา
final imageUrl = Supabase.instance.client
    .storage
    .from('pet-images')
    .getPublicUrl(fileName);
```

## 5. Quick Test

```dart
// Test สร้าง pet ใหม่
void testCreatePet() async {
  final repo = SupabasePetRepository();

  try {
    final pet = await repo.createPet(
      name: 'Milo',
      species: 'Cat',
      gender: 'Male',
      breed: 'Siamese',
      dateOfBirth: DateTime(2020, 1, 1),
      weightKg: 4.5,
    );
    print('Created pet: ${pet.name} (ID: ${pet.id})');
  } catch (e) {
    print('Error: $e');
  }
}

// Test ดึง pets ทั้งหมด
void testGetPets() async {
  final repo = SupabasePetRepository();

  try {
    final pets = await repo.getUserPets();
    print('Found ${pets.length} pets:');
    for (final pet in pets) {
      print('  - ${pet.name} (${pet.species})');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## สรุป

1. **สร้างตาราง**ใน Supabase Dashboard ด้วย SQL ด้านบน
2. **ใช้ SupabasePetRepository** สำหรับจัดการข้อมูลสัตว์เลี้ยง
3. **ใช้ SupabaseAssessmentRepository** สำหรับบันทึกผลการประเมิน
4. **RLS Policy** ช่วยให้ข้อมูลปลอดภัย - ผู้ใช้เห็นเฉพาะข้อมูลของตัวเอง
