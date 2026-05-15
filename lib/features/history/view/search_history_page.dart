import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
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
      appBar: AppBar(
        elevation: 0,
        titleSpacing: 0,
        title: Container(
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: context.cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          child: Row(
            children: [
              Icon(Icons.search, color: context.cs.onSurfaceVariant, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  cursorColor: context.cs.primary,
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
                  child: Icon(Icons.close,
                      color: context.cs.onSurfaceVariant, size: 20),
                ),
            ],
          ),
        ),
      ),
        body: Column(
          children: [
            // Results
            Expanded(
              child: !_searched
                  ? const EmptyState(
                      icon: Icons.history,
                      message: 'Ketik untuk mencari transaksi',
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
    );
  }
}
