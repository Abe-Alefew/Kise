import 'package:flutter/material.dart';

import '../../../../core/theme/app_dimensions.dart';

class HomeDashboardScreen extends StatelessWidget {
	const HomeDashboardScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final textTheme = Theme.of(context).textTheme;

		return Scaffold(
			appBar: AppBar(
				title: const Text('Home'),
			),
			body: Padding(
				padding: AppDimensions.pagePadding,
				child: Center(
					child: Text(
						'Welcome to KISE',
						style: textTheme.displaySmall,
						textAlign: TextAlign.center,
					),
				),
			),
		);
	}
}
