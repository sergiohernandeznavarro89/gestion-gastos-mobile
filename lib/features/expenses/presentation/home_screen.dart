import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'home_provider.dart';
import 'widgets/account_slider.dart';
import 'widgets/pending_items_list.dart';

enum HomeFilter { pendientes, todos }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  HomeFilter? _currentFilter;

  @override
  Widget build(BuildContext context) {
    final homeDataAsync = ref.watch(homeDataProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              ref.invalidate(homeDataProvider);
            },
          ),
        ],
      ),
      body: homeDataAsync.when(
        data: (data) {
          final effectiveFilter = _currentFilter ?? (data.currentMonthItems.isEmpty ? HomeFilter.todos : HomeFilter.pendientes);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(homeDataProvider);
              try {
                await ref.read(homeDataProvider.future);
              } catch (_) {}
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: AccountSlider(accounts: data.accounts)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                SliverToBoxAdapter(child: _buildFilters(effectiveFilter)),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                if (effectiveFilter == HomeFilter.pendientes)
                  PendingItemsList(
                    currentMonthItems: data.currentMonthItems,
                    nextMonthItems: data.nextMonthItems,
                    hideNextMonth: false,
                  )
                else ...[
                  PendingItemsList(
                    currentMonthItems: data.executedItems,
                    nextMonthItems: const [],
                    hideNextMonth: true,
                  ),
                  if (data.hasMoreData)
                    SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 32.0),
                          child: TextButton.icon(
                            onPressed: () {
                              ref.read(homeDataProvider.notifier).loadMoreMonths();
                            },
                            icon: const Icon(Icons.add),
                            label: const Text('Cargar mes anterior'),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
                const SizedBox(height: 24),
                Text(
                  'Ocurrió un error al cargar tus datos',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString().replaceAll('Exception: ', ''),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(homeDataProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilters(HomeFilter effectiveFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        children: [
          _buildChip('Mov. Pendientes', HomeFilter.pendientes, effectiveFilter),
          const SizedBox(width: 8),
          _buildChip('Mov. Realizados', HomeFilter.todos, effectiveFilter),
        ],
      ),
    );
  }

  Widget _buildChip(String label, HomeFilter filter, HomeFilter effectiveFilter) {
    return ChoiceChip(
      label: Text(label),
      selected: effectiveFilter == filter,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentFilter = filter;
          });
        }
      },
    );
  }
}
