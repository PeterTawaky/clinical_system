import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorView extends StatelessWidget {
  final FlutterErrorDetails? errorDetails;

  const ErrorView({super.key, this.errorDetails});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image with error handling
            _buildErrorImage(isDark, primaryColor),
            const SizedBox(height: 40),
            // Error title with gradient text
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback:
                  (bounds) => LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.7)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).createShader(bounds),
              child: const Text(
                'Oops!',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Error message
            const Text(
              'Something went wrong while\ntrying to process your request',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, height: 1.4),
            ),
            const SizedBox(height: 30),
            // Error details (expandable) - Fixed this section
            if (errorDetails != null) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Theme(
                  data: theme.copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    initiallyExpanded: false,
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Text(
                      'Error Details',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SelectableText(
                            _formatErrorDetails(errorDetails!),
                            style: TextStyle(
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[700],
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _formatErrorDetails(errorDetails!)),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error details copied to clipboard'),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: primaryColor),
                child: const Text('Copy Error Details'),
              ),
            ],
            const SizedBox(height: 30),
            // Go to home button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'GO TO HOME',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage(bool isDark, Color primaryColor) {
    try {
      return Transform.scale(
        scale: 1.1,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/shy.png',
            height: 180,
            fit: BoxFit.contain,
            errorBuilder:
                (context, error, stackTrace) =>
                    _buildFallbackImage(isDark, primaryColor),
          ),
        ),
      );
    } catch (e) {
      return _buildFallbackImage(isDark, primaryColor);
    }
  }

  Widget _buildFallbackImage(bool isDark, Color primaryColor) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[200],
        shape: BoxShape.circle,
        border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
      ),
      child: Icon(
        Icons.sentiment_dissatisfied_outlined,
        size: 80,
        color: primaryColor,
      ),
    );
  }

  String _formatErrorDetails(FlutterErrorDetails errorDetails) {
    return '''
Exception: ${errorDetails.exception}
Stack Trace: ${errorDetails.stack}
Library: ${errorDetails.library}
Context: ${errorDetails.context}
''';
  }
}
