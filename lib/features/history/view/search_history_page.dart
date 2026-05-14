import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/history_model.dart';
import '../../../core/repositories/interfaces/i_history_repository.dart';
import '../../../shared/widgets/empty_state.dart';
import '../widgets/history_list_item.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SearchHistoryPage extends StatefulWidget {
  const SearchHistoryPage({super.key});

  @override
  State<SearchHistoryPage> createState() => _SearchHistoryPageState();
}

class _SearchHistoryPageState extends State<SearchHistoryPage> {
  final _controller = TextEditingController();
  List<HistoryModel> _results = [];
  bool _searched = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() { _results = []; _searched = false; });
      return;
    }
    final repo = context.read<IHistoryRepository>();
    final results = await repo.search(query.trim());
    if (mounted) setState(() { _results = results; _searched = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(12),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.darkBlue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Cari transaksi...',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: _search,
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() { _results = []; _searched = false; });
                        },
                        child: const Icon(Icons.close,
                            color: AppColors.darkGray, size: 20),
                      ),
                  ],
                ),
              ),
            ),
            // Results
            Expanded(
              child: !_searched
                  ? const EmptyState(
                      icon: Icons.history,
                      message: 'Belum ada transaksi',
                    )
                  : _results.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off,
                          message: 'Tidak ada hasil',
                        )
                      : ListView.builder(
                          itemCount: _results.length,
                          itemBuilder: (_, i) {
                            final item = _results[i];
                            return HistoryListItem(
                              item: item,
                              onTap: () {
                                if (item.type == 2 || item.type == 4) {
                                  context.push(
                                      '/history/transfer/${item.transferId}');
                                } else {
                                  context.push('/history/${item.id}');
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
