import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/classroom.dart';
import '../models/course_detail.dart';
import '../services/classroom_service.dart';
import '../services/timetable_service.dart';

class RoomDetailSheet extends StatefulWidget {
  final Classroom room;

  const RoomDetailSheet({super.key, required this.room});

  static void show(BuildContext context, Classroom room) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomDetailSheet(room: room),
    );
  }

  @override
  State<RoomDetailSheet> createState() => _RoomDetailSheetState();
}

class _RoomDetailSheetState extends State<RoomDetailSheet> {
  Future<CourseDetail?>? _courseFuture;

  @override
  void initState() {
    super.initState();
    if (widget.room.hasCourse && widget.room.icalResourceId != null) {
      _courseFuture = context.read<TimetableService>().fetchCurrentCourse(widget.room.icalResourceId!);
    }
  }

  Color _statusColor(BuildContext context, Classroom r) {
    final cs = Theme.of(context).colorScheme;
    if (r.hasCourse) return cs.error;
    if (r.currentPeople == 0) return Colors.green;
    return Colors.orange;
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final svc = context.watch<ClassroomService>();
    final isFav = svc.isFavorite(widget.room.id);
    final col = _statusColor(context, widget.room);
    final bg = _statusBg(context, widget.room);

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(_typeIcon(widget.room.type), color: col, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.room.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: cs.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      widget.room.typeLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: () => svc.toggleFavorite(widget.room.id),
                icon: Icon(
                  isFav ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isFav ? Colors.orange : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // ── Status Badge ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: col,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusLabel(widget.room).toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: col,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (widget.room.currentPeople > 0)
                Text(
                  '${widget.room.currentPeople} personnes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Information Cards ──
          Row(
            children: [
              _InfoCard(
                icon: Icons.layers_rounded,
                label: 'Étage',
                value: widget.room.floor.toString(),
              ),
              const SizedBox(width: 12),
              _InfoCard(
                icon: Icons.map_rounded,
                label: 'Épi',
                value: widget.room.corridor.toString(),
              ),
            ],
          ),
          
          if (widget.room.hasCourse) ...[
            const SizedBox(height: 24),
            Text(
              'COURS ACTUEL',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            FutureBuilder<CourseDetail?>(
              future: _courseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final course = snapshot.data;
                final courseName = course?.name ?? widget.room.currentCourse ?? 'Chargement...';
                final prof = course?.professor ?? 'Enseignant inconnu';
                final hours = course?.timeRange ?? '';

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.errorContainer.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: cs.error.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.school_rounded, color: cs.error, size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    courseName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurface,
                                    ),
                                  ),
                                ),
                                if (hours.isNotEmpty)
                                  Text(
                                    hours,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: cs.error,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              prof,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          if (!widget.room.hasCourse && widget.room.nextCourseStart != null) ...[
            const SizedBox(height: 24),
            Text(
              'PROCHAINE OCCUPATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cs.primary.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Icon(Icons.event_available_rounded, color: cs.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Libre jusqu\'à ${DateFormat('HH:mm').format(widget.room.nextCourseStart!)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Un cours commencera à cette heure là.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 20),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
