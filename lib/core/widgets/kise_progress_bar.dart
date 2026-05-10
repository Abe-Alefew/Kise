import 'package:flutter/material.dart';

// @ USAGE: KiseProgressBar(0.5, 15 (optional: have default), Duration(milliseconds: 200) (optional: have default))

class KiseProgressBar extends StatelessWidget {
    final double progress;
    final double height;
    final Duration duration;
    final Color? fillColor;
    final Color? trackColor;

    const KiseProgressBar({
        super.key,
        required this.progress,
        this.height = 20,
        this.duration = const Duration(milliseconds: 400),
        this.fillColor,
        this.trackColor,
    });

    @override
    Widget build(BuildContext context) {
        return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LayoutBuilder(
                builder: (context, constraints) {
                    return Container(
                        width: double.infinity,
                        height: height,
                        color: trackColor ?? const Color(0xFFF2EAD9),
                        child: Stack(
                            children: [
                                AnimatedContainer(
                                    duration: duration,
                                    curve: Curves.easeInOut,
                                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                                    height: height,
                                    decoration: BoxDecoration(
                                        color: fillColor ?? const Color(0xffDDA22C),
                                        borderRadius: BorderRadius.circular(height / 2),
                                    ),
                                )
                            ],
                        ),
                    );
                }
            ),
        );
    }
}