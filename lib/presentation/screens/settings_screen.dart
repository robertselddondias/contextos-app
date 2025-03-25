// Arquivo: lib/presentation/screens/settings_screen.dart
// Reordenado: Histórico, Notificações, Tema, Ferramentas (debug)

import 'package:contextual/presentation/blocs/game/game_bloc.dart';
import 'package:contextual/presentation/blocs/settings/settings_bloc.dart';
import 'package:contextual/utils/responsive_utils.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Salvar a preferência
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);

      // Inscrever ou desinscrever do tópico no FCM
      if (value) {
        await FirebaseMessaging.instance.subscribeToTopic('daily_word');
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic('daily_word');
      }

      setState(() {
        _notificationsEnabled = value;
        _isLoading = false;
      });

      // Mostrar confirmação
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(value
                ? 'Notificações da palavra diária ativadas'
                : 'Notificações da palavra diária desativadas'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Tratar erro
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar configuração: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Configurações',
          style: TextStyle(
            fontSize: context.responsiveFontSize(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.all(context.responsiveValue(
              small: 12.0,
              medium: 16.0,
              large: 20.0,
            )),
            children: [
              // 1. Histórico
              _buildSection(
                context,
                'Histórico',
                [
                  // ListTile com estilo consistente com o bloco de tema
                  InkWell(
                    onTap: () => Navigator.of(context).pushNamed('/history'),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.responsiveValue(
                          small: 12.0,
                          medium: 16.0,
                          large: 20.0,
                        ),
                        vertical: context.responsiveValue(
                          small: 12.0,
                          medium: 16.0,
                          large: 18.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Ícone circular estilizado
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).colorScheme.surfaceVariant,
                            ),
                            child: Icon(
                              Icons.history_outlined,
                              color: Theme.of(context).iconTheme.color,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),
                          // Texto e descrição
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ver histórico de jogos',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(15),
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Veja suas tentativas anteriores',
                                  style: TextStyle(
                                    fontSize: context.responsiveFontSize(12),
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Ícone de seta para indicar navegação
                          Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSize(16)),

              // 2. Configuração de notificações
              _buildSection(
                context,
                'Notificações',
                [
                  SwitchListTile(
                    title: Text(
                      'Palavra diária',
                      style: TextStyle(fontSize: context.responsiveFontSize(14)),
                    ),
                    subtitle: Text(
                      'Receba uma notificação quando uma nova palavra do dia estiver disponível',
                      style: TextStyle(fontSize: context.responsiveFontSize(12)),
                    ),
                    value: _notificationsEnabled,
                    onChanged: _isLoading ? null : _toggleNotifications,
                    secondary: _isLoading
                        ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    )
                        : Icon(
                      _notificationsEnabled
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: _notificationsEnabled
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                ],
              ),

              SizedBox(height: context.responsiveSize(16)),

              // 3. Configuração do tema
              _buildSection(
                context,
                'Tema',
                [
                  _buildThemeSelector(context, state),
                ],
              ),

              SizedBox(height: context.responsiveSize(16)),

              // 4. Ferramentas de desenvolvimento (apenas em debug)
              if (kDebugMode)
                _buildSection(
                  context,
                  'Ferramentas de Desenvolvimento',
                  [
                    _buildDeveloperTools(context),
                  ],
                ),

              SizedBox(height: context.responsiveSize(16)),

              // Versão do app
              Center(
                child: Text(
                  'Versão 1.0.0',
                  style: TextStyle(
                    fontSize: context.responsiveFontSize(12),
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSection(
      BuildContext context,
      String title,
      List<Widget> children,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: context.responsiveFontSize(16),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.responsiveSize(8)),
        Card(
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  // Método para criar o seletor de tema, visualmente aprimorado
  Widget _buildThemeSelector(BuildContext context, SettingsState state) {
    return Column(
      children: [
        _buildThemeOption(
          context,
          'Claro',
          ThemeMode.light,
          state.themeMode,
          Icons.light_mode_outlined,
          'Aparência clara com fundo branco',
        ),
        const Divider(height: 1),
        _buildThemeOption(
          context,
          'Escuro',
          ThemeMode.dark,
          state.themeMode,
          Icons.dark_mode_outlined,
          'Aparência escura com fundo preto',
        ),
        const Divider(height: 1),
        _buildThemeOption(
          context,
          'Sistema',
          ThemeMode.system,
          state.themeMode,
          Icons.brightness_auto_outlined,
          'Segue a configuração do sistema',
        ),
      ],
    );
  }

// Novo método para criar cada opção de tema com design aprimorado
  Widget _buildThemeOption(
      BuildContext context,
      String title,
      ThemeMode themeMode,
      ThemeMode currentThemeMode,
      IconData icon,
      String subtitle,
      ) {
    final bool isSelected = themeMode == currentThemeMode;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () {
        context.read<SettingsBloc>().add(ThemeModeChanged(themeMode));
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(
              small: 12.0,
              medium: 16.0,
              large: 20.0,
            ),
            vertical: context.responsiveValue(
              small: 12.0,
              medium: 16.0,
              large: 18.0,
            ),
          ),
          child: Row(
            children: [
              // Ícone circular estilizado
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? primaryColor.withOpacity(0.2)
                      : Theme.of(context).colorScheme.surfaceVariant,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? primaryColor : Theme.of(context).iconTheme.color,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              // Texto e descrição
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(15),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? primaryColor : null,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: context.responsiveFontSize(12),
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ],
                ),
              ),
              // Indicador de seleção
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperTools(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(
            'Diagnóstico de Relações de Palavras',
            style: TextStyle(fontSize: context.responsiveFontSize(14)),
          ),
          subtitle: Text(
            'Ferramenta para gerenciar contextos semânticos',
            style: TextStyle(fontSize: context.responsiveFontSize(12)),
          ),
          trailing: Icon(
            Icons.chevron_right,
            size: context.responsiveSize(22),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(
              small: 12.0,
              medium: 16.0,
              large: 20.0,
            ),
            vertical: context.responsiveValue(
              small: 4.0,
              medium: 8.0,
              large: 12.0,
            ),
          ),
          onTap: () => Navigator.of(context).pushNamed('/word_relation_diagnostics'),
        ),
        const Divider(height: 1),
        // Opção para forçar atualização da palavra do dia
        ListTile(
          title: Text(
            'Forçar atualização da palavra',
            style: TextStyle(fontSize: context.responsiveFontSize(14)),
          ),
          subtitle: Text(
            'Buscar a palavra mais recente do servidor',
            style: TextStyle(fontSize: context.responsiveFontSize(12)),
          ),
          trailing: Icon(
            Icons.refresh,
            size: context.responsiveSize(22),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(
              small: 12.0,
              medium: 16.0,
              large: 20.0,
            ),
            vertical: context.responsiveValue(
              small: 4.0,
              medium: 8.0,
              large: 12.0,
            ),
          ),
          onTap: () {
            // Reiniciar o jogo, forçando buscar a palavra do dia novamente
            context.read<GameBloc>().add(const GameReset());
            // Mostrar confirmação
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Palavra do dia atualizada'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
      ],
    );
  }
}
