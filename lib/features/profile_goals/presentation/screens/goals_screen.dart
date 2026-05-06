import 'package:flutter/material.dart';
import 'package:kise/core/widgets/kise_progress_bar.dart';

void main() {
    runApp(MaterialApp(
        title: 'Kise',
        home: KiseApp(),
    ));
}

class KiseApp extends StatefulWidget {
    const KiseApp({super.key});

    @override
    State<KiseApp> createState() => _KiseAppState();
}

class _KiseAppState extends State<KiseApp> {
    double progress = 0.0;

    @override
    Widget build(BuildContext context) {
        return Scaffold(
            appBar: AppBar(
                title: Text('Kise'),
            ),
            body: Center(
                child: Column(
                    children: [
                        Text('My progress bar.'),
                        KiseProgressBar(progress: progress, height: 13.0,),
                        FloatingActionButton(
                            onPressed: () {
                                setState(() {
                                    if (progress < 1) {
                                        progress += 0.1;
                                        print('plus: $progress');
                                    }
                                });
                            },
                            child: Text('plus'),
                        ),
                        FloatingActionButton(
                            onPressed: () {
                                setState(() {
                                    if (progress > 0) {
                                        progress -= 0.1;
                                        print('minus: $progress');
                                    }
                                });
                            },
                            child: Text('minus'),
                        ),
                    ],
                ),
            ),
        );
    }
}