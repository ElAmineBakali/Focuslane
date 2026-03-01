import 'package:flutter/material.dart';
import '../../../screens/culture/services/culture_firestore_service.dart';
import '../models/culture_models.dart';

class BooksListScreen extends StatefulWidget {
  const BooksListScreen({super.key});
  static const route = '/culture/books';

  @override
  State<BooksListScreen> createState() => _BooksListScreenState();
}

class _BooksListScreenState extends State<BooksListScreen> {
  ItemStatus? _status;

  @override
  Widget build(BuildContext context) {
    final svc = CultureFirestoreService.I;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Libros'),
        actions: [
          PopupMenuButton<ItemStatus?>(
            initialValue: _status,
            onSelected: (v) => setState(() => _status = v),
            itemBuilder:
                (_) => [
                  const PopupMenuItem(value: null, child: Text('Todos')),
                  ...ItemStatus.values.map(
                    (e) => PopupMenuItem(value: e, child: Text(e.name)),
                  ),
                ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/culture/book/edit'),
          ),
        ],
      ),
      body: StreamBuilder<List<Book>>(
        stream: svc.watchBooks(status: _status),
        builder: (_, s) {
          final data = s.data ?? [];
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.isEmpty) return const Center(child: Text('Sin libros'));
          return ListView.separated(
            itemCount: data.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final b = data[i];
              return ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: Text(b.title),
                subtitle: Text(
                  '${b.author ?? "â€”"} â€¢ ${b.genre ?? ""} â€¢ ${b.status.name}',
                ),
                trailing: SizedBox(
                  width: 80,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(b.rating?.toStringAsFixed(1) ?? '-'),
                      const Text('â­', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                ),
                onTap:
                    () => Navigator.pushNamed(
                      context,
                      '/culture/book',
                      arguments: b,
                    ),
              );
            },
          );
        },
      ),
    );
  }
}



