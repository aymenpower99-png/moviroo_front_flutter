import 'package:flutter/material.dart';
import '../../../../../theme/app_colors.dart';
import 'driver_row.dart';
import '../../components/pickup_drop_row.dart';
import '../../components/trip_summary_card.dart';
import '../../components/animated_progress_bar.dart';
import '../../models/ride_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BottomPanel
// ─────────────────────────────────────────────────────────────────────────────

class BottomPanel extends StatefulWidget {
  final RideState rideState;
  final VoidCallback? onContinue;
  final VoidCallback? onChatTap;

  /// Pickup location label shown in the pickup/drop row.
  final String pickupLabel;

  /// Drop-off location label shown in the pickup/drop row.
  final String dropLabel;

  const BottomPanel({
    super.key,
    required this.rideState,
    this.onContinue,
    this.onChatTap,
    this.pickupLabel = 'Pickup location',
    this.dropLabel = 'Drop-off location',
  });

  @override
  State<BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<BottomPanel>
    with SingleTickerProviderStateMixin {
  late final DraggableScrollableController _sheetCtrl;
  late final AnimationController _pulseController;

  bool get _isArrivalOrLater =>
      widget.rideState.phase == RidePhase.driverArrived ||
      widget.rideState.phase == RidePhase.rideInProgress ||
      widget.rideState.phase == RidePhase.rideEnded;

  double _targetSize(RidePhase phase) {
    switch (phase) {
      case RidePhase.driverArrived:
        return 0.60;
      case RidePhase.rideEnded:
        return 0.75;
      default:
        return 0.50;
    }
  }

  /// Maps phase to stage index for the timeline.
  int _stageIndex(RidePhase phase) {
    switch (phase) {
      case RidePhase.driverOnTheWay:
        return widget.rideState.progress < 0.05 ? 0 : 1;
      case RidePhase.driverArrived:
        return 1;
      case RidePhase.rideInProgress:
        return 2;
      case RidePhase.rideEnded:
        return 3;
    }
  }

  String _statusLabel(RidePhase phase) {
    switch (phase) {
      case RidePhase.driverOnTheWay:
        return 'Driver is on the way';
      case RidePhase.driverArrived:
        return 'Driver is arriving';
      case RidePhase.rideInProgress:
        return 'Enjoy your ride';
      case RidePhase.rideEnded:
        return 'You have arrived';
    }
  }

  String _dynamicStatusLabel(RidePhase phase, double progress) {
    switch (phase) {
      case RidePhase.driverOnTheWay:
        return progress < 0.8
            ? 'Driver is heading to your pickup'
            : 'Driver is almost at your location';
      case RidePhase.driverArrived:
        return 'Driver has arrived at pickup point';
      case RidePhase.rideInProgress:
        return progress < 0.8
            ? 'Your ride has started'
            : "You're almost at your destination";
      case RidePhase.rideEnded:
        return "You've arrived at your destination";
    }
  }

  @override
  void initState() {
    super.initState();
    _sheetCtrl = DraggableScrollableController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(BottomPanel old) {
    super.didUpdateWidget(old);
    if (widget.rideState.phase != old.rideState.phase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sheetCtrl.isAttached) {
          _sheetCtrl.animateTo(
            _targetSize(widget.rideState.phase),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sheetCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      controller: _sheetCtrl,
      initialChildSize: _targetSize(widget.rideState.phase),
      minChildSize: 0.18,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.18, 0.50, 0.60, 0.75, 0.85],
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: AppColors.border(context))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.border(context),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                if (widget.rideState.phase == RidePhase.rideEnded)
                  TripSummaryCard(
                    rideState: widget.rideState,
                    pickupLabel: widget.pickupLabel,
                    dropLabel: widget.dropLabel,
                    onContinue: widget.onContinue,
                  )
                else ...[
                  // ETA display
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${widget.rideState.etaMins} min left',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dynamicStatusLabel(
                                  widget.rideState.phase,
                                  widget.rideState.progress,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            widget.rideState.arrivalTime,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  AnimatedRideProgressBar(
                    phase: widget.rideState.phase,
                    progress: widget.rideState.progress,
                  ),

                  const SizedBox(height: 20),

                  DriverRow(
                    driverName: widget.rideState.driverName,
                    vehicleName: widget.rideState.vehicleName,
                    plateNumber: widget.rideState.plateNumber,
                    isArrived: _isArrivalOrLater,
                    onChatTap: widget.onChatTap,
                  ),

                  const SizedBox(height: 20),

                  PickupDropRow(
                    pickupLabel: widget.pickupLabel,
                    dropLabel: widget.dropLabel,
                  ),

                  const SizedBox(height: 24),

                  _StageTimeline(
                    activeIndex: _stageIndex(widget.rideState.phase),
                    statusLabel: _statusLabel(widget.rideState.phase),
                    pulseController: _pulseController,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stage Timeline
// ─────────────────────────────────────────────────────────────────────────────

class _StageTimeline extends StatelessWidget {
  final int activeIndex;
  final String statusLabel;
  final AnimationController pulseController;

  const _StageTimeline({
    required this.activeIndex,
    required this.statusLabel,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    const stages = ['Matched', 'Pickup', 'On trip', 'Arrived'];
    final purple = AppColors.primaryPurple;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Dots + line row ──
        Stack(
          alignment: Alignment.center,
          children: [
            // Background connecting line
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Row(
                children: List.generate(stages.length - 1, (index) {
                  final isCompleted = index < activeIndex;
                  return Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? purple
                            : AppColors.border(context),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // Dots row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(stages.length, (index) {
                final isCompleted = index < activeIndex;
                final isActive = index == activeIndex;

                return isActive
                    ? _ActiveDot(
                        pulseController: pulseController,
                        purple: purple,
                      )
                    : _InactiveDot(
                        isCompleted: isCompleted,
                        purple: purple,
                      );
              }),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Status label centered under active stage ──
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(stages.length, (index) {
            final isActive = index == activeIndex;
            return Expanded(
              child: Center(
                child: isActive
                    ? Text(
                        statusLabel,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: purple,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Active dot with smooth scale pulse ──
class _ActiveDot extends StatelessWidget {
  final AnimationController pulseController;
  final Color purple;

  const _ActiveDot({
    required this.pulseController,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseController,
      builder: (context, child) {
        final scale = Tween<double>(begin: 1.0, end: 1.25).evaluate(
          CurvedAnimation(
            parent: pulseController,
            curve: Curves.easeInOut,
          ),
        );
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: purple,
          boxShadow: [
            BoxShadow(
              color: purple.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Completed / Upcoming dot ──
class _InactiveDot extends StatelessWidget {
  final bool isCompleted;
  final Color purple;

  const _InactiveDot({
    required this.isCompleted,
    required this.purple,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? purple : Colors.transparent,
        border: Border.all(
          color: isCompleted ? purple : AppColors.border(context),
          width: 2,
        ),
      ),
      child: isCompleted
          ? const Center(
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 10,
              ),
            )
          : null,
    );
  }
}
