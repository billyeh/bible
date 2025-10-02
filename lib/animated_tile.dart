import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

class AnimatedTile extends StatefulWidget {
  final Widget child;
  final String uniqueKey;
  final int staggerIndex; // index for minor delay

  const AnimatedTile({
    super.key,
    required this.child,
    required this.uniqueKey,
    required this.staggerIndex,
  });

  @override
  State<AnimatedTile> createState() => _AnimatedTileState();
}

class _AnimatedTileState extends State<AnimatedTile> {
  bool _visible = false;
  bool _hasAnimated = false;

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key(widget.uniqueKey),
      onVisibilityChanged: (info) {
        if (!_hasAnimated && info.visibleFraction > 0.1) {
          _hasAnimated = true; // mark as animated

          // Small stagger based on nearby index
          final delayMs = (widget.staggerIndex * 5) % 20;
          Future.delayed(Duration(milliseconds: delayMs), () {
            if (mounted) setState(() => _visible = true);
          });
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 400),
        opacity: _visible ? 1 : 0,
        curve: Curves.easeOut,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 400),
          offset: _visible ? Offset.zero : const Offset(0, 0.05),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
