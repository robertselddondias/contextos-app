import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LoadingIndicator extends StatelessWidget {
  final String message;

  const LoadingIndicator({
    super.key,
    this.message = 'Carregando...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300), // Add constraints
        child: Column(
          mainAxisSize: MainAxisSize.min, // Set to min
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLoadingAnimation(context),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingAnimation(BuildContext context) {
    try {
      // Add error handling for asset loading
      return SizedBox(
        width: 200,
        height: 200,
        child: Lottie.asset(
          'assets/animations/loading.json',
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            // If animation fails to load, fallback to CircularProgressIndicator
            return _buildFallbackIndicator(context);
          },
        ),
      );
    } catch (e) {
      return _buildFallbackIndicator(context);
    }
  }

  Widget _buildFallbackIndicator(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
        strokeWidth: 6,
      ),
    );
  }
}
