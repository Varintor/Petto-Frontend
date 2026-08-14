import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/consultation_models.dart';
import '../controllers/consultation_controller.dart';

/// Authenticated owner-side Feature 3 workspace. Guest presentation data stays
/// in the legacy home preview, while every action here uses the backend.
class OwnerConsultationScreen extends StatefulWidget {
  const OwnerConsultationScreen({
    super.key,
    required this.petId,
    required this.petName,
    this.latestAssessmentId,
  });

  final int petId;
  final String petName;
  final int? latestAssessmentId;

  @override
  State<OwnerConsultationScreen> createState() =>
      _OwnerConsultationScreenState();
}

class _OwnerConsultationScreenState extends State<OwnerConsultationScreen> {
  final _messageController = TextEditingController();
  Timer? _refreshTimer;
  bool _sending = false;
  bool _includeLatestAssessment = false;

  @override
  void initState() {
    super.initState();
    _includeLatestAssessment = widget.latestAssessmentId != null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWorkspace());
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        context.read<ConsultationController>().refreshNewMessages();
      }
    });
  }

  @override
  void didUpdateWidget(covariant OwnerConsultationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.petId != widget.petId) {
      context.read<ConsultationController>().closeActiveConsultation();
      _loadWorkspace();
    }
    if (oldWidget.latestAssessmentId != widget.latestAssessmentId &&
        widget.latestAssessmentId != null) {
      _includeLatestAssessment = true;
    }
  }

  Future<void> _loadWorkspace() =>
      context.read<ConsultationController>().loadOwnerWorkspace(widget.petId);

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _startConsultation(VetModel vet) async {
    await context.read<ConsultationController>().startConsultation(
      petId: widget.petId,
      vetId: vet.id,
      assessmentId: _includeLatestAssessment ? widget.latestAssessmentId : null,
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final sent = await context.read<ConsultationController>().sendMessage(text);
    if (!mounted) return;
    if (sent) _messageController.clear();
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        final active = controller.active;
        if (active != null && active.petId == widget.petId) {
          return _conversation(controller, active);
        }
        return _directory(controller);
      },
    );
  }

  Widget _directory(ConsultationController controller) {
    if (controller.loading &&
        controller.vets.isEmpty &&
        controller.consultations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: _loadWorkspace,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 150),
        children: [
          const Text(
            'Veterinary Consultation',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppTheme.secondaryText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Persistent conversations for ${widget.petName}',
            style: const TextStyle(color: AppTheme.mutedText),
          ),
          if (controller.error != null) ...[
            const SizedBox(height: 12),
            _ErrorCard(message: controller.error!, onRetry: _loadWorkspace),
          ],
          if (widget.latestAssessmentId != null) ...[
            const SizedBox(height: 14),
            SwitchListTile.adaptive(
              value: _includeLatestAssessment,
              onChanged: (value) =>
                  setState(() => _includeLatestAssessment = value),
              title: const Text('Share latest AI health assessment'),
              subtitle: const Text(
                'The selected veterinarian receives the complete saved result.',
              ),
              secondary: const Icon(Icons.auto_awesome_rounded),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              tileColor: AppTheme.primaryColor.withValues(alpha: 0.06),
            ),
          ],
          if (controller.consultations.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionLabel('Existing consultations'),
            const SizedBox(height: 10),
            for (final consultation in controller.consultations)
              _ConsultationCard(
                consultation: consultation,
                onTap: () => controller.openConsultation(consultation),
              ),
          ],
          const SizedBox(height: 22),
          const _SectionLabel('Available Petto veterinarians'),
          const SizedBox(height: 10),
          if (controller.vets.isEmpty)
            const _EmptyCard(
              message: 'No verified veterinarian is available right now.',
            )
          else
            for (final vet in controller.vets)
              _VetCard(
                vet: vet,
                busy: controller.loading,
                onStart: () => _startConsultation(vet),
              ),
        ],
      ),
    );
  }

  Widget _conversation(
    ConsultationController controller,
    ConsultationModel consultation,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Back to consultations',
                onPressed: controller.closeActiveConsultation,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultation.vetName ??
                          'Veterinarian #${consultation.vetId}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${widget.petName} • ${consultation.status}',
                      style: const TextStyle(color: AppTheme.mutedText),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh messages',
                onPressed: controller.loading
                    ? null
                    : controller.refreshMessages,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
        ),
        if (controller.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              controller.error!,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        Expanded(
          child: controller.loading && controller.messages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : controller.messages.isEmpty
              ? const _EmptyCard(message: 'No messages yet. Say hello.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  itemCount: controller.messages.length,
                  itemBuilder: (context, index) =>
                      _OwnerMessageBubble(controller.messages[index]),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_sending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _sending ? null : _sendMessage,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
  );
}

class _ConsultationCard extends StatelessWidget {
  const _ConsultationCard({required this.consultation, required this.onTap});
  final ConsultationModel consultation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onTap,
      leading: const CircleAvatar(child: Icon(Icons.forum_rounded)),
      title: Text(
        consultation.vetName ?? 'Veterinarian #${consultation.vetId}',
      ),
      subtitle: Text(
        '${consultation.status} • ${consultation.providerName ?? 'Petto'}',
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
    ),
  );
}

class _VetCard extends StatelessWidget {
  const _VetCard({
    required this.vet,
    required this.busy,
    required this.onStart,
  });
  final VetModel vet;
  final bool busy;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        child: const Icon(Icons.medical_services_rounded),
      ),
      title: Text(
        vet.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(
        [vet.specialty, vet.clinicName].whereType<String>().join(' • '),
      ),
      trailing: FilledButton(
        onPressed: busy ? null : onStart,
        child: const Text('Consult'),
      ),
    ),
  );
}

class _OwnerMessageBubble extends StatelessWidget {
  const _OwnerMessageBubble(this.message);
  final ChatMessageModel message;

  @override
  Widget build(BuildContext context) {
    final mine = message.senderType == 'user';
    final status = message.readAt != null
        ? 'Read'
        : message.deliveredAt != null
        ? 'Delivered'
        : 'Sent';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.isAiBriefing)
              const Text(
                'AI briefing',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            Text(
              message.content ?? 'Shared attachment',
              style: TextStyle(color: mine ? Colors.white : null),
            ),
            const SizedBox(height: 4),
            Text(
              mine ? status : message.senderType.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: mine ? Colors.white70 : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Center(
      child: Text(message, style: const TextStyle(color: AppTheme.mutedText)),
    ),
  );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.red.withValues(alpha: 0.06),
    child: ListTile(
      leading: const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
      title: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
      trailing: TextButton(onPressed: onRetry, child: const Text('Retry')),
    ),
  );
}
