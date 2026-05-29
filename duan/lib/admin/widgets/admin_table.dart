import 'package:flutter/material.dart';

class AdminTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;

  const AdminTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [

          /// HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FA),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E9F0), width: 1),
              ),
            ),
            child: Row(
              children: headers
                  .map(
                    (h) => Expanded(
                      child: Text(
                        h,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF37474F),
                          fontSize: 12.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          /// BODY
          Expanded(
            child: rows.isEmpty
                ? _emptyState()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: rows.length,
                    separatorBuilder: (_, __) => const Divider(
                      height: 1,
                      color: Color(0xFFF0F2F5),
                    ),
                    itemBuilder: (context, i) {
                      return _DataRow(
                        cells: rows[i],
                        isAlt: i.isOdd,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              "No data",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataRow extends StatefulWidget {
  final List<Widget> cells;
  final bool isAlt;

  const _DataRow({required this.cells, required this.isAlt});

  @override
  State<_DataRow> createState() => _DataRowState();
}

class _DataRowState extends State<_DataRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final base = widget.isAlt
        ? const Color(0xFFFBFCFD)
        : Colors.white;
    final bg = _hovered ? const Color(0xFFEFF6FC) : base;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: widget.cells
              .map((cell) => Expanded(child: cell))
              .toList(),
        ),
      ),
    );
  }
}
