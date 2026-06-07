import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ishi/components/gameplay/displays/targeting_banner.dart';
import 'package:ishi/core/managers/game_manager.dart';
import 'package:ishi/core/models/ishi_card.dart';
import 'package:ishi/core/models/relic/relic.dart';
import 'package:ishi/core/data_types.dart' show isPc;
import '../../animated_card_list/animated_card_list.dart';
import '../animated_play_button.dart';
import '../card_counter.dart';
import '../hand_controls.dart';
import '../relic_display.dart';

class LowerPanel extends StatefulWidget {
  final GameManager manager;
  final List<IshiCard> currentHand;
  final bool isMyTurn;
  final Relic? activeTargetingRelic;
  final IshiCard? selectedCard;
  final Key? animatedListKey;
  final List<IshiCard> relicTargets;
  final ScrollController? scrollController;

  // Callbacks
  final VoidCallback onEndTurn;
  final VoidCallback onFlipAllCards;
  final VoidCallback onTakePenalty;
  final void Function(DeckSortType) onSortHand;
  final VoidCallback onToggleAutoSort;
  final void Function(IshiCard) onPlayCard;
  final void Function(IshiCard) onTapCard;
  final bool? Function(bool, Relic) onTapRelic;
  final VoidCallback onCancelRelicTargeting;
  final Future<bool?> Function() onConfirmRelicTargeting;

  const LowerPanel({
    super.key,
    required this.manager,
    required this.currentHand,
    required this.isMyTurn,
    required this.activeTargetingRelic,
    required this.selectedCard,
    required this.animatedListKey,
    required this.relicTargets,
    required this.scrollController,
    required this.onEndTurn,
    required this.onFlipAllCards,
    required this.onTakePenalty,
    required this.onSortHand,
    required this.onToggleAutoSort,
    required this.onPlayCard,
    required this.onTapCard,
    required this.onTapRelic,
    required this.onCancelRelicTargeting,
    required this.onConfirmRelicTargeting,
  });

  @override
  State<LowerPanel> createState() => _LowerPanelState();
}

class _LowerPanelState extends State<LowerPanel> {
  bool _isViewingRelics = false;
  late GameManager _manager;

  @override
  void initState() {
    super.initState();
    _manager = widget.manager;
  }

  @override
  Widget build(BuildContext context) {
    final playerRelics = _manager.playerRelics[_manager.localPlayerIndex];

    Widget? targetingBanner;
    if (widget.activeTargetingRelic != null) {
      targetingBanner = TargetingBanner(
        activeRelic: widget.activeTargetingRelic!,
        currentTargetsCount: widget.relicTargets.length,
        onCancel: widget.onCancelRelicTargeting,
        onConfirm: () async {
          final isViewingRelics = await widget.onConfirmRelicTargeting();
          if (isViewingRelics != null && mounted) {
            setState(() => _isViewingRelics = isViewingRelics);
          }
        },
      ).animate().fadeIn().slideY(begin: 0.5);
    }

    final desktopContent = Column(
      mainAxisSize: .min,
      mainAxisAlignment: .end,
      children: [
        Row(
          mainAxisAlignment: .center,
          children: [
            CardCounter(currentHandLength: widget.currentHand.length),
            if (playerRelics.isNotEmpty) ...[
              const SizedBox(width: 16),
              _cardViewSwapButton.animate().fadeIn().slideX(),
            ],
          ],
        ),
        if (widget.activeTargetingRelic != null) ...[
          const SizedBox(height: 16),
          targetingBanner!,
        ],
        if (widget.activeTargetingRelic == null && !_isViewingRelics) ...[
          HandControls(
            onEndTurn: widget.onEndTurn,
            onFlipAllCard: widget.onFlipAllCards,
            onSortHand: widget.onSortHand,
            onTakePenalty: widget.onTakePenalty,
            onToggleAutoSort: widget.onToggleAutoSort,
            manager: _manager,
            isMyTurn: widget.isMyTurn,
          ),
          AnimatedPlayButton(
            selectedCard: widget.selectedCard,
            isMyTurn: widget.isMyTurn,
            onPlay: () async => widget.onPlayCard(widget.selectedCard!),
          ),
        ],
        Container(
          height: 280,
          padding: const .symmetric(horizontal: 8, vertical: 12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: child),
            ),
            child: _isViewingRelics
                ? SizedBox(
                    key: const ValueKey('relics_view'),
                    child: _buildRelicDisplay,
                  )
                : _cardsDisplay,
          ),
        ),
        SizedBox(height: _isViewingRelics ? 32 : 16),
      ],
    );

    final mobileContent = Stack(
      clipBehavior: .none,
      children: [
        Transform.translate(
          offset: const Offset(0, 104),
          child: Container(
            padding: const .symmetric(horizontal: 8, vertical: 12),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _isViewingRelics
                  ? SizedBox(
                      key: const ValueKey('relics_view'),
                      child: _buildRelicDisplay,
                    )
                  : _cardsDisplay,
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 16,
          child: Row(
            mainAxisAlignment: .center,
            children: [
              CardCounter(currentHandLength: widget.currentHand.length),
              if (playerRelics.isNotEmpty) ...[
                const SizedBox(width: 16),
                _cardViewSwapButton.animate().fadeIn().slideX(),
              ],
            ],
          ),
        ),
        if (widget.activeTargetingRelic != null) ...[
          const SizedBox(height: 16),
          targetingBanner!,
        ],
        if (widget.activeTargetingRelic == null && !_isViewingRelics) ...[
          Positioned(
            bottom: 0,
            right: 0,
            child: HandControls(
              onEndTurn: widget.onEndTurn,
              onFlipAllCard: widget.onFlipAllCards,
              onSortHand: widget.onSortHand,
              onTakePenalty: widget.onTakePenalty,
              onToggleAutoSort: widget.onToggleAutoSort,
              manager: _manager,
              isMyTurn: widget.isMyTurn,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 128,
            child: Row(
              mainAxisAlignment: .center,
              mainAxisSize: .min,
              children: [
                AnimatedPlayButton(
                  selectedCard: widget.selectedCard,
                  isMyTurn: widget.isMyTurn,
                  onPlay: () async => widget.onPlayCard(widget.selectedCard!),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    return isPc ? desktopContent : mobileContent;
  }

  ElevatedButton get _cardViewSwapButton => ElevatedButton.icon(
    onPressed: () => setState(() => _isViewingRelics = !_isViewingRelics),
    label: Text(_isViewingRelics ? "VIEW CARDS" : "VIEW RELICS"),
    icon: Icon(_isViewingRelics ? Icons.style : Icons.auto_awesome),
    style: ElevatedButton.styleFrom(
      backgroundColor: _isViewingRelics
          ? Colors.grey.shade800
          : Colors.amber.shade700,
      foregroundColor: Colors.white,
    ),
  );

  Widget get _cardsDisplay {
    final animatedCardList = AnimatedCardList(
      animatedListKey: widget.animatedListKey,
      currentHand: widget.currentHand,
      selectedCards: widget.activeTargetingRelic != null
          ? widget.relicTargets
          : (widget.selectedCard != null ? [widget.selectedCard!] : []),
      onTapCard: widget.onTapCard,
      scrollController: widget.scrollController,
      isMyTurn: widget.isMyTurn,
      event: _manager.activeDeckEvent,
      isPlayable: (card) {
        if (widget.activeTargetingRelic != null) return true;
        return _manager.canPlay(card, _manager.localPlayerIndex).canPlay;
      },
    );

    return RawScrollbar(
      key: ValueKey(widget.scrollController),
      controller: widget.scrollController,
      thumbColor: isPc ? Colors.black26 : Colors.transparent,
      radius: const .circular(8),
      thickness: 6,
      child: Transform.scale(scale: isPc ? 1 : 0.6, child: animatedCardList),
    );
  }

  Widget get _buildRelicDisplay => RelicDisplay(
    relics: _manager.playerRelics[_manager.localPlayerIndex],
    onTapRelic: (isActiveRelic, relic) {
      final isViewingRelics = widget.onTapRelic(isActiveRelic, relic);
      if (isViewingRelics != null) {
        setState(() => _isViewingRelics = isViewingRelics);
      }
    },
  );
}
