part of 'home_screen.dart';

extension _HomeConsultScreenPart on _HomeScreenState {
  String _chatTimeLabel() {
    final now = DateTime.now();
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  void _openVetChat(_VetData vet) {
    _chatMessageController.clear();
    _update(() {
      _activeView = _View.consult;
      _activeChatVet = vet;
    });
  }

  void _closeVetChat() {
    _update(() {
      _activeChatVet = null;
    });
  }

  void _sendChatText() {
    final vet = _activeChatVet;
    final text = _chatMessageController.text.trim();
    if (vet == null || text.isEmpty) return;
    _chatMessageController.clear();
    _update(() {
      _conversationForVet(vet.id).add(
        _VetChatMessageData(
          fromVet: false,
          timeLabel: _chatTimeLabel(),
          text: text,
        ),
      );
    });
    _queueVetReply(
      vet,
      vet.online
          ? 'Got it. I\'m reviewing that now and will guide you next.'
          : 'I saved your message for ${vet.name}. They\'ll reply when they\'re back online.',
    );
  }

  void _startVetCall(_VetData vet) {
    _showPreviewSnackBar('Calling ${vet.name}');
  }

  void _sharePetProfileWithVet() {
    final vet = _activeChatVet;
    if (vet == null) return;
    _update(() {
      _conversationForVet(vet.id).add(
        _VetChatMessageData(
          fromVet: false,
          timeLabel: _chatTimeLabel(),
          title: '${_activePet.name} Profile',
          text:
              '${_activePet.species} • ${_activePet.breed}\n${_activePet.ageLabel} • ${_activePet.weightLabel}\nStatus: ${_activePet.status}',
          icon: Icons.pets_rounded,
          tint: AppTheme.accentColor,
        ),
      );
    });
    _queueVetReply(
      vet,
      'Received ${_activePet.name}\'s profile. I\'ll use this for context.',
    );
  }

  void _shareHealthSnapshotWithVet() {
    final vet = _activeChatVet;
    if (vet == null) return;
    _update(() {
      _conversationForVet(vet.id).add(
        _VetChatMessageData(
          fromVet: false,
          timeLabel: _chatTimeLabel(),
          title: 'Health Snapshot',
          text:
              'Happiness: 85%\nEnergy: 40%\nCurrent status: ${_activePet.status}\nLatest weight: ${_activePet.weightLabel}',
          icon: Icons.favorite_rounded,
          tint: AppTheme.primaryColor,
        ),
      );
    });
    _queueVetReply(vet, 'Thanks. The snapshot came through clearly.');
  }

  void _shareAiCheckWithVet({_VetData? vetOverride}) {
    final vet = vetOverride ?? _activeChatVet;
    if (vet == null) return;
    final latestCheck = _HomeScreenState._history.first;
    _update(() {
      _conversationForVet(vet.id).add(
        _VetChatMessageData(
          fromVet: false,
          timeLabel: _chatTimeLabel(),
          title: 'AI Health Check',
          text: '${latestCheck.title}\n${latestCheck.result}',
          icon: Icons.auto_awesome_rounded,
          tint: AppTheme.secondaryColor,
        ),
      );
    });
    _queueVetReply(
      vet,
      'I received the AI health check. I\'ll review the summary and recommend the next step.',
    );
  }

  void _queueVetReply(_VetData vet, String message) {
    Timer(const Duration(milliseconds: 850), () {
      if (!mounted) return;
      _update(() {
        _conversationForVet(vet.id).add(
          _VetChatMessageData(
            fromVet: true,
            timeLabel: _chatTimeLabel(),
            text: message,
          ),
        );
      });
    });
  }

  Widget _buildConsultView(BuildContext context) {
    final visibleVets = _HomeScreenState._vets
        .where((vet) => _vetFilter == _VetFilter.all || vet.online)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftReveal(
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                'Assistant',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
          const SizedBox(height: 18),
          _SoftReveal(
            delay: 0.08,
            child: Row(
              children: [
                Expanded(
                  child: _ConsultActionCard(
                    dark: true,
                    icon: Icons.auto_awesome_rounded,
                    title: 'Smart AI Scan',
                    subtitle: 'Health insights',
                    onTap: () {
                      _update(() {
                        _showAssessment = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _ConsultActionCard(
                    dark: false,
                    icon: Icons.camera_alt_rounded,
                    title: 'Photo Analysis',
                    subtitle: 'Upload to Scan',
                    onTap: () {
                      _update(() {
                        _showAssessment = true;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SoftReveal(
            delay: 0.16,
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Talk to a Vet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _FilterToggle(
                  current: _vetFilter,
                  onChanged: (filter) {
                    _update(() {
                      _vetFilter = filter;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in visibleVets.indexed) ...[
            _SoftReveal(
              delay: 0.22 + (entry.$1 * 0.05),
              child: _VetCard(
                vet: entry.$2,
                onChat: () => _openVetChat(entry.$2),
                onCall: entry.$2.online ? () => _startVetCall(entry.$2) : null,
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 18),
          _SoftReveal(
            delay: 0.34,
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Recent Consultations',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.secondaryText,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _update(() {
                      _activeView = _View.history;
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'View All',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final entry in _HomeScreenState._history.take(3).indexed) ...[
            _SoftReveal(
              delay: 0.4 + (entry.$1 * 0.05),
              child: _HistoryPreviewCard(item: entry.$2),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  Widget _buildVetChatModal(BuildContext context) {
    final vet = _activeChatVet!;
    final conversation = _conversationForVet(vet.id);
    return _BottomOverlay(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.86,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.98),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.16),
                    width: 1.3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.045),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withValues(
                              alpha: 0.16,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          vet.name.substring(4, 5),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vet.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vet.specialty,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppTheme.primaryColor,
                                  letterSpacing: 1,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _SquareIconButton(
                      icon: Icons.call_rounded,
                      onTap: () => _startVetCall(vet),
                    ),
                    const SizedBox(width: 8),
                    _SquareIconButton(
                      icon: Icons.close_rounded,
                      onTap: _closeVetChat,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _VetChatQuickAction(
                      icon: Icons.pets_rounded,
                      label: 'Pet Profile',
                      color: AppTheme.accentColor,
                      onTap: _sharePetProfileWithVet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VetChatQuickAction(
                      icon: Icons.favorite_rounded,
                      label: 'Snapshot',
                      color: AppTheme.primaryColor,
                      onTap: _shareHealthSnapshotWithVet,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _VetChatQuickAction(
                      icon: Icons.auto_awesome_rounded,
                      label: 'AI Check',
                      color: AppTheme.secondaryColor,
                      onTap: _shareAiCheckWithVet,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF7),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppTheme.primaryColor.withValues(alpha: 0.10),
                  ),
                ),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  itemCount: conversation.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _VetChatBubble(message: conversation[index]);
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.22),
                      width: 1.6,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.10),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _chatMessageController,
                          cursorColor: AppTheme.primaryColor,
                          cursorWidth: 2.4,
                          cursorHeight: 24,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppTheme.secondaryText,
                                fontWeight: FontWeight.w700,
                              ),
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            hintStyle: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: AppTheme.mutedText.withValues(
                                    alpha: 0.82,
                                  ),
                                  fontWeight: FontWeight.w600,
                                ),
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendChatText(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _sendChatText,
                        borderRadius: BorderRadius.circular(22),
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
