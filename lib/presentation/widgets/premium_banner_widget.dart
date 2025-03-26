// lib/presentation/widgets/premium_banner_widget.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/services/premium_banner_service.dart';
import 'package:contextual/services/purchase_manager.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget de banner que promove a versão premium do app
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
  bool _visible = false;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();

    // Configurar animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
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

    // Inicializar e verificar se o banner deve ser mostrado
    _initBanner();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Inicializa o banner e verifica se deve ser mostrado
  Future<void> _initBanner() async {
    await _bannerService.initialize();

    // Verificar estado inicial
    if (_bannerService.shouldShowBanner) {
      setState(() {
        _visible = true;
      });
      _animationController.forward();
    }

    // Ouvir mudanças no estado do banner
    _bannerService.showBannerStream.listen((shouldShow) {
      if (shouldShow && !_visible) {
        setState(() {
          _visible = true;
        });
        _animationController.forward();
      } else if (!shouldShow && _visible) {
        _animationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _visible = false;
            });
          }
        });
      }
    });
  }

  /// Fecha o banner e marca como exibido
  void _dismissBanner() {
    HapticFeedback.lightImpact();
    _bannerService.markBannerAsShown();
  }

  /// Inicia o processo de compra
  Future<void> _startPurchase() async {
    HapticFeedback.mediumImpact();

    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
    });

    try {
      await _purchaseManager.buyRemoveAds();
      // A compra é processada por listeners, não precisamos fazer nada
    } catch (e) {
      // Erro tratado pelo PurchaseManager
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
    if (!_visible) {
      return const SizedBox.shrink();
    }

    // Obtém as mensagens do banner
    final messages = _bannerService.getBannerMessages();
    final primaryMessage = messages['primary'] ?? 'Remova os anúncios';
    final secondaryMessage = messages['secondary'] ?? 'Jogue sem interrupções';

    // Detecta tema escuro
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
        animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.all(context.responsiveValue(
                small: 12.0,
                medium: 16.0,
                large: 20.0,
              )),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [
                    Color(0xFF2A2A72),
                    Color(0xFF003366),
                  ]
                      : [
                    Color(0xFF7F5AF0),
                    Color(0xFF4E35DD),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Cabeçalho com botão de fechar
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: _dismissBanner,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conteúdo principal
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: context.responsiveValue(
                        small: 16.0,
                        medium: 20.0,
                        large: 24.0,
                      ),
                      vertical: context.responsiveValue(
                        small: 8.0,
                        medium: 12.0,
                        large: 16.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Ícone animado
                        Container(
                          width: context.responsiveValue(
                            small: 50.0,
                            medium: 60.0,
                            large: 70.0,
                          ),
                          height: context.responsiveValue(
                            small: 50.0,
                            medium: 60.0,
                            large: 70.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.block,
                                color: Colors.white,
                                size: context.responsiveValue(
                                  small: 24.0,
                                  medium: 28.0,
                                  large: 32.0,
                                ),
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.ads_click,
                                    color: isDarkMode
                                        ? Color(0xFF2A2A72)
                                        : Color(0xFF7F5AF0),
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
                        ),
                        const SizedBox(width: 16),

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
                                ),
                              ),
                              const SizedBox(height: 4),
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

                  // Botão de ação
                  Padding(
                    padding: EdgeInsets.only(
                      left: context.responsiveValue(
                        small: 16.0,
                        medium: 20.0,
                        large: 24.0,
                      ),
                      right: context.responsiveValue(
                        small: 16.0,
                        medium: 20.0,
                        large: 24.0,
                      ),
                      bottom: context.responsiveValue(
                        small: 16.0,
                        medium: 20.0,
                        large: 24.0,
                      ),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPurchasing ? null : _startPurchase,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: isDarkMode
                              ? Color(0xFF2A2A72)
                              : Color(0xFF7F5AF0),
                          backgroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            vertical: context.responsiveValue(
                              small: 10.0,
                              medium: 12.0,
                              large: 14.0,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isPurchasing
                            ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isDarkMode
                                  ? Color(0xFF2A2A72)
                                  : Color(0xFF7F5AF0),
                            ),
                          ),
                        )
                            : Text(
                          'Comprar agora',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: context.responsiveFontSize(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
