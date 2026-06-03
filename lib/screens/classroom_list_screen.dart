import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/classroom_service.dart';
import '../models/classroom.dart';

// ─── Palette (shared constants) ─────────────────────────────────────────────
const _bg = Color(0xFF0F0D13);
const _surface = Color(0xFF1C1A22);
const _surface2 = Color(0xFF252230);
const _surface3 = Color(0xFF312D3C);
const _primary = Color(0xFFC9B8FF);
const _priCont = Color(0xFF3A2E6A);
const _ok = Color(0xFF94D4A4);
const _okBg = Color(0x2494D4A4);
const _wa = Color(0xFFF2C469);
const _waBg = Color(0x24F2C469);
const _er = Color(0xFFF28E8A);
const _erBg = Color(0x24F28E8A);
const _t1 = Color(0xFFEDE8F5);
const _t3 = Color(0xFF7B7585);

Color _statusColor(Classroom r) {
  if (r.hasCourse) return _er;
  if (r.currentPeople == 0) return _ok;
  return _wa;
}

Color _statusBg(Classroom r) {
  if (r.hasCourse) return _erBg;
  if (r.currentPeople == 0) return _okBg;
  return _waBg;
}

String _statusLabel(Classroom r) {
  if (r.hasCourse) return 'Cours';
  if (r.currentPeople == 0) return 'Libre';
  return 'Occupée';
}

IconData _typeIcon(RoomType t) {
  switch (t) {
    case RoomType.amphitheater:
      return Icons.theater_comedy_rounded;
    case RoomType.laboratory:
      return Icons.science_rounded;
    default:
      return Icons.meeting_room_rounded;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
enum _StatusFilter { all, libre, occupee, cours }

class ClassroomListScreen extends StatefulWidget {
  final String? initialQuery;
  const ClassroomListScreen({super.key, this.initialQuery});

  @override
  State<ClassroomListScreen> createState() => _ClassroomListScreenState();
}

class _ClassroomListScreenState extends State<ClassroomListScreen> {
  late TextEditingController _search;
  int? _floor;
  int? _corridor;
  RoomType? _type;
  _StatusFilter _status = _StatusFilter.all;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Classroom> _filter(List<Classroom> all) {
    return all.where((r) {
      if (_floor != null && r.floor != _floor) return false;
      if (_corridor != null && r.corridor != _corridor) return false;
      if (_type != null && r.type != _type) return false;
      if (_search.text.isNotEmpty &&
          !r.name.toLowerCase().contains(_search.text.toLowerCase())) {
        return false;
      }
      switch (_status) {
        case _StatusFilter.libre:
          return r.currentPeople == 0 && !r.hasCourse;
        case _StatusFilter.occupee:
          return r.currentPeople > 0 && !r.hasCourse;
        case _StatusFilter.cours:
          return r.hasCourse;
        case _StatusFilter.all:
          return true;
      }
    }).toList();
  }

  void _showFilterMenu(List<Classroom> all) {
    final floors = <int?>[
      ...(all.map((r) => r.floor).toSet().toList()..sort())
    ];
    final corridors = <int?>[
      ...(all.map((r) => r.corridor).toSet().toList()..sort())
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: _surface3,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filtres',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: _t1)),
                    TextButton(
                      onPressed: () {
                        setModalState(() {
                          _status = _StatusFilter.all;
                          _floor = null;
                          _corridor = null;
                          _type = null;
                        });
                        setState(() {});
                      },
                      child: const Text('Réinitialiser',
                          style: TextStyle(color: _primary, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Section: Statut ──
                const _FilterLabel(label: 'Statut'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _StatusFilter.values.map<Widget>((f) {
                    final labels = {
                      _StatusFilter.all: 'Toutes',
                      _StatusFilter.libre: 'Libres',
                      _StatusFilter.occupee: 'Occupées',
                      _StatusFilter.cours: 'Cours',
                    };
                    final on = _status == f;
                    return _MenuChip(
                      label: labels[f]!,
                      active: on,
                      onTap: () {
                        setModalState(() => _status = f);
                        setState(() {});
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Section: Type ──
                const _FilterLabel(label: 'Type de salle'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MenuChip(
                      label: 'Tous',
                      active: _type == null,
                      onTap: () {
                        setModalState(() => _type = null);
                        setState(() {});
                      },
                    ),
                    ...RoomType.values.map<Widget>((t) {
                      final label = {
                        RoomType.classroom: 'Salle',
                        RoomType.laboratory: 'Labo',
                        RoomType.amphitheater: 'Amphi',
                      }[t]!;
                      return _MenuChip(
                        label: label,
                        active: _type == t,
                        onTap: () {
                          setModalState(() => _type = t);
                          setState(() {});
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Section: Étage & Épi ──
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FilterLabel(label: 'Étage'),
                          const SizedBox(height: 8),
                          _MenuDrop<int?>(
                            value: _floor,
                            items: [null, ...floors],
                            label: (v) => v == null ? 'Tous' : 'Étage $v',
                            onChanged: (v) {
                              setModalState(() => _floor = v);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FilterLabel(label: 'Épi'),
                          const SizedBox(height: 8),
                          _MenuDrop<int?>(
                            value: _corridor,
                            items: [null, ...corridors],
                            label: (v) => v == null ? 'Tous' : 'Épi $v',
                            onChanged: (v) {
                              setModalState(() => _corridor = v);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ClassroomService>();
    final all = svc.classrooms;
    final rooms = _filter(all);

    final hasFilters = _status != _StatusFilter.all ||
        _floor != null ||
        _corridor != null ||
        _type != null;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Salles',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: _t1,
                          letterSpacing: -.5)),
                  GestureDetector(
                    onTap: () => _showFilterMenu(all),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasFilters ? _priCont : _surface,
                        borderRadius: BorderRadius.circular(16),
                        border: hasFilters
                            ? Border.all(color: _primary.withValues(alpha: 0.3))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.tune_rounded,
                              size: 18,
                              color: hasFilters ? _primary : _t3),
                          const SizedBox(width: 8),
                          Text('Filtres',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: hasFilters ? _primary : _t3)),
                          if (hasFilters) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                  color: _primary, shape: BoxShape.circle),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Search bar ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                    color: _surface, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: _t3, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                            color: _t1,
                            fontWeight: FontWeight.w600,
                            fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Rechercher une salle…',
                          hintStyle: TextStyle(color: _t3),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                          fillColor: Colors.transparent,
                          filled: false,
                        ),
                      ),
                    ),
                    if (_search.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _search.clear()),
                        child: const Icon(Icons.close_rounded,
                            color: _t3, size: 18),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Result count ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                '${rooms.length} salle${rooms.length > 1 ? 's' : ''}',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _t3,
                    letterSpacing: .6),
              ),
            ),
            const SizedBox(height: 10),

            // ── List ───────────────────────────────────────────────────────
            Expanded(
              child: rooms.isEmpty
                  ? const Center(
                      child: Text('Aucune salle trouvée.',
                          style: TextStyle(
                              color: _t3, fontWeight: FontWeight.w600)),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                      itemCount: rooms.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) =>
                          _RoomTile(room: rooms[i], svc: svc),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Menu Widgets ───────────────────────────────────────────────────────────
class _FilterLabel extends StatelessWidget {
  final String label;
  const _FilterLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _t3,
            letterSpacing: 1));
  }
}

class _MenuChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _MenuChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _priCont : _surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active ? _primary.withValues(alpha: 0.5) : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: active ? _primary : _t1,
          ),
        ),
      ),
    );
  }
}

class _MenuDrop<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  const _MenuDrop(
      {required this.value,
        required this.items,
        required this.label,
        required this.onChanged});


  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(14),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items
            .map((i) => DropdownMenuItem(
          value: i,
          child: Text(label(i),
              style: const TextStyle(
                  color: _t1,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ))
            .toList(),
        onChanged: (v) {
          if (v != null || items.contains(null)) onChanged(v as T);
        },
        underline: const SizedBox(),
        isExpanded: true,
        dropdownColor: _surface3,
        icon: const Icon(Icons.expand_more_rounded, color: _t3),
      ),
    );
  }
}

// ─── Room tile ───────────────────────────────────────────────────────────────
class _RoomTile extends StatelessWidget {
  final Classroom room;
  final ClassroomService svc;
  const _RoomTile({required this.room, required this.svc});

  @override
  Widget build(BuildContext context) {
    final col = _statusColor(room);
    final bg = _statusBg(room);
    final isFav = svc.isFavorite(room.id);

    return Container(
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(16)),
            child: Icon(_typeIcon(room.type), color: col, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: _t1)),
                const SizedBox(height: 3),
                Text(
                    '${room.typeLabel} · Étage ${room.floor} · Épi ${room.corridor}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600, color: _t3)),
                if (room.currentPeople > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 12, color: _t3),
                        const SizedBox(width: 3),
                        Text('${room.currentPeople} personnes',
                            style: const TextStyle(
                                fontSize: 11,
                                color: _t3,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(20)),
                child: Text(_statusLabel(room),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: col,
                        letterSpacing: .3)),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => svc.toggleFavorite(room.id),
                child: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? _wa : _t3,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
