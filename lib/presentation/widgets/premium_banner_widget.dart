// lib/presentation/widgets/premium_banner_widget.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/services/premium_banner_service.dart';
import 'package:contextual/services/purchase_manager.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de banner que promove a versão premium do app com design moderno e elegante
class PremiumBannerWidget extends StatefulWidget {
  const PremiumBannerWidget({Key? key}) : super(key: key);

  @override
  State<PremiumBannerWidget> createState() => _PremiumBannerWidgetState();
}

class _PremiumBannerWidgetState extends State<PremiumBannerWidget> with SingleTickerProviderStateMixin {
  final PremiumBannerService _bannerService = PremiumBannerService();
  final PurchaseManager _purchaseManager = PurchaseManager();
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();

    debugPrint('PremiumBannerWidget: Widget inicializado');

    // Configurar animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 150.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutBack,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Inicializar o banner
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBanner();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Inicializa o banner
  Future<void> _initBanner() async {
    try {
      await _bannerService.initialize();
      await _purchaseManager.initialize();

      // Iniciar animação
      _animationController.forward();

      debugPrint('PremiumBannerWidget: Banner inicializado e animação iniciada');
    } catch (e) {
      debugPrint('PremiumBannerWidget: Erro ao inicializar banner: $e');
    }
  }

  /// Fecha o banner e marca como exibido
  void _dismissBanner() {
    HapticFeedback.lightImpact();
    _bannerService.markBannerAsShown();

    // Animar fechamento
    _animationController.reverse();

    debugPrint('PremiumBannerWidget: Banner dispensado pelo usuário');
  }

  /// Inicia o processo de compra
  Future<void> _startPurchase() async {
    HapticFeedback.mediumImpact();

    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      debugPrint('PremiumBannerWidget: Iniciando processo de compra');
      await _purchaseManager.buyRemoveAds();
      // A compra é processada por listeners, não precisamos fazer nada
    } catch (e) {
      debugPrint('PremiumBannerWidget: Erro no processo de compra: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível iniciar a compra. Tente novamente mais tarde.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Obtém as mensagens do banner
    final messages = _bannerService.getBannerMessages();
    final primaryMessage = messages['primary'] ?? 'Remova os anúncios';
    final secondaryMessage = messages['secondary'] ?? 'Jogue sem interrupções';

    // Detecta tema escuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Cores do tema moderno
    final Color primaryGradientStart = isDarkMode
        ? const Color(0xFF2B2D5D)
        : const Color(0xFF6366F1);
    final Color primaryGradientEnd = isDarkMode
        ? const Color(0xFF1A1F38)
        : const Color(0xFF4F46E5);
    final Color accentColor = isDarkMode
        ? const Color(0xFF9FA0FF)
        : const Color(0xFFEEF2FF);
    final Color buttonColor = isDarkMode
        ? const Color(0xFFEEF2FF)
        : Colors.white;
    final Color buttonTextColor = isDarkMode
        ? const Color(0xFF2B2D5D)
        : const Color(0xFF4338CA);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: context.responsiveValue(
                    small: 16.0,
                    medium: 20.0,
                    large: 24.0,
                  ),
                  vertical: context.responsiveValue(
                    small: 10.0,
                    medium: 12.0,
                    large: 16.0,
                  ),
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryGradientStart,
                      primaryGradientEnd,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGradientStart.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                    color: accentColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Fundo decorativo com círculos
                      Positioned(
                        top: -20,
                        right: -20,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: -20,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                      // Conteúdo do banner
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Cabeçalho com badge premium e botão de fechar
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Badge premium
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        color: Colors.amberAccent,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'PREMIUM',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Botão de fechar
                                IconButton(
                                  icon: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: accentColor.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                  onPressed: _dismissBanner,
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 32,
                                    minHeight: 32,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Conteúdo principal
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                            child: Row(
                              children: [
                                // Ícone animado
                                _buildPremiumIcon(context, accentColor),
                                const SizedBox(width: 20),

                                // Texto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        primaryMessage,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: context.responsiveFontSize(18),
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        secondaryMessage,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: context.responsiveFontSize(14),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Botão de ação com efeito de destaque
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isPurchasing ? null : _startPurchase,
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: buttonTextColor,
                                  backgroundColor: buttonColor,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _isPurchasing
                                      ? SizedBox(
                                    key: const ValueKey('loading'),
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        buttonTextColor,
                                      ),
                                    ),
                                  )
                                      : Row(
                                    key: const ValueKey('button'),
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Comprar agora',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: context.responsiveFontSize(15),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // Ícone premium com efeito visual moderno
  Widget _buildPremiumIcon(BuildContext context, Color accentColor) {
    return Container(
      width: context.responsiveValue(
        small: 56.0,
        medium: 64.0,
        large: 72.0,
      ),
      height: context.responsiveValue(
        small: 56.0,
        medium: 64.0,
        large: 72.0,
      ),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(
          color: accentColor.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ícone principal
          Icon(
            Icons.block_flipped,
            color: Colors.white,
            size: context.responsiveValue(
              small: 26.0,
              medium: 30.0,
              large: 34.0,
            ),
          ),

          // Elemento decorativo
          Positioned(
            right: 6,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.verified_rounded,
                color: Colors.blue,
                size: context.responsiveValue(
                  small: 12.0,
                  medium: 14.0,
                  large: 16.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
