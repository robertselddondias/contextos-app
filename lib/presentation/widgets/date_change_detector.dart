// lib/presentation/widgets/date_change_detector.dart
import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget que monitora alterações de data e atualiza a palavra do dia quando necessário
class DateChangeDetector extends StatefulWidget {
  final Widget child;

  const DateChangeDetector({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<DateChangeDetector> createState() => _DateChangeDetectorState();
}

class _DateChangeDetectorState extends State<DateChangeDetector> with WidgetsBindingObserver {
  DateTime? _lastCheckDate;
  String? _lastCheckDateStr;
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Carrega a última data verificada das preferências
    _loadLastCheckDate();

    // Verifica a palavra do dia após a construção do widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndUpdateDailyWord();
    });
  }

  Future<void> _loadLastCheckDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastCheckStr = prefs.getString('last_word_check_date');

      if (lastCheckStr != null) {
        _lastCheckDateStr = lastCheckStr;
        _lastCheckDate = DateTime.parse(lastCheckStr);
      }
    } catch (e) {
      debugPrint('Erro ao carregar última data verificada: $e');
    }
  }

  Future<void> _saveLastCheckDate(DateTime date) async {
    try {
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      // Só salva se for diferente da última data salva
      if (dateStr != _lastCheckDateStr) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_word_check_date', dateStr);
        _lastCheckDateStr = dateStr;
        _lastCheckDate = date;
      }
    } catch (e) {
      debugPrint('Erro ao salvar data verificada: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando o app volta para o primeiro plano (retomado)
    if (state == AppLifecycleState.resumed) {
      _checkAndUpdateDailyWord();
    }
  }

  Future<void> _checkAndUpdateDailyWord() async {
    if (!mounted) return;

    final now = DateTime.now();
    final currentDateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    // Verifica se já fizemos a verificação inicial ou se a data mudou
    if (!_initialCheckDone || _lastCheckDateStr != currentDateStr) {
      _initialCheckDone = true;

      try {
        // Busca o GameBloc via BlocProvider e aciona a verificação com força
        final gameBloc = context.read<GameBloc>();

        // GameRefreshDaily irá verificar e atualizar a palavra do dia se necessário
        gameBloc.add(const GameRefreshDaily());

        // Atualiza a data da última verificação
        await _saveLastCheckDate(now);

        debugPrint('Verificação da palavra do dia realizada em: $currentDateStr');
      } catch (e) {
        debugPrint('Erro ao verificar/atualizar a palavra do dia: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
