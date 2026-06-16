part of track_ride_page;
// ── Build mixin ───────────────────────────────────────────────────────────────
// Contains the build() method and all widget-building helpers.
// ─────────────────────────────────────────────────────────────────────────────

mixin _TrackRideBuildMixin
    on State<TrackRidePage>, _TrackRideStateMixin, _TrackRideCallbacksMixin {
  Widget buildPage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isRideEnded = rideState.phase == RidePhase.rideEnded;

    return PopScope(
      canPop: !isRideEnded,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isRideEnded) {
          // Ride is over — back button must go to home, not back to tracking
          AppRouter.clearAndGo(context, AppRouter.home);
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: AppColors.bg(context),
          body: Stack(
            fit: StackFit.expand,
            children: [
            // ── Mapbox Map ──────────────────────────────────────────────
            Positioned.fill(
              child: mbx.MapWidget(
                styleUri: isDark
                    ? MapConstants.mapboxStyleUrlDark
                    : MapConstants.mapboxStyleUrl,
                cameraOptions: mbx.CameraOptions(
                  center: pickupLatLng,
                  zoom: 13.0,
                  pitch: 0.0,
                ),
                onMapCreated: onMapCreated,
                onStyleLoadedListener: (event) => onStyleLoaded(),
                onCameraChangeListener: onCameraChanged,
              ),
            ),

            // ── Back button ──────────────────────────────────────────────
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 12,
              child: _WhiteMapBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
            ),

            // ── Loading pill ─────────────────────────────────────────────
            if (isInitializing) _buildLoadingPill(context),

            // ── Right-side map buttons ───────────────────────────────────
            if (isRideDataReady)
              Positioned(
                right: 16,
                top: (MediaQuery.of(context).size.height - 300) / 2,
                child: Column(
                  children: [
                    // Driver location button — only when we have a GPS fix
                    if (isDriverLocationReady)
                      _WhiteMapBtn(
                        icon: Icons.directions_car,
                        onTap: () {
                          if (driverPos != null) {
                            mapController.animateCamera(
                              driverPos!,
                              bearing: driverBearing,
                            );
                          }
                        },
                      ),
                    if (isDriverLocationReady) const SizedBox(height: 12),
                    // Route overview button — always available once ride data is ready
                    _WhiteMapBtn(
                      icon: Icons.map,
                      onTap: () {
                        mapController.fitBoundsToPickupAndDropoff(
                          pickupLatLng,
                          dropoffLatLng,
                        );
                      },
                    ),
                  ],
                ),
              ),

            // ── Bottom panel ─────────────────────────────────────────────
            // BUG FIX: Hide bottom panel when ride is completed so the
            // buggy TripSummaryCard (which shows distanceLeft/arrivalTime)
            // is not visible behind the completion overlay.
            if (isRideDataReady && rideState.phase != RidePhase.rideEnded)
              BottomPanel(
                rideState: rideState,
                driverId: widget.driverId,
                pickupLabel: pickupAddress,
                dropLabel: dropoffAddress,
                onContinue: () => Navigator.maybePop(context),
                onChatTap: () {
                  Navigator.pushNamed(
                    context,
                    '/chat',
                    arguments: {
                      'rideId': widget.rideId,
                      'driverName': rideState.driverName,
                      'driverId': widget.driverId,
                      'vehicleName': rideState.vehicleName,
                      'vehicleMake': rideState.vehicleMake,
                      'vehicleModel': rideState.vehicleModel,
                      'vehicleColor': rideState.vehicleColor,
                      'plateNumber': rideState.plateNumber,
                      'driverPhotoUrl': rideState.driverPhotoUrl,
                    },
                  );
                },
              )
            else if (!isRideDataReady)
              // Cold start: show skeleton while waiting for WebSocket data
              _buildSkeletonSheet(context),

            // ── Trip-completed overlay ───────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 480),
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutQuart,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
              child: rideState.phase == RidePhase.rideEnded
                  ? TripCompletedOverlay(
                      key: const ValueKey('trip_completed'),
                      rideState: rideState,
                      durationMin: tripDurationMin,
                      distanceKm: tripDistanceKm,
                      rideId: widget.rideId,
                      onContinue: () => AppRouter.clearAndGo(context, AppRouter.home),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildLoadingPill(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 62,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bg(context).withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primaryPurple,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                initStatus,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.text(context),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonSheet(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.50,
      minChildSize: 0.18,
      maxChildSize: 0.50,
      snap: true,
      snapSizes: const [0.18, 0.50],
      builder: (context, scrollController) {
        return IgnorePointer(
          ignoring: true,
          child: Container(
            // Panel background lives OUTSIDE the shimmer so only shapes shimmer
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
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
              child: TrackingSkeleton(),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// White Map Button — standalone white rounded square button
// ─────────────────────────────────────────────────────────────────────────────

class _WhiteMapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _WhiteMapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.text(context)),
      ),
    );
  }
}
