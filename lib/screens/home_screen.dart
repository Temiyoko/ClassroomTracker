import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../services/classroom_service.dart';
import '../services/notification_service.dart';
import '../models/classroom.dart';
import '../widgets/room_detail_sheet.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────
Color _statusColor(BuildContext context, Classroom r) {
  final cs = Theme.of(context).colorScheme;
  if (r.hasCourse) return cs.error;
  if (r.currentPeople == 0) {
    return Colors
        .green; // Material 3 doesn't have a "success" in ColorScheme by default, but we can use green or secondary
  }
  return Colors.orange; // warning
}

Color _statusBg(BuildContext context, Classroom r) {
  final cs = Theme.of(context).colorScheme;
  if (r.hasCourse) return cs.errorContainer.withValues(alpha: 0.3);
  if (r.currentPeople == 0) return Colors.green.withValues(alpha: 0.15);
  return Colors.orange.withValues(alpha: 0.15);
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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.watch<ClassroomService>();
    final cs = Theme.of(context).colorScheme;
    final all = svc.classrooms;
    final favs = svc.favorites;

    // Group by corridor → floor
    final Map<int, Map<int, List<Classroom>>> byCorridorFloor = {};
    for (final r in all) {
      byCorridorFloor.putIfAbsent(r.corridor, () => {});
      byCorridorFloor[r.corridor]!.putIfAbsent(r.floor, () => []);
      byCorridorFloor[r.corridor]![r.floor]!.add(r);
    }
    final sortedCorridors = byCorridorFloor.keys.toList()..sort();

    final free = all.where((r) => r.currentPeople == 0 && !r.hasCourse).length;
    final busy = all.where((r) => r.currentPeople > 0 || r.hasCourse).length;
    final withCourse = all.where((r) => r.hasCourse).length;
    final pct = all.isEmpty ? 0 : (busy * 100 / all.length).round();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bonjour',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: cs.onSurface,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ESIEE Paris',
                            style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    const _NotifButton(),
                  ],
                ),
              ),
            ),

            // ── Occupancy hero ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: _HeroCard(
                    pct: pct,
                    free: free,
                    busy: busy,
                    total: all.length,
                    withCourse: withCourse),
              ),
            ),

            // ── Section: Favoris ───────────────────────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'Favoris', actionLabel: null),
            ),
            if (favs.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Marquez des salles ★ pour les retrouver ici.',
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 114,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: favs.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _FavChip(room: favs[i], svc: svc),
                  ),
                ),
              ),

            // ── Section: Par couloir ──────────────────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'Par couloir', actionLabel: null),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemCount: sortedCorridors.length,
                itemBuilder: (_, i) {
                  final corridor = sortedCorridors[i];
                  final floorMap = byCorridorFloor[corridor]!;
                  return _CorridorCard(corridor: corridor, floorMap: floorMap);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets ────────────────────────────────────────────────────────────────
class _NotifButton extends StatelessWidget {
  const _NotifButton();

  void _showNotificationCenter(BuildContext context) {
    final notifSvc = context.read<NotificationService>();
    final cs = Theme.of(context).colorScheme;
    notifSvc.markAllAsRead();

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          final cs = Theme.of(context).colorScheme;
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: cs.outlineVariant,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notifications',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface)),
                    TextButton(
                      onPressed: () {
                        notifSvc.clearAll();
                        Navigator.pop(context);
                      },
                      child: Text('Tout effacer',
                          style: TextStyle(color: cs.error, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Consumer<NotificationService>(
                    builder: (context, svc, _) {
                      final notifications = svc.notifications;
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none_rounded,
                                  size: 48,
                                  color: cs.onSurfaceVariant
                                      .withValues(alpha: 0.3)),
                              const SizedBox(height: 16),
                              Text('Aucune notification',
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final n = notifications[i];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: cs.primaryContainer
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.check_circle_outline,
                                      color: cs.onPrimaryContainer, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(n.title,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w800,
                                                  color: cs.onSurface)),
                                          Text(
                                            DateFormat('HH:mm')
                                                .format(n.timestamp),
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: cs.onSurfaceVariant),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(n.body,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: cs.onSurfaceVariant,
                                              height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread =
        context.select<NotificationService, int>((s) => s.unreadCount);
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showNotificationCenter(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.notifications_outlined,
                color: cs.onSurfaceVariant, size: 22),
          ),
          if (unread > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.surface, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  const _SectionHeader({required this.title, this.actionLabel});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                  letterSpacing: .8)),
          if (actionLabel != null)
            Text(actionLabel!,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: cs.primary)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatefulWidget {
  final int pct, free, busy, total, withCourse;
  const _HeroCard(
      {required this.pct,
      required this.free,
      required this.busy,
      required this.total,
      required this.withCourse});

  @override
  State<_HeroCard> createState() => _HeroCardState();
}

class _HeroCardState extends State<_HeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;

    final bg = isDark ? cs.onPrimary : cs.primary;
    final fg = isDark ? cs.primary : cs.onPrimary;
    final waveColor = fg.withValues(alpha: 0.05);

    return Container(
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Wave effect
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _WavePainter(
                    waveValue: _controller.value,
                    fillLevel: widget.pct / 100,
                    color: waveColor,
                  ),
                );
              },
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('OCCUPATION GLOBALE',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: fg,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${widget.pct}',
                        style: TextStyle(
                            fontSize: 72,
                            fontWeight: FontWeight.w900,
                            color: fg,
                            letterSpacing: -3,
                            height: 1)),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10, left: 4),
                      child: Text('%',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: fg.withValues(alpha: 0.9))),
                    ),
                  ],
                ),
                Text(
                    '${widget.busy} salle${widget.busy > 1 ? 's' : ''} occupée${widget.busy > 1 ? 's' : ''} sur ${widget.total}',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: fg)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _HeroStat(
                        value: '${widget.free}', label: 'Libres', color: fg),
                    const SizedBox(width: 10),
                    _HeroStat(
                        value: '${widget.withCourse}',
                        label: 'En cours',
                        color: fg),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final double waveValue;
  final double fillLevel;
  final Color color;

  _WavePainter({
    required this.waveValue,
    required this.fillLevel,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();

    double amplitude = 8.0;
    double wavelength = size.width;
    double baseHeight = size.height * (1 - fillLevel);

    path.moveTo(0, baseHeight);

    for (double x = 0; x <= size.width; x++) {
      double y =
          math.sin((x / wavelength * 2 * math.pi) + (waveValue * 2 * math.pi)) *
                  amplitude +
              baseHeight;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.waveValue != waveValue || oldDelegate.fillLevel != fillLevel;
}

class _HeroStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _HeroStat(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w900, color: color)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: color.withValues(alpha: 0.9),
                    letterSpacing: .5)),
          ],
        ),
      ),
    );
  }
}

class _FavChip extends StatelessWidget {
  final Classroom room;
  final ClassroomService svc;
  const _FavChip({required this.room, required this.svc});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final col = _statusColor(context, room);
    final bg = _statusBg(context, room);
    return GestureDetector(
      onTap: () => RoomDetailSheet.show(context, room),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: BorderRadius.circular(12)),
                  child: Icon(_typeIcon(room.type), color: col, size: 18),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => svc.toggleFavorite(room.id),
                  child: const Icon(Icons.star_rounded,
                      color: Colors.orange, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(room.name,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface)),
            const SizedBox(height: 2),
            Text(_statusLabel(room),
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700, color: col)),
          ],
        ),
      ),
    );
  }
}

// ─── Corridor / Floor breakdown ──────────────────────────────────────────────
class _CorridorCard extends StatelessWidget {
  final int corridor;
  final Map<int, List<Classroom>> floorMap;
  const _CorridorCard({required this.corridor, required this.floorMap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sortedFloors = floorMap.keys.toList()..sort();
    final allRooms = floorMap.values.expand((r) => r).toList();
    final freeCount =
        allRooms.where((r) => r.currentPeople == 0 && !r.hasCourse).length;
    final total = allRooms.length;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  corridor > 0 ? 'Épi $corridor' : "Rue",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: freeCount > 0
                      ? Colors.green.withValues(alpha: 0.15)
                      : cs.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$freeCount libre${freeCount > 1 ? 's' : ''} / $total',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: freeCount > 0 ? Colors.green : cs.error,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Floors
          for (int i = 0; i < sortedFloors.length; i++) ...[
            if (i > 0)
              Divider(
                height: 16,
                thickness: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            _FloorRow(
                floor: sortedFloors[i], rooms: floorMap[sortedFloors[i]]!),
          ],
        ],
      ),
    );
  }
}

class _FloorRow extends StatelessWidget {
  final int floor;
  final List<Classroom> rooms;
  const _FloorRow({required this.floor, required this.rooms});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = rooms.length;
    final freeRooms =
        rooms.where((r) => r.currentPeople == 0 && !r.hasCourse).toList();
    final freeCount = freeRooms.length;
    final pct = total == 0 ? 0.0 : (total - freeCount) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Étage $floor',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: Colors.green.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct > 0.7
                        ? cs.error
                        : pct > 0.4
                            ? Colors.orange
                            : Colors.green,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$freeCount/$total',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (freeRooms.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              ...freeRooms.take(3).map((r) => _FreeRoomChip(room: r)),
              if (freeRooms.length > 3) _MoreChip(count: freeRooms.length - 3),
            ],
          ),
        ],
      ],
    );
  }
}

class _FreeRoomChip extends StatelessWidget {
  final Classroom room;
  const _FreeRoomChip({required this.room});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => RoomDetailSheet.show(context, room),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Text(
          room.name,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}

class _MoreChip extends StatelessWidget {
  final int count;
  const _MoreChip({required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '+$count autres',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}
