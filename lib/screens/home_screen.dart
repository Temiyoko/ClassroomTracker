import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/classroom_service.dart';
import '../services/notification_service.dart';
import '../models/classroom.dart';

// ─── Palette ───────────────────────────────────────────────────────────────
const _bg = Color(0xFF0F0D13);
const _surface = Color(0xFF1C1A22);
const _primary = Color(0xFFC9B8FF);
const _priCont = Color(0xFF3A2E6A);
const _onPriCont = Color(0xFFEDE0FF);
const _ok = Color(0xFF94D4A4);
const _okBg = Color(0x2494D4A4);
const _wa = Color(0xFFF2C469);
const _waBg = Color(0x24F2C469);
const _er = Color(0xFFF28E8A);
const _erBg = Color(0x24F28E8A);
const _t1 = Color(0xFFEDE8F5);
const _t2 = Color(0xFFC4BDD1);
const _t3 = Color(0xFF7B7585);

// ─── Helpers ────────────────────────────────────────────────────────────────
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
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final svc = context.watch<ClassroomService>();
    final all = svc.classrooms;
    final favs = svc.favorites;

    final free = all.where((r) => r.currentPeople == 0 && !r.hasCourse).length;
    final busy = all.where((r) => r.currentPeople > 0 || r.hasCourse).length;
    final withCourse = all.where((r) => r.hasCourse).length;
    final pct = all.isEmpty ? 0 : (busy * 100 / all.length).round();
    final freeFavs =
        favs.where((r) => r.currentPeople == 0 && !r.hasCourse).toList();

    return Scaffold(
      backgroundColor: _bg,
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
                            'Bonjour, ${auth.userName ?? ''}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: _t1,
                              letterSpacing: -.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            auth.schoolOrg ?? '',
                            style: const TextStyle(
                                fontSize: 13,
                                color: _t3,
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
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Text(
                    'Marquez des salles ★ pour les retrouver ici.',
                    style: TextStyle(
                        fontSize: 13, color: _t3, fontWeight: FontWeight.w600),
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

            // ── Section: Actives ───────────────────────────────────────────
            const SliverToBoxAdapter(
              child: _SectionHeader(title: 'En ce moment', actionLabel: null),
            ),
            SliverList.separated(
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: all.take(5).length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _RoomCard(room: all[i], svc: svc),
              ),
            ),

            // ── Logout ─────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 20),
                child: TextButton.icon(
                  onPressed: () => context.read<AuthService>().logout(),
                  icon: const Icon(Icons.logout_rounded, size: 18, color: _t3),
                  label: const Text('Déconnexion',
                      style:
                          TextStyle(color: _t3, fontWeight: FontWeight.w700)),
                ),
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
    notifSvc.markAllAsRead();

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _t3, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifications',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _t1)),
                  TextButton(
                    onPressed: () {
                      notifSvc.clearAll();
                      Navigator.pop(context);
                    },
                    child: const Text('Tout effacer',
                        style: TextStyle(color: _er, fontSize: 13)),
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
                                size: 48, color: _t3.withAlpha(50)),
                            const SizedBox(height: 16),
                            const Text('Aucune notification',
                                style: TextStyle(
                                    color: _t3, fontWeight: FontWeight.w600)),
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
                            color: _bg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _okBg,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.check_circle_outline,
                                    color: _ok, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(n.title,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: _t1)),
                                        Text(
                                          DateFormat('HH:mm').format(n.timestamp),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: _t3),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(n.body,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _t2,
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unread = context.select<NotificationService, int>((s) => s.unreadCount);

    return GestureDetector(
      onTap: () => _showNotificationCenter(context),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: _surface, borderRadius: BorderRadius.circular(14)),
            child:
                const Icon(Icons.notifications_outlined, color: _t2, size: 22),
          ),
          if (unread > 0)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: _er,
                  shape: BoxShape.circle,
                  border: Border.all(color: _bg, width: 2),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: _t3,
                  letterSpacing: .8)),
          if (actionLabel != null)
            Text(actionLabel!,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _primary)),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int pct, free, busy, total, withCourse;
  const _HeroCard(
      {required this.pct,
      required this.free,
      required this.busy,
      required this.total,
      required this.withCourse});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: _priCont, borderRadius: BorderRadius.circular(28)),
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OCCUPATION GLOBALE',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: _primary,
                  letterSpacing: 1)),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$pct',
                  style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.w900,
                      color: _onPriCont,
                      letterSpacing: -3,
                      height: 1)),
              const Padding(
                padding: EdgeInsets.only(bottom: 10, left: 4),
                child: Text('%',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _primary)),
              ),
            ],
          ),
          Text(
              '$busy salle${busy > 1 ? 's' : ''} occupée${busy > 1 ? 's' : ''} sur $total',
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: _primary)),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(value: '$free', label: 'Libres'),
              const SizedBox(width: 10),
              _HeroStat(value: '$withCourse', label: 'En cours'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value, label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: _onPriCont)),
            Text(label,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _primary,
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
    final col = _statusColor(room);
    final bg = _statusBg(room);
    return Container(
      width: 130,
      decoration: BoxDecoration(
          color: _surface, borderRadius: BorderRadius.circular(20)),
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
                child: const Icon(Icons.star_rounded, color: _wa, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(room.name,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w800, color: _t1)),
          const SizedBox(height: 2),
          Text(_statusLabel(room),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700, color: col)),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Classroom room;
  final ClassroomService svc;
  const _RoomCard({required this.room, required this.svc});

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
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(16)),
            child: Icon(_typeIcon(room.type), color: col, size: 22),
          ),
          const SizedBox(width: 14),
          // Info
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
              ],
            ),
          ),
          // Status badge
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
              const SizedBox(height: 6),
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
