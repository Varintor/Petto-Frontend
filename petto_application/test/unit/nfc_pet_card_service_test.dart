import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:petto_application/src/core/services/nfc_pet_card_service.dart';

void main() {
  test('builds a standards-compliant NDEF URI record', () {
    const url = 'https://example.test/public/pet-card/token';

    final message = buildPetHealthCardNdef(url);

    expect(message.records, hasLength(1));
    final record = message.records.single;
    expect(record.typeNameFormat, TypeNameFormat.wellKnown);
    expect(record.type, [0x55]);
    expect(record.identifier, isEmpty);
    expect(record.payload.first, 0x00);
    expect(utf8.decode(record.payload.skip(1).toList()), url);
    expect(message.byteLength, greaterThan(url.length));
  });
}
