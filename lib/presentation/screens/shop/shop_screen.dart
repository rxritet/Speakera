import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/shop.dart';
import '../../providers/shop_provider.dart';

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shopProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Магазин'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: ShopCategory.values.map((cat) => Tab(text: cat.label)).toList(),
        ),
        actions: [
          // Currency display
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: switch (state) {
              ShopLoaded(:final currency) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '${currency.xp}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ],
      ),
      body: switch (state) {
        ShopLoading() => const Center(child: CircularProgressIndicator()),
        ShopError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(message),
              ],
            ),
          ),
        ShopLoaded(:final items, :final boosters, :final avatars) => TabBarView(
            controller: _tabController,
            children: [
              _AllShop(items: items),
              _AvatarsShop(avatars: avatars, items: items.where((i) => i.type == ShopItemType.avatar).toList()),
              _ThemesShop(items: items.where((i) => i.type == ShopItemType.theme).toList()),
              _BoostersShop(boosters: boosters, items: items.where((i) => i.type == ShopItemType.booster).toList()),
              _EffectsShop(items: items.where((i) => i.type == ShopItemType.effect).toList()),
            ],
          ),
      },
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// SHOP TABS
// ────────────────────────────────────────────────────────────────────────────

class _AllShop extends StatelessWidget {
  const _AllShop({required this.items});
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Товары загружаются...'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
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
        childAspectRatio: 1,
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
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Темы скоро появятся!', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
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
        // Active boosters
        if (boosters.any((b) => b.isActive)) ...[
          Text(
            'Активные бустеры',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...boosters.where((b) => b.isActive).map((b) => _ActiveBoosterCard(booster: b)),
          const SizedBox(height: 24),
        ],
        // Available boosters
        Text(
          'Магазин бустеров',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _ShopItemCard(item: item)),
      ],
    );
  }
}

class _EffectsShop extends StatelessWidget {
  const _EffectsShop({required this.items});
  final List<ShopItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('Эффекты скоро появятся!', textAlign: TextAlign.center),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _ShopItemCard(item: items[index]),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// ITEM CARDS
// ────────────────────────────────────────────────────────────────────────────

class _ShopItemCard extends StatelessWidget {
  const _ShopItemCard({required this.item});
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPurchased = item.isPurchased;
    final isEquipped = item.isEquipped;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isPurchased && !isEquipped ? () => _showEquipDialog(context, item) : null,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPurchased
                  ? [theme.colorScheme.primaryContainer, theme.colorScheme.secondaryContainer]
                  : [theme.colorScheme.surfaceContainer, theme.colorScheme.surfaceContainerHighest],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    item.icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                item.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (isPurchased)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isEquipped ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isEquipped ? 'Экипировано' : 'Куплено',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.currency == ShopCurrency.xp ? '⚡' : '💎',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              if (item.isLimited) ...[
                const SizedBox(height: 8),
                Text(
                  'До ${item.limitedUntil != null ? "${item.limitedUntil!.day}.${item.limitedUntil!.month}" : ''}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showEquipDialog(BuildContext context, ShopItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: Text('Экипировать ${item.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () {
              // Equip item
              Navigator.pop(context);
            },
            child: const Text('Экипировать'),
          ),
        ],
      ),
    );
  }
}

class _AvatarCard extends StatelessWidget {
  const _AvatarCard({required this.avatar});
  final UserAvatar avatar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: avatar.isUnlocked ? () {} : null,
        child: Container(
          decoration: BoxDecoration(
            color: Color(avatar.backgroundColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Center(
                child: Text(
                  avatar.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              if (!avatar.isUnlocked)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.lock, color: Colors.white, size: 28),
                ),
              if (avatar.isUnlocked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: avatar.source == AvatarSource.achievement
                          ? Colors.amber
                          : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      avatar.source == AvatarSource.achievement
                          ? Icons.emoji_events
                          : Icons.check,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.item});
  final ShopItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
            if (item.isPurchased)
              const Icon(Icons.check_circle, color: Colors.green)
            else
            FilledButton(
              onPressed: () {
                // Purchase
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: Text('${item.price} ⚡'),
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
            Text(
              booster.icon,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    booster.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Осталось: ${hours > 0 ? '$hours ч ' : ''}${minutes} мин',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.timer,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
