import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/utils/keyboard_dismisser.dart';
import 'package:flutter/material.dart';

class GuessInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isLoading;
  final Function(String) onSubmitted;

  const GuessInput({
    super.key,
    required this.controller,
    required this.isLoading,
    required this.onSubmitted,
  });

  @override
  State<GuessInput> createState() => _GuessInputState();
}

class _GuessInputState extends State<GuessInput> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _scaleAnimation;
  bool _hasText = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    widget.controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: isDarkMode
            ? ColorConstants.darkSurfaceVariant
            : ColorConstants.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.primary.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: 'Digite uma palavra...',
                  hintStyle: TextStyle(
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.4),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(
                      color: ColorConstants.primary.withOpacity(0.5),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.white.withOpacity(0.2)
                          : Colors.black.withOpacity(0.1),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(
                      color: ColorConstants.primary,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? ColorConstants.darkSurface
                      : Colors.white,
                  prefixIcon: Icon(
                    Icons.search,
                    color: _focusNode.hasFocus
                        ? ColorConstants.primary
                        : isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.4),
                  ),
                  suffixIcon: widget.isLoading
                      ? Container(
                    margin: const EdgeInsets.all(10),
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        ColorConstants.primary,
                      ),
                    ),
                  )
                      : _hasText
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      widget.controller.clear();
                      _focusNode.requestFocus();
                    },
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.4),
                  )
                      : null,
                ),
                enabled: !widget.isLoading,
                textInputAction: TextInputAction.search,
                onSubmitted: widget.isLoading ? null : widget.onSubmitted,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTapDown: (_) => _animationController.forward(),
            onTapUp: (_) => _animationController.reverse(),
            onTapCancel: () => _animationController.reverse(),
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: InkWell(
                onTap: widget.isLoading || !_hasText
                    ? null
                    : () {
                  // Esconder o teclado explicitamente
                  context.hideKeyboard();
                  // Chamar a função de submissão
                  widget.onSubmitted(widget.controller.text);
                },
                borderRadius: BorderRadius.circular(16.0),
                child: Material(
                  borderRadius: BorderRadius.circular(16.0),
                  elevation: 4,
                  color: _hasText
                      ? ColorConstants.primary
                      : isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      gradient: _hasText
                          ? ColorConstants.primaryGradient
                          : null,
                    ),
                    child: Icon(
                      Icons.send,
                      color: _hasText
                          ? Colors.white
                          : isDarkMode
                          ? Colors.white.withOpacity(0.6)
                          : Colors.black.withOpacity(0.3),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16,)
        ],
      ),
    );
  }
}
