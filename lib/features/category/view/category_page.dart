import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_icons.dart';
import '../../../core/models/category_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../bloc/category_bloc.dart';
import '../bloc/category_event.dart';
import '../bloc/category_state.dart';

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CategoryBloc()..add(const CategoryLoad()),
      child: const _CategoryBody(),
    );
  }
}

class _CategoryBody extends StatefulWidget {
  const _CategoryBody();

  @override
  State<_CategoryBody> createState() => _CategoryBodyState();
}

class _CategoryBodyState extends State<_CategoryBody>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoryBloc, CategoryState>(
      listener: (context, state) {
        if (state is CategorySuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is CategoryError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),

            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kategori'),
            elevation: 0,
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Pendapatan'),
                Tab(text: 'Pengeluaran'),
              ],
            ),
          ),
          body: state is CategoryLoaded
              ? TabBarView(
                  controller: _tabController,
                  children: [
                    _CategoryList(categories: state.incomeCategories),
                    _CategoryList(categories: state.expenseCategories),
                  ],
                )
              : (state is CategoryLoading || state is CategoryInitial)
                  ? const Center(child: CircularProgressIndicator())
                  : const SizedBox.shrink(),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              final sign = _tabController.index == 0 ? '+' : '-';
              context
                  .push('/settings/category/add', extra: sign)
                  .then((_) {
                if (context.mounted) {
                  context.read<CategoryBloc>().add(const CategoryLoad());
                }
              });
            },
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _CategoryList extends StatelessWidget {
  final List<CategoryModel> categories;

  const _CategoryList({required this.categories});

  Color _parseColor(String hex) {
    try {
      return Color(
          int.parse('FF${hex.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      return const Color(0xFF2b6788);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const EmptyState(
        icon: Icons.category_outlined,
        message: 'Belum ada kategori',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final color = _parseColor(cat.color);
        return InkWell(
          onTap: () => context
              .push('/settings/category/${cat.id}/edit')
              .then((_) {
            if (context.mounted) {
              context.read<CategoryBloc>().add(const CategoryLoad());
            }
          }),
          child: Container(
            color: context.cs.surfaceContainerLowest,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.only(bottom: 1),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(AppIcons.fromName(cat.icon),
                      color: color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    cat.name,
                    style: TextStyle(
                      fontSize: 15,
                      color: cat.active == 1
                          ? context.cs.onSurface
                          : context.cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Switch(
                  value: cat.active == 1,
                  onChanged: (_) {
                    context
                        .read<CategoryBloc>()
                        .add(CategoryToggleActive(cat));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
