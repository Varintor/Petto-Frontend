import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';

enum NfcWriteStatus {
  success,
  unsupported,
  disabled,
  readOnly,
  tooSmall,
  cancelled,
  failed,
}

class NfcWriteResult {
  const NfcWriteResult(this.status, this.message);

  final NfcWriteStatus status;
  final String message;

  bool get succeeded => status == NfcWriteStatus.success;
}

/// Writes the revocable public Pet Health Card URL to a standard NDEF tag.
///
/// The tag contains only the bearer URL. Health data remains in the backend,
/// so rotating or revoking the public-card token immediately invalidates both
/// QR codes and previously written NFC tags.
class NfcPetCardService {
  NfcManager? _manager;
  Completer<NfcWriteResult>? _pending;
  bool _sessionActive = false;
  bool _handlingTag = false;

  bool get isSupportedPlatform =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<NfcWriteResult> writeUrl(
    String url, {
    Duration timeout = const Duration(seconds: 45),
  }) async {
    if (!isSupportedPlatform) {
      return const NfcWriteResult(
        NfcWriteStatus.unsupported,
        'NFC writing is available on supported Android phones.',
      );
    }
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      return const NfcWriteResult(
        NfcWriteStatus.failed,
        'The Pet Health Card link is invalid.',
      );
    }

    final manager = NfcManager.instance;
    _manager = manager;
    final availability = await manager.checkAvailability();
    if (availability == NfcAvailability.unsupported) {
      return const NfcWriteResult(
        NfcWriteStatus.unsupported,
        'This phone does not support NFC.',
      );
    }
    if (availability != NfcAvailability.enabled) {
      return const NfcWriteResult(
        NfcWriteStatus.disabled,
        'Turn on NFC in the phone settings and try again.',
      );
    }

    final message = buildPetHealthCardNdef(url);
    final completer = Completer<NfcWriteResult>();
    _pending = completer;
    _handlingTag = false;
    try {
      _sessionActive = true;
      await manager.startSession(
        pollingOptions: const {NfcPollingOption.iso14443},
        alertMessageIos: 'Hold the Petto NFC tag near the top of this iPhone.',
        invalidateAfterFirstReadIos: false,
        onSessionErrorIos: (error) {
          _sessionActive = false;
          _complete(
            const NfcWriteResult(
              NfcWriteStatus.cancelled,
              'NFC writing was cancelled.',
            ),
          );
        },
        onDiscovered: (tag) async {
          if (_handlingTag || completer.isCompleted) return;
          _handlingTag = true;
          try {
            final ndef = Ndef.from(tag);
            if (ndef == null) {
              await _finish(
                const NfcWriteResult(
                  NfcWriteStatus.unsupported,
                  'This tag is not NDEF compatible. Try an NTAG213/215/216 tag.',
                ),
                errorMessageIos: 'This NFC tag is not NDEF compatible.',
              );
              return;
            }
            if (!ndef.isWritable) {
              await _finish(
                const NfcWriteResult(
                  NfcWriteStatus.readOnly,
                  'This NFC tag is read-only. Use another writable tag.',
                ),
                errorMessageIos: 'This NFC tag is read-only.',
              );
              return;
            }
            if (ndef.maxSize < message.byteLength) {
              await _finish(
                const NfcWriteResult(
                  NfcWriteStatus.tooSmall,
                  'This NFC tag does not have enough storage for the link.',
                ),
                errorMessageIos: 'This NFC tag is too small.',
              );
              return;
            }
            await ndef.write(message: message);
            await _finish(
              const NfcWriteResult(
                NfcWriteStatus.success,
                'Pet Health Card written to the NFC tag.',
              ),
              alertMessageIos: 'Pet Health Card written successfully.',
            );
          } catch (_) {
            await _finish(
              const NfcWriteResult(
                NfcWriteStatus.failed,
                'Could not write the NFC tag. Keep it still and try again.',
              ),
              errorMessageIos: 'Could not write this NFC tag.',
            );
          }
        },
      );
      return await completer.future.timeout(
        timeout,
        onTimeout: () async {
          await cancel();
          return const NfcWriteResult(
            NfcWriteStatus.cancelled,
            'No NFC tag was detected. Try again and hold the tag closer.',
          );
        },
      );
    } catch (_) {
      await cancel();
      return const NfcWriteResult(
        NfcWriteStatus.failed,
        'NFC could not start. Close other NFC apps and try again.',
      );
    } finally {
      _pending = null;
      _handlingTag = false;
    }
  }

  Future<void> _finish(
    NfcWriteResult result, {
    String? alertMessageIos,
    String? errorMessageIos,
  }) async {
    if (_sessionActive) {
      _sessionActive = false;
      try {
        await _manager?.stopSession(
          alertMessageIos: alertMessageIos,
          errorMessageIos: errorMessageIos,
        );
      } catch (_) {
        // The OS may already have closed an iOS reader session.
      }
    }
    _complete(result);
  }

  void _complete(NfcWriteResult result) {
    final pending = _pending;
    if (pending != null && !pending.isCompleted) pending.complete(result);
  }

  Future<void> cancel() async {
    if (_sessionActive) {
      _sessionActive = false;
      try {
        await _manager?.stopSession();
      } catch (_) {
        // Cancellation is best effort because the platform may close first.
      }
    }
    _complete(
      const NfcWriteResult(
        NfcWriteStatus.cancelled,
        'NFC writing was cancelled.',
      ),
    );
  }
}

@visibleForTesting
NdefMessage buildPetHealthCardNdef(String url) {
  // NFC Forum URI Record Type Definition: TNF well-known, type "U", URI
  // identifier code 0x00 (no abbreviation), followed by the UTF-8 URL.
  final payload = Uint8List.fromList([0x00, ...utf8.encode(url)]);
  return NdefMessage(
    records: [
      NdefRecord(
        typeNameFormat: TypeNameFormat.wellKnown,
        type: Uint8List.fromList(const [0x55]),
        identifier: Uint8List(0),
        payload: payload,
      ),
    ],
  );
}
