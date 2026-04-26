import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '_RouteCard.dart';
import '_EtaSheet.dart';

class MapEtaPage extends StatefulWidget {
  const MapEtaPage({super.key});

  @override
  State<MapEtaPage> createState() => _MapEtaPageState();
}

class _MapEtaPageState extends State<MapEtaPage> {
  int _selectedRoute = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: Stack(
        children: [
          // ── 1. MAP fullscreen ────────────────────────────
          Positioned.fill(
            child: Image.asset('images/map_preview.png', fit: BoxFit.cover),
          ),

          // ── 2. Route cards sur la map ────────────────────
          Positioned(
            top: MediaQuery.of(context).size.height * 0.28,
            left: MediaQuery.of(context).size.width * 0.32,
            child: RouteCard(
              duration: '54 min',
              distance: '72 km',
              isSelected: _selectedRoute == 0,
              onTap: () => setState(() => _selectedRoute = 0),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.40,
            left: MediaQuery.of(context).size.width * 0.38,
            child: RouteCard(
              duration: '53 min',
              distance: '71.4 km',
              isSelected: _selectedRoute == 1,
              onTap: () => setState(() => _selectedRoute = 1),
            ),
          ),

          // ── 3. Back button ───────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _MapBtn(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.canPop(context)
                          ? Navigator.pop(context)
                          : null,
                    ),
                    const Spacer(),
                    _MapBtn(icon: Icons.layers_outlined, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),

          // ── 4. Draggable bottom sheet ────────────────────
          EtaSheet(selectedRoute: _selectedRoute),
        ],
      ),
    );
  }
}

class _MapBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.bg(context).withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
