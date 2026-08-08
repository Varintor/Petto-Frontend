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

  void _shareAiCheckWithVet({
    _VetData? vetOverride,
    AssessmentEntity? assessmentOverride,
  }) {
    final vet = vetOverride ?? _activeChatVet;
    if (vet == null) return;
    final String title;
    final String result;
    if (assessmentOverride != null) {
      title = assessmentOverride.symptoms ?? 'AI Health Check';
      result = assessmentOverride.riskLevel;
    } else {
      final controller = context.read<HealthAssessmentController>();
      final assessments = controller.history;
      if (assessments.isNotEmpty) {
        final latest = assessments.first;
        title = latest.symptoms ?? 'AI Health Check';
        result = latest.riskLevel;
      } else {
        final latestCheck = _HomeScreenState._history.first;
        title = latestCheck.title;
        result = latestCheck.result;
      }
    }
    _update(() {
      _conversationForVet(vet.id).add(
        _VetChatMessageData(
          fromVet: false,
          timeLabel: _chatTimeLabel(),
          title: 'AI Health Check',
          text: '$title\n$result',
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

  void _loadAssessmentHistory() {
    // No pet yet (guest / fresh account) — leave the history empty rather
    // than fetching a shared default pet's data.
    final petId = context.read<AuthController>().petId;
    if (petId == null) return;
    context.read<HealthAssessmentController>().loadPetHistory(petId);
  }

  void _showAssessmentDetail(AssessmentEntity assessment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AssessmentDetailSheet(
        assessment: assessment,
        onShareWithVet: () => _shareAssessmentWithAvailableVet(assessment),
      ),
    );
  }

  void _shareAssessmentWithAvailableVet(AssessmentEntity assessment) {
    var vet = _activeChatVet;
    if (vet == null) {
      final onlineVets = _HomeScreenState._vets.where((v) => v.online);
      if (onlineVets.isEmpty) {
        _showPreviewSnackBar('No online vet available');
        return;
      }
      vet = onlineVets.first;
      _openVetChat(vet);
    }
    _shareAiCheckWithVet(vetOverride: vet, assessmentOverride: assessment);
  }

  void _openAssessmentDetailScreen(AssessmentEntity assessment) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: AppTheme.motionNormal,
        reverseTransitionDuration: AppTheme.motionFast,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _AssessmentDetailScreen(
            assessment: assessment,
            onShareWithVet: () => _shareAssessmentWithAvailableVet(assessment),
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: AppTheme.motionCurveSoft,
            reverseCurve: AppTheme.motionReverseCurve,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.004, 0.001),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  void _showAssessmentHistorySheet(List<AssessmentEntity> assessments) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: AppTheme.secondaryText.withValues(alpha: 0.18),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return _assistantBottomSheetFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Latest Checks',
                        style: Theme.of(ctx).textTheme.headlineSmall,
                      ),
                    ),
                    _SquareIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                  itemCount: assessments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final assessment = assessments[index];
                    return _AssessmentHistoryCard(
                      assessment: assessment,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        _openAssessmentDetailScreen(assessment);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVetDirectorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: AppTheme.secondaryText.withValues(alpha: 0.18),
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final visibleVets = _HomeScreenState._vets
            .where((vet) => _vetFilter == _VetFilter.all || vet.online)
            .toList();
        return _assistantBottomSheetFrame(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 22, 24, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Care Team',
                        style: Theme.of(ctx).textTheme.headlineSmall,
                      ),
                    ),
                    _FilterToggle(
                      current: _vetFilter,
                      onChanged: (filter) {
                        _update(() {
                          _vetFilter = filter;
                        });
                        Navigator.of(ctx).pop();
                        _showVetDirectorySheet();
                      },
                    ),
                    const SizedBox(width: 10),
                    _SquareIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: visibleVets.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final vet = visibleVets[index];
                    return _VetCard(
                      vet: vet,
                      onChat: () {
                        Navigator.of(ctx).pop();
                        _openVetChat(vet);
                      },
                      onCall: vet.online ? () => _startVetCall(vet) : null,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _assistantBottomSheetFrame({required Widget child}) {
    return SafeArea(
      top: false,
      child: FractionallySizedBox(
        heightFactor: 0.86,
        alignment: Alignment.bottomCenter,
        child: Container(
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: AppTheme.glassCardDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(42)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 46,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.only(top: 12), child: child),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsultView(BuildContext context) {
    final assessmentController = context.watch<HealthAssessmentController>();
    final assessments = assessmentController.history;
    final latestAssessment = assessments.isNotEmpty ? assessments.first : null;
    final onlineVetCount = _HomeScreenState._vets
        .where((vet) => vet.online)
        .length;
    final featuredVet = _HomeScreenState._vets.firstWhere(
      (vet) => vet.online,
      orElse: () => _HomeScreenState._vets.first,
    );

    // Load assessment history on first build if empty
    if (assessments.isEmpty && !assessmentController.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadAssessmentHistory();
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 150),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SoftReveal(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Assistant',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SoftReveal(
            delay: 0.04,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: AppTheme.glassCardDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.98),
                borderRadius: BorderRadius.circular(34),
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.14),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.medical_services_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What does ${_activePet.name} need today?',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Scan symptoms, review records, or open a care chat.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppTheme.mutedText,
                                height: 1.3,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _SoftReveal(
            delay: 0.12,
            child: _AssistantSummaryCard(
              icon: Icons.fact_check_rounded,
              title: 'Latest check',
              subtitle: assessmentController.isLoading && assessments.isEmpty
                  ? 'Loading health records...'
                  : latestAssessment?.symptoms ?? 'No assessment yet',
              meta: latestAssessment?.riskLevel ?? 'Start scan',
              onTap: latestAssessment == null
                  ? () {
                      _update(() {
                        _showAssessment = true;
                      });
                    }
                  : () => _openAssessmentDetailScreen(latestAssessment),
              trailingLabel: assessments.length > 1 ? 'View all' : 'Refresh',
              onTrailingTap: assessments.length > 1
                  ? () => _showAssessmentHistorySheet(assessments)
                  : _loadAssessmentHistory,
            ),
          ),
          const SizedBox(height: 12),
          _SoftReveal(
            delay: 0.16,
            child: _AssistantSummaryCard(
              icon: Icons.support_agent_rounded,
              title: 'Care team',
              subtitle:
                  '${featuredVet.name} • ${featuredVet.specialty}\nShare ${_activePet.name}\'s profile, latest checks, and notes in chat.',
              meta: '$onlineVetCount online',
              onTap: () => _openVetChat(featuredVet),
              trailingLabel: 'Open',
              onTrailingTap: _showVetDirectorySheet,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVetChatModal(BuildContext context) {
    final vet = _activeChatVet!;
    final conversation = _conversationForVet(vet.id);
    return _BottomOverlay(
      expand: true,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor.withValues(alpha: 0.98),
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
                          color: AppTheme.primaryColor.withValues(alpha: 0.16),
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
                color: AppTheme.surfaceColor.withValues(alpha: 0.72),
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
                        scrollPadding: EdgeInsets.only(
                          bottom: MediaQuery.viewInsetsOf(context).bottom + 120,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
    );
  }
}
