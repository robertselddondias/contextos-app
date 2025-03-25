// presentation/blocs/settings/settings_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:contextual/data/datasources/local/shared_prefs_manager.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SharedPrefsManager _localDataSource;

  SettingsBloc({
    required SharedPrefsManager localDataSource,
  }) : _localDataSource = localDataSource,
        super(const SettingsState()) {
    on<SettingsLoaded>(_onSettingsLoaded);
    on<ThemeModeChanged>(_onThemeModeChanged);
    on<LocaleChanged>(_onLocaleChanged);
  }

  Future<void> _onSettingsLoaded(
      SettingsLoaded event,
      Emitter<SettingsState> emit,
      ) async {
    try {
      // Carrega as configurações salvas
      final themeMode = await _localDataSource.getThemeMode();
      final locale = await _localDataSource.getLocale() ??
          const Locale('pt', 'BR'); // Locale padrão

      emit(state.copyWith(
        themeMode: themeMode,
        locale: locale,
      ));
    } catch (e) {
      // Em caso de erro, usamos as configurações padrão
      emit(state);
    }
  }

  Future<void> _onThemeModeChanged(
      ThemeModeChanged event,
      Emitter<SettingsState> emit,
      ) async {
    try {
      // Salva a nova configuração de tema
      await _localDataSource.saveThemeMode(event.themeMode);

      // Atualiza o estado
      emit(state.copyWith(themeMode: event.themeMode));
    } catch (e) {
      // Em caso de erro, mantemos o estado atual
    }
  }

  Future<void> _onLocaleChanged(
      LocaleChanged event,
      Emitter<SettingsState> emit,
      ) async {
    try {
      // Salva a nova configuração de idioma
      await _localDataSource.saveLocale(event.locale);

      // Atualiza o estado
      emit(state.copyWith(locale: event.locale));
    } catch (e) {
      // Em caso de erro, mantemos o estado atual
    }
  }
}
