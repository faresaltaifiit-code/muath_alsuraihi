import 'package:flutter/material.dart';

class JuzScreen extends StatelessWidget {
  const JuzScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('الأجزاء')),
        body: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          itemCount: 30,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final number = index + 1;
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text('$number')),
                title: Text('الجزء $number'),
                subtitle: const Text('استعرض التلاوات من قائمة السور'),
                trailing: const Icon(Icons.chevron_left_rounded),
              ),
            );
          },
        ),
      );
}
