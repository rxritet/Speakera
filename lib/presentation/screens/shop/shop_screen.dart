import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/payment_card_utils.dart';
import '../../../domain/entities/shop.dart';
import '../../providers/shop_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: ShopCategory.values.length, vsync: this);
    Future.microtask(() => ref.read(shopProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showTopUpSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => const _TopUpSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProvider);
    ref.listen<ShopState>(shopProvider, (_, next) {
      if (next is ShopError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.message)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: ShopCategory.values.map((category) => Tab(text: category.label)).toList(),
        ),
        actions: [
          if (state case ShopLoaded(:final currency)) ...[
            _BalanceChip(
              icon: '₸',
              label: _formatAmount(currency.tenge),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _showTopUpSheet,
              tooltip: 'Пополнить баланс',
              icon: const Icon(Icons.add_card_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: switch (state) {
        ShopLoading() => const Center(child: CircularProgressIndicator()),
        ShopError() => const Center(child: CircularProgressIndicator()),
        ShopLoaded(:final items, :final boosters, :final avatars) => TabBarView(
            controller: _tabController,
            children: [
              _AllShop(items: items),
              _AvatarsShop(
                avatars: avatars,
                items: items.where((item) => item.type == ShopItemType.avatar).toList(),
              ),
              _ThemesShop(
                items: items.where((item) => item.type == ShopItemType.theme).toList(),
              ),
              _BoostersShop(
                boosters: boosters,
                items: items.where((item) => item.type == ShopItemType.booster).toList(),
              ),
              _EffectsShop(
                items: items.where((item) => item.type == ShopItemType.effect).toList(),
              ),
            ],
          ),
      },
      floatingActionButton: state case ShopLoaded() ? FloatingActionButton.extended(
        onPressed: _showTopUpSheet,
        icon: const Icon(Icons.account_balance_wallet_outlined),
        label: const Text('Пополнить'),
      ) : null,
    );
  }
}

class _BalanceChip extends StatelessWidget {
  const _BalanceChip({
    required this.icon,
    required this.label,
  });

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TopUpSheet extends ConsumerStatefulWidget {
  const _TopUpSheet();

  @override
  ConsumerState<_TopUpSheet> createState() => _TopUpSheetState();
}

class _TopUpSheetState extends ConsumerState<_TopUpSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberCtrl = TextEditingController();
  final _holderCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _amountCtrl = TextEditingController(text: '5000');
  bool _submitting = false;

  @override
  void dispose() {
    _numberCtrl.dispose();
    _holderCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amount <= 0) return;

    setState(() => _submitting = true);
    await ref.read(shopProvider.notifier).topUpBalance(amount: amount);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Баланс пополнен на ${_formatAmount(amount)} ₸')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardNumber = _numberCtrl.text;
    final scheme = PaymentCardUtils.detectScheme(cardNumber);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Пополнение баланса',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Для демо пополнение проходит сразу после полной валидации карты.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _numberCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Номер карты',
                  hintText: '4111 1111 1111 1111',
                  prefixIcon: const Icon(Icons.credit_card_rounded),
                  suffixText: scheme?.toUpperCase(),
                ),
                onChanged: (value) {
                  final formatted = PaymentCardUtils.formatNumber(value);
                  if (formatted != value) {
                    _numberCtrl.value = TextEditingValue(
                      text: formatted,
                      selection: TextSelection.collapsed(offset: formatted.length),
                    );
                  } else {
                    setState(() {});
                  }
                },
                validator: (value) {
                  if (!PaymentCardUtils.isValidNumber(value)) {
                    return 'Введите корректный номер карты';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _holderCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Имя держателя',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (value) {
                  if (!PaymentCardUtils.isValidHolder(value)) {
                    return 'Введите имя как на карте';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _expiryCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Срок',
                        hintText: 'MM/YY',
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      onChanged: (value) {
                        final formatted = PaymentCardUtils.formatExpiry(value);
                        if (formatted != value) {
                          _expiryCtrl.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                      },
                      validator: (value) {
                        if (!PaymentCardUtils.isValidExpiry(value)) {
                          return 'Некорректный срок';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cvvCtrl,
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (!PaymentCardUtils.isValidCvv(value)) {
                          return 'Некорректный CVV';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Сумма пополнения',
                  prefixText: '₸ ',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
                validator: (value) {
                  final amount = int.tryParse((value ?? '').trim());
                  if (amount == null || amount < 500) {
                    return 'Минимум 500 ₸';
                  }
                  if (amount > 200000) {
                    return 'Слишком большая сумма для демо';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: const [1000, 3000, 5000, 10000]
                    .map(
                      (amount) => _QuickAmountChip(amount: amount),
                    )
                    .toList(growable: false),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payments_rounded),
                  label: Text(_submitting ? 'Проверяем карту...' : 'Пополнить баланс'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAmountChip extends StatelessWidget {
  const _QuickAmountChip({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_TopUpSheetState>();
    return ActionChip(
      label: Text('₸ ${_formatAmount(amount)}'),
      onPressed: () {
        if (state == null) return;
        state._amountCtrl.text = '$amount';
      },
    );
  }
}

class _AllShop extends StatelessWidget {
  const _AllShop({required this.items});

  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _ShopItemCard(item: items[index]),
    );
  }
}

class _AvatarsShop extends StatelessWidget {
  const _AvatarsShop({required this.avatars, required this.items});

  final List<UserAvatar> avatars;
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.92,
      ),
      itemCount: avatars.length + items.length,
      itemBuilder: (context, index) {
        if (index < avatars.length) {
          return _AvatarCard(avatar: avatars[index]);
        }
        return _ShopItemCard(item: items[index - avatars.length]);
      },
    );
  }
}

class _ThemesShop extends StatelessWidget {
  const _ThemesShop({required this.items});

  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ThemeCard(item: items[index]),
    );
  }
}

class _BoostersShop extends StatelessWidget {
  const _BoostersShop({required this.boosters, required this.items});

  final List<Booster> boosters;
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (boosters.any((booster) => booster.isActive)) ...[
          Text(
            'Активные бустеры',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...boosters
              .where((booster) => booster.isActive)
              .map(
                (booster) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ActiveBoosterCard(booster: booster),
                ),
              ),
          const SizedBox(height: 16),
        ],
        Text(
          'Магазин бустеров',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ShopItemCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _EffectsShop extends StatelessWidget {
  const _EffectsShop({required this.items});

  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _ShopItemCard(item: items[index]),
    );
  }
}

class _ShopItemCard extends ConsumerWidget {
  const _ShopItemCard({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final canEquip = item.isPurchased && !item.isEquipped;
    final canBuy = !item.isPurchased;
    final isBooster = item.type == ShopItemType.booster;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: item.isPurchased
                ? [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.secondaryContainer,
                  ]
                : [
                    theme.colorScheme.surfaceContainer,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(item.icon, style: const TextStyle(fontSize: 28)),
                ),
                const Spacer(),
                if (item.isLimited)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'LIMITED',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                item.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (item.isPurchased)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: item.isEquipped ? Colors.green : Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.isEquipped ? 'Экипировано' : 'Куплено',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: item.isEquipped ? Colors.white : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Row(
                children: [
                  Text(
                    item.currency.symbol,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    item.currency == ShopCurrency.tenge
                        ? _formatAmount(item.price)
                        : '${item.price}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: canBuy
                    ? () => ref.read(shopProvider.notifier).purchaseItem(item.id)
                    : canEquip
                        ? () => isBooster
                            ? ref.read(shopProvider.notifier).activateBooster(item.id)
                            : ref.read(shopProvider.notifier).equipItem(item.id)
                        : null,
                child: Text(
                  canBuy
                      ? 'Купить'
                      : canEquip
                          ? (isBooster ? 'Активировать' : 'Экипировать')
                          : 'Используется',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarCard extends ConsumerWidget {
  const _AvatarCard({required this.avatar});

  final UserAvatar avatar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: avatar.isUnlocked ? () => ref.read(shopProvider.notifier).equipAvatar(avatar.id) : null,
        child: Container(
          decoration: BoxDecoration(
            color: Color(avatar.backgroundColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(avatar.icon, style: const TextStyle(fontSize: 38)),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      avatar.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (!avatar.isUnlocked)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 28),
                ),
              if (avatar.isEquipped)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.green, size: 14),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends ConsumerWidget {
  const _ThemeCard({required this.item});

  final ShopItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 84,
              height: 64,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: item.isPurchased
                  ? () => ref.read(shopProvider.notifier).equipItem(item.id)
                  : () => ref.read(shopProvider.notifier).purchaseItem(item.id),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              child: Text(
                item.isPurchased
                    ? 'Надеть'
                    : '${item.currency.symbol} ${item.currency == ShopCurrency.tenge ? _formatAmount(item.price) : item.price}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBoosterCard extends StatelessWidget {
  const _ActiveBoosterCard({required this.booster});

  final Booster booster;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = booster.remainingMinutes;
    final hours = remaining ~/ 60;
    final minutes = remaining % 60;

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(booster.icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booster.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Осталось: ${hours > 0 ? '$hours ч ' : ''}$minutes мин',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.timer_outlined,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

String _formatAmount(int amount) {
  final digits = amount.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final reversedIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reversedIndex > 1 && reversedIndex % 3 == 1) {
      buffer.write(' ');
    }
  }
  return buffer.toString();
}
