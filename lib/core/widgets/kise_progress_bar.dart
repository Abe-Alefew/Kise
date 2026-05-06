import 'package:flutter/material.dart';

// @ USAGE: KiseProgressBar(0.5, 15 (optional: have default), Duration(milliseconds: 200) (optional: have default))

class KiseProgressBar extends StatelessWidget {
    final double progress;
    final double height;
    final Duration duration;

    const KiseProgressBar({
        super.key,
        required this.progress,
        this.height = 20,
        this.duration = const Duration(milliseconds: 400),    
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
                        color: Color(0xF2EAD9FF),
                        child: Stack(
                            children: [
                                AnimatedContainer(
                                    duration: duration,
                                    curve: Curves.easeInOut,
                                    width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                                    height: height,
                                    decoration: BoxDecoration(
                                        color: Color(0xDDA22Cff),
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