import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/health/health_service.dart';
import '../../../domain/entities/duel.dart';
import '../../providers/duel_provider.dart';

class CreateDuelScreen extends ConsumerStatefulWidget {
  const CreateDuelScreen({super.key});

  @override
  ConsumerState<CreateDuelScreen> createState() => _CreateDuelScreenState();
}

class _CreateDuelScreenState extends ConsumerState<CreateDuelScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _habitCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _opponentCtrl = TextEditingController();

  int _durationDays = 21;
  DuelType _duelType = DuelType.duel;
  int _maxParticipants = 5;
  bool _isTrustedCheckin = false;
  HealthMetric? _selectedHealthMetric;
  double _healthTarget = 8000;

  static const _durations = [7, 14, 21, 30];
  static const _groupSizes = [3, 5, 7, 10];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _duelType = _tabController.index == 0 ? DuelType.duel : DuelType.group;
        _isTrustedCheckin = false;
        _selectedHealthMetric = null;
      });
    });
  }

  @override
  void dispose() {
    _habitCtrl.dispose();
    _descCtrl.dispose();
    _opponentCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(createDuelProvider.notifier).create(
          habitName: _habitCtrl.text.trim(),
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
          durationDays: _durationDays,
          opponentUsername: _duelType == DuelType.duel && _opponentCtrl.text.trim().isNotEmpty
              ? _opponentCtrl.text.trim()
              : null,
          type: _duelType,
          maxParticipants: _duelType == DuelType.group ? _maxParticipants : 2,
          isTrustedCheckin: _isTrustedCheckin,
          healthMetric: _isTrustedCheckin ? _selectedHealthMetric?.key : null,
          healthTargetValue: _isTrustedCheckin ? _healthTarget : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ref.listen<CreateDuelState>(createDuelProvider, (prev, next) {
      if (next is CreateDuelSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Дуэль создана! ⚔️')),
        );
        ref.read(createDuelProvider.notifier).reset();
        ref.read(duelsListProvider.notifier).load();

        // Если групповая — переходим в лобби
        if (next.duel.isGroup && next.duel.inviteCode != null) {
          Navigator.pushReplacementNamed(
            context,
            '/group-lobby',
            arguments: next.duel.id,
          );
        } else {
          Navigator.pop(context);
        }
      } else if (next is CreateDuelError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message), backgroundColor: colorScheme.error),
        );
      }
    });

    final state = ref.watch(createDuelProvider);
    final isLoading = state is CreateDuelLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новая дуэль'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: '1 на 1'),
            Tab(icon: Icon(Icons.groups), text: 'Групповая'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Habit Name ────────────────────────────────────────────────
            TextFormField(
              controller: _habitCtrl,
              decoration: const InputDecoration(
                labelText: 'Привычка *',
                hintText: 'напр. Утренняя медитация',
                prefixIcon: Icon(Icons.local_fire_department_outlined),
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Обязательное поле' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(
                labelText: 'Описание (необязательно)',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 2,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),

            // ── Type-specific fields ──────────────────────────────────────
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              child: _duelType == DuelType.duel
                  ? _OneVsOneFields(controller: _opponentCtrl)
                  : _GroupFields(
                      maxParticipants: _maxParticipants,
                      onSizeChanged: (v) => setState(() => _maxParticipants = v),
                    ),
            ),

            const SizedBox(height: 24),

            // ── Duration ──────────────────────────────────────────────────
            Text('Длительность', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _durations.map((d) {
                final selected = d == _durationDays;
                return ChoiceChip(
                  label: Text('$d д.'),
                  selected: selected,
                  onSelected: (_) => setState(() => _durationDays = d),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // ── Trusted Check-in ──────────────────────────────────────────
            _TrustedCheckinSection(
              enabled: _isTrustedCheckin,
              selectedMetric: _selectedHealthMetric,
              targetValue: _healthTarget,
              onToggle: (v) => setState(() {
                _isTrustedCheckin = v;
                if (!v) _selectedHealthMetric = null;
              }),
              onMetricChanged: (m) => setState(() => _selectedHealthMetric = m),
              onTargetChanged: (v) => setState(() => _healthTarget = v),
            ),

            const SizedBox(height: 32),

            // ── Submit button ─────────────────────────────────────────────
            FilledButton.icon(
              onPressed: isLoading ? null : _submit,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.add),
              label: Text(isLoading
                  ? 'Создаём...'
                  : _duelType == DuelType.group
                      ? 'Создать лобби'
                      : 'Создать дуэль'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Поля для 1v1 ──────────────────────────────────────────────────────────

class _OneVsOneFields extends StatelessWidget {
  const _OneVsOneFields({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Имя соперника (необязательно)',
        hintText: 'Оставь пустым для открытого вызова',
        prefixIcon: Icon(Icons.person_search),
      ),
      textInputAction: TextInputAction.done,
    );
  }
}

// ─── Поля для группы ───────────────────────────────────────────────────────

class _GroupFields extends StatelessWidget {
  const _GroupFields({
    required this.maxParticipants,
    required this.onSizeChanged,
  });

  final int maxParticipants;
  final ValueChanged<int> onSizeChanged;

  static const _sizes = [3, 5, 7, 10];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Групповая дуэль создаст лобби с кодом приглашения. Все участники присоединяются по коду.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Максимум участников', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _sizes.map((s) {
            return ChoiceChip(
              label: Text('$s игроков'),
              selected: s == maxParticipants,
              onSelected: (_) => onSizeChanged(s),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ─── Trusted Check-in Section ──────────────────────────────────────────────

class _TrustedCheckinSection extends StatelessWidget {
  const _TrustedCheckinSection({
    required this.enabled,
    required this.selectedMetric,
    required this.targetValue,
    required this.onToggle,
    required this.onMetricChanged,
    required this.onTargetChanged,
  });

  final bool enabled;
  final HealthMetric? selectedMetric;
  final double targetValue;
  final ValueChanged<bool> onToggle;
  final ValueChanged<HealthMetric?> onMetricChanged;
  final ValueChanged<double> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: enabled
            ? theme.colorScheme.secondary.withValues(alpha: 0.08)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: enabled
              ? theme.colorScheme.secondary.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trusted Check-in',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Авто-чекин через Apple Health / Google Fit',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Switch(value: enabled, onChanged: onToggle),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<HealthMetric>(
              value: selectedMetric,
              decoration: const InputDecoration(
                labelText: 'Метрика',
                prefixIcon: Icon(Icons.monitor_heart_outlined),
              ),
              items: HealthMetric.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text('${m.emoji} ${m.label}'),
                      ))
                  .toList(),
              onChanged: onMetricChanged,
              validator: (_) => enabled && selectedMetric == null ? 'Выберите метрику' : null,
            ),
            if (selectedMetric != null) ...[
              const SizedBox(height: 16),
              Text(
                'Цель в день: ${targetValue.toInt()} ${_unitForMetric(selectedMetric!)}',
                style: theme.textTheme.bodyMedium,
              ),
              Slider(
                value: targetValue,
                min: _minTarget(selectedMetric!),
                max: _maxTarget(selectedMetric!),
                divisions: 10,
                label: '${targetValue.toInt()}',
                onChanged: onTargetChanged,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _unitForMetric(HealthMetric m) {
    return switch (m) {
      HealthMetric.steps => 'шагов',
      HealthMetric.sleepHours => 'часов',
      HealthMetric.activeMinutes => 'минут',
      HealthMetric.heartRateAvg => 'уд/мин',
      HealthMetric.waterMl => 'мл',
      HealthMetric.caloriesBurned => 'ккал',
    };
  }

  double _minTarget(HealthMetric m) {
    return switch (m) {
      HealthMetric.steps => 3000,
      HealthMetric.sleepHours => 5,
      HealthMetric.activeMinutes => 10,
      HealthMetric.heartRateAvg => 50,
      HealthMetric.waterMl => 500,
      HealthMetric.caloriesBurned => 200,
    };
  }

  double _maxTarget(HealthMetric m) {
    return switch (m) {
      HealthMetric.steps => 20000,
      HealthMetric.sleepHours => 10,
      HealthMetric.activeMinutes => 120,
      HealthMetric.heartRateAvg => 100,
      HealthMetric.waterMl => 4000,
      HealthMetric.caloriesBurned => 1500,
    };
  }
}
