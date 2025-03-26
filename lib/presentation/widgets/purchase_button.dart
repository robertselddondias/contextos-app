// lib/presentation/widgets/purchase_button.dart
import 'package:contextual/core/constants/color_constants.dart';
import 'package:contextual/services/purchase_manager.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:flutter/material.dart';

/// Widget que exibe um botão para compra de "Remover Anúncios"
class PurchaseButton extends StatefulWidget {
  const PurchaseButton({Key? key}) : super(key: key);

  @override
  State<PurchaseButton> createState() => _PurchaseButtonState();
}

class _PurchaseButtonState extends State<PurchaseButton> {
  final PurchaseManager _purchaseManager = PurchaseManager();
  bool _isPurchased = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Garantir que o gerenciador de compras está inicializado
    if (!_purchaseManager.isInitialized) {
      await _purchaseManager.initialize();
    }

    // Verificar se já foi comprado
    setState(() {
      _isPurchased = _purchaseManager.removeAdsActive;
    });

    // Escutar mudanças futuras
    _purchaseManager.purchaseStateStream.listen((isPurchased) {
      if (mounted) {
        setState(() {
          _isPurchased = isPurchased;
        });
      }
    });
  }

  Future<void> _purchaseRemoveAds() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _purchaseManager.buyRemoveAds();
      if (!result) {
        // Se a compra não foi iniciada com sucesso, mostra um erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível iniciar a compra. Tente novamente mais tarde.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro na compra: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _restorePurchases() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _purchaseManager.restorePurchases();

      // Verificar se a restauração reativou a compra
      if (_purchaseManager.removeAdsActive && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Compras restauradas com sucesso!'),
            backgroundColor: ColorConstants.success,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nenhuma compra encontrada para restaurar.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao restaurar compras: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPurchased) {
      return _buildAlreadyPurchasedWidget(context);
    } else {
      return _buildPurchaseButtonWidget(context);
    }
  }

  Widget _buildAlreadyPurchasedWidget(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: ColorConstants.success.withOpacity(0.5),
          width: 1.0,
        ),
      ),
      child: Padding(
      padding: EdgeInsets.all(context.responsiveValue(
      small: 12.0,
      medium: 16.0,
      large: 18.0,
    )),
    child: Row(
    children: [
    Container(
    padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ColorConstants.success.withOpacity(0.1),
      ),
      child: Icon(
        Icons.check_circle,
        color: ColorConstants.success,
        size: context.responsiveSize(24),
      ),
    ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versão sem anúncios ativada',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: context.responsiveFontSize(15),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Aproveite o jogo sem interrupções!',
              style: TextStyle(
                fontSize: context.responsiveFontSize(13),
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    ],
    ),
      ),
    );
  }

  Widget _buildPurchaseButtonWidget(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Botão de compra principal
          InkWell(
            onTap: _isLoading ? null : _purchaseRemoveAds,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(context.responsiveValue(
                small: 12.0,
                medium: 16.0,
                large: 18.0,
              )),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: ColorConstants.primary.withOpacity(0.1),
                    ),
                    child: _isLoading
                        ? SizedBox(
                      width: context.responsiveSize(24),
                      height: context.responsiveSize(24),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ColorConstants.primary,
                        ),
                      ),
                    )
                        : Icon(
                      Icons.block_flipped,
                      color: ColorConstants.primary,
                      size: context.responsiveSize(24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remover Anúncios',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: context.responsiveFontSize(15),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jogue sem interrupções por apenas R\$19,90',
                          style: TextStyle(
                            fontSize: context.responsiveFontSize(13),
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: context.responsiveSize(16),
                    color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                  ),
                ],
              ),
            ),
          ),
          // Separador
          Divider(height: 1, thickness: 1, color: Colors.grey.withOpacity(0.2)),
          // Botão para restaurar compras
          InkWell(
            onTap: _isLoading ? null : _restorePurchases,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Restaurar Compras',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: context.responsiveFontSize(13),
                  color: ColorConstants.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
