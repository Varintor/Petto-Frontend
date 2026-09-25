part of 'vet_portal_screen.dart';

class _BackendConversationScreen extends StatelessWidget {
  const _BackendConversationScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(child: _BackendConversationPanel(showBack: true)),
    );
  }
}

class _BackendConversationPanel extends StatefulWidget {
  const _BackendConversationPanel({this.showBack = false});

  final bool showBack;

  @override
  State<_BackendConversationPanel> createState() =>
      _BackendConversationPanelState();
}

class _BackendConversationPanelState extends State<_BackendConversationPanel> {
  final _message = TextEditingController();
  final _conversationScrollController = ScrollController();
  int? _visibleConsultationId;
  int _visibleConversationItemCount = -1;
  bool _sending = false;
  bool _proposingAppointment = false;
  int? _changingAppointmentId;

  @override
  void dispose() {
    _conversationScrollController.dispose();
    _message.dispose();
    super.dispose();
  }

  void _scheduleScrollToLatest(int consultationId, int itemCount) {
    if (_visibleConsultationId == consultationId &&
        _visibleConversationItemCount == itemCount) {
      return;
    }
    _visibleConsultationId = consultationId;
    _visibleConversationItemCount = itemCount;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_conversationScrollController.hasClients) return;
      _conversationScrollController.animateTo(
        _conversationScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final sent = await context.read<ConsultationController>().sendMessage(text);
    if (!mounted) return;
    if (sent) _message.clear();
    setState(() => _sending = false);
  }

  void _useQuickReply(String text) {
    _message.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _proposeAppointment() async {
    if (_proposingAppointment) return;
    final now = DateTime.now();
    final schedule = await _showVetScheduleDialog(
      initialDateTime: now.add(const Duration(days: 1)),
      title: 'Plan appointment',
      subtitle: 'Pick a gentle follow-up time for this pet.',
      actionLabel: 'Propose',
    );
    if (schedule == null || !mounted) return;
    if (!schedule.startsAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose an appointment time in the future.'),
        ),
      );
      return;
    }

    setState(() => _proposingAppointment = true);
    await context.read<ConsultationController>().proposeAppointment(
      startsAt: schedule.startsAt,
      reason: schedule.reason,
    );
    if (!mounted) return;
    setState(() => _proposingAppointment = false);
  }

  Future<void> _rescheduleAppointment(AppointmentModel appointment) async {
    if (_changingAppointmentId != null) return;
    final now = DateTime.now();
    final schedule = await _showVetScheduleDialog(
      initialDateTime: appointment.startsAt.isAfter(now)
          ? appointment.startsAt
          : now.add(const Duration(days: 1)),
      initialReason: appointment.reason ?? '',
      title: 'Reschedule visit',
      subtitle: 'Move this appointment to a clearer time.',
      actionLabel: 'Update',
    );
    if (schedule == null || !mounted) return;
    if (!schedule.startsAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a time in the future.')),
      );
      return;
    }

    setState(() => _changingAppointmentId = appointment.id);
    await context.read<ConsultationController>().updateAppointment(
      appointment.id,
      startsAt: schedule.startsAt,
      reason: schedule.reason,
    );
    if (!mounted) return;
    setState(() => _changingAppointmentId = null);
  }

  Future<_VetScheduleResult?> _showVetScheduleDialog({
    required DateTime initialDateTime,
    required String title,
    required String subtitle,
    required String actionLabel,
    String initialReason = '',
  }) {
    return showDialog<_VetScheduleResult>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (dialogContext) => _VetScheduleDialog(
        initialDateTime: initialDateTime,
        initialReason: initialReason,
        title: title,
        subtitle: subtitle,
        actionLabel: actionLabel,
      ),
    );
  }

  Future<void> _cancelAppointment(AppointmentModel appointment) async {
    if (_changingAppointmentId != null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel appointment?'),
        content: const Text(
          'If accepted, it will also be removed from the owner’s Calendar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Keep appointment'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel appointment'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _changingAppointmentId = appointment.id);
    await context.read<ConsultationController>().cancelAppointment(
      appointment.id,
    );
    if (!mounted) return;
    setState(() => _changingAppointmentId = null);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConsultationController>(
      builder: (context, controller, _) {
        final consultation = controller.active;
        if (consultation == null) {
          return _VetLoadState(
            message:
                controller.error ??
                'Select a consultation to read its messages.',
            onRetry: controller.error == null
                ? null
                : controller.loadVetConsultations,
          );
        }
        _scheduleScrollToLatest(
          consultation.id,
          controller.messages.length +
              controller.appointments.length +
              controller.sharedAssessments.length +
              controller.sharedHealthCards.length,
        );
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
              child: _Panel(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    if (widget.showBack) ...[
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                        color: AppTheme.primaryColor,
                        style: IconButton.styleFrom(
                          backgroundColor: _VetUi.blush,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _PetBadge(species: consultation.petSpecies ?? 'Pet'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            consultation.petName ??
                                'Pet #${consultation.petId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.secondaryText,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: AppTheme.displayFontFamily,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _ConnectionPill(
                            connected: controller.realtimeConnected,
                          ),
                        ],
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Propose appointment',
                      onPressed: _proposingAppointment || consultation.isClosed
                          ? null
                          : _proposeAppointment,
                      icon: _proposingAppointment
                          ? const PettoButtonProgress(
                              onDark: false,
                              width: 20,
                              height: 6,
                            )
                          : const Icon(Icons.event_available_rounded),
                      color: AppTheme.primaryColor,
                      style: IconButton.styleFrom(
                        backgroundColor: _VetUi.blush,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      tooltip: 'Refresh messages',
                      onPressed: controller.loading
                          ? null
                          : controller.refreshMessages,
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppTheme.primaryColor,
                      style: IconButton.styleFrom(
                        backgroundColor: _VetUi.cream,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                child: _InlineAlert(message: controller.error!),
              ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(18, 4, 18, 0),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.48),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: _VetUi.border),
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    controller.loading &&
                        controller.messages.isEmpty &&
                        controller.appointments.isEmpty
                    ? const _AssistantLoading()
                    : _ConversationList(
                        controller: controller,
                        scrollController: _conversationScrollController,
                        changingAppointmentId: _changingAppointmentId,
                        onRescheduleAppointment: _rescheduleAppointment,
                        onCancelAppointment: _cancelAppointment,
                      ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                10,
                18,
                18 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: consultation.isClosed
                  ? _Panel(
                      padding: const EdgeInsets.all(14),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: AppTheme.primaryColor,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This consultation is closed. Messages are read-only.',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _VetQuickReplies(
                          petName:
                              consultation.petName ??
                              'Pet #${consultation.petId}',
                          enabled: !_sending,
                          onSelected: _useQuickReply,
                        ),
                        const SizedBox(height: 8),
                        _ChatComposer(
                          controller: _message,
                          sending: _sending,
                          onSend: _send,
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _VetQuickReplies extends StatelessWidget {
  const _VetQuickReplies({
    required this.petName,
    required this.enabled,
    required this.onSelected,
  });

  final String petName;
  final bool enabled;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final replies = <({Key key, IconData icon, String label, String message})>[
      (
        key: const Key('vet-request-health-card'),
        icon: Icons.badge_outlined,
        label: 'Request Health Card',
        message:
            "Please share $petName's Pet Health Card so I can review the latest health information.",
      ),
      (
        key: const Key('vet-quick-reply-photo'),
        icon: Icons.add_photo_alternate_outlined,
        label: 'Request photo',
        message: 'Please send a clear photo of the affected area.',
      ),
      (
        key: const Key('vet-quick-reply-monitor'),
        icon: Icons.monitor_heart_outlined,
        label: 'Monitor update',
        message:
            'Please monitor your pet and send me an update within 24 hours.',
      ),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final reply = replies[index];
          return ActionChip(
            key: reply.key,
            avatar: Icon(reply.icon, size: 17, color: AppTheme.primaryColor),
            label: Text(reply.label),
            onPressed: enabled ? () => onSelected(reply.message) : null,
            backgroundColor: _VetUi.surface,
            side: BorderSide(
              color: AppTheme.primaryColor.withValues(alpha: 0.16),
            ),
            labelStyle: const TextStyle(
              color: AppTheme.secondaryText,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({
    required this.controller,
    required this.scrollController,
    required this.changingAppointmentId,
    required this.onRescheduleAppointment,
    required this.onCancelAppointment,
  });

  final ConsultationController controller;
  final ScrollController scrollController;
  final int? changingAppointmentId;
  final ValueChanged<AppointmentModel> onRescheduleAppointment;
  final ValueChanged<AppointmentModel> onCancelAppointment;

  @override
  Widget build(BuildContext context) {
    final empty =
        controller.messages.isEmpty &&
        controller.appointments.isEmpty &&
        controller.sharedAssessments.isEmpty &&
        controller.sharedHealthCards.isEmpty;
    if (empty) {
      return const _ChatEmptyState();
    }
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        for (final assessment in controller.sharedAssessments)
          SharedAssessmentPanel(assessment: assessment),
        for (final sharedCard in controller.sharedHealthCards)
          SharedHealthCardPanel(card: sharedCard),
        for (final appointment in controller.appointments)
          ConsultationAppointmentCard(
            appointment: appointment,
            busy: changingAppointmentId == appointment.id,
            onReschedule: appointment.canBeChanged
                ? () => onRescheduleAppointment(appointment)
                : null,
            onCancel: appointment.canBeChanged
                ? () => onCancelAppointment(appointment)
                : null,
          ),
        for (final message in controller.messages)
          _ChatBubble(
            text: message.content ?? 'Attachment',
            mine: message.isFromVet,
            time: message.createdAt,
          ),
      ],
    );
  }
}

class _ChatComposer extends StatelessWidget {
  const _ChatComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: _VetUi.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _VetUi.blush,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              color: AppTheme.primaryColor,
              size: 21,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Type a reply...',
                isCollapsed: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 50,
            height: 50,
            child: IconButton.filled(
              tooltip: 'Send message',
              onPressed: sending ? null : onSend,
              style: IconButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: sending
                  ? const PettoButtonProgress(width: 22, height: 6)
                  : const Icon(Icons.send_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _TintIcon(icon: Icons.forum_rounded, filled: true),
            const SizedBox(height: 12),
            const Text(
              'No messages yet',
              style: TextStyle(
                color: AppTheme.secondaryText,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                fontFamily: AppTheme.displayFontFamily,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start with a quick update or propose a follow-up appointment.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineAlert extends StatelessWidget {
  const _InlineAlert({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFEF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectionPill extends StatelessWidget {
  const _ConnectionPill({required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? const Color(0xFF6E8A54) : _VetUi.gold;
    return Container(
      key: const Key('vet-chat-connection-status'),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            connected ? 'Realtime connected' : 'Reconnecting',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantLoading extends StatelessWidget {
  const _AssistantLoading();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(child: PettoChatSkeleton());
  }
}
