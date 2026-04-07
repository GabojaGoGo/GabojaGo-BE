import 'package:flutter/material.dart';
import '../models/user_prefs.dart';
import '../services/api_service.dart';
import '../services/user_data_service.dart';
import 'course_detail_screen.dart';
import 'receipt_screen.dart';
import 'travel_setup_screen.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  List<Map<String, dynamic>> _courses = [];
  bool _loading = false;
  UserPrefs? _loadedPrefs; // 마지막으로 로드한 취향 (변경 감지용)

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final prefs = UserPrefsScope.of(context).prefs;
    // 취향이 바뀌었을 때만 리로드
    if (prefs.hasPrefs &&
        (prefs.purposes.toString() != _loadedPrefs?.purposes.toString() ||
         prefs.duration != _loadedPrefs?.duration)) {
      _loadCourses(prefs);
    }
  }

  Future<void> _loadCourses(UserPrefs prefs) async {
    setState(() { _loading = true; _loadedPrefs = prefs; });
    try {
      final courses = await ApiService.getCoursesWithDetail(
        purposes: prefs.purposes,
        duration: prefs.duration,
      );
      if (mounted) setState(() { _courses = courses; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _courses = []; _loading = false; });
    }
  }

  void _goToSetup() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TravelSetupScreen(showCourseResult: false),
      ),
    );
    // didChangeDependencies가 취향 변경을 감지해서 자동으로 reload
  }

  void _showSavedCourses() {
    final saved = UserDataService.instance.getSavedCourses();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SavedCoursesSheet(
        courses: saved,
        onRemove: (contentId) async {
          await UserDataService.instance.removeSavedCourse(contentId);
          if (!mounted) return;
          setState(() {});
          Navigator.pop(context);
          _showSavedCourses(); // 재열기
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prefs = UserPrefsScope.of(context).prefs;
    final savedCount = UserDataService.instance.getSavedCourses().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 여행 플래너',
            style: TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.bookmark_outlined),
                onPressed: _showSavedCourses,
                tooltip: '내 플래너',
              ),
              if (savedCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2E7D6B),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$savedCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ReceiptScreen())),
            tooltip: '영수증 스캔',
          ),
        ],
      ),
      body: !prefs.hasPrefs
          ? _buildEmptyState(context)
          : _buildCourseList(context, prefs),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('취향을 먼저 설정해보세요',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('맞춤 여행 코스를 추천해드릴게요',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _goToSetup,
              icon: const Icon(Icons.tune_outlined),
              label: const Text('취향 설정하기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseList(BuildContext context, UserPrefs prefs) {
    final purposeLabels = prefs.purposes
        .map((k) => kPurposeOptions
            .firstWhere((o) => o['key'] == k,
                orElse: () => {'label': k})['label']!)
        .toList();
    final durationLabel = prefs.duration.isNotEmpty
        ? kDurationOptions
            .firstWhere((o) => o['key'] == prefs.duration,
                orElse: () => {'label': prefs.duration})['label']!
        : '';

    return CustomScrollView(
      slivers: [
        // 취향 요약 헤더
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D6B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF2E7D6B).withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      ...purposeLabels.map((label) => _PrefChip(label: label)),
                      if (durationLabel.isNotEmpty)
                        _PrefChip(label: durationLabel, isDuration: true),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: _goToSetup,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF2E7D6B),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('다른 추천\n받아볼래요',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),

        // 결과 카운트
        if (!_loading)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            sliver: SliverToBoxAdapter(
              child: Text(
                '내 취향 맞춤 코스 ${_courses.length}개',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),

        // 로딩
        if (_loading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),

        // 코스 없음
        if (!_loading && _courses.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('😔', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 12),
                  const Text('조건에 맞는 코스가 없어요',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _goToSetup,
                    child: const Text('다른 취향으로 다시 추천받기'),
                  ),
                ],
              ),
            ),
          ),

        // 코스 카드 목록
        if (!_loading && _courses.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _CourseCard(
                    course: _courses[i],
                    purposes: prefs.purposes,
                    onSaveChanged: () => setState(() {}),
                  ),
                ),
                childCount: _courses.length,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── 취향 칩 ──────────────────────────────────────────────
class _PrefChip extends StatelessWidget {
  final String label;
  final bool isDuration;
  const _PrefChip({required this.label, this.isDuration = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDuration
            ? const Color(0xFF1565C0).withValues(alpha: 0.1)
            : const Color(0xFF2E7D6B).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDuration
              ? const Color(0xFF1565C0)
              : const Color(0xFF2E7D6B),
        ),
      ),
    );
  }
}

// ─── 코스 카드 (스크린샷 기반 UI) ─────────────────────────
class _CourseCard extends StatefulWidget {
  final Map<String, dynamic> course;
  final List<String> purposes;
  final VoidCallback onSaveChanged;

  const _CourseCard({
    required this.course,
    required this.purposes,
    required this.onSaveChanged,
  });

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  late bool _saved;

  @override
  void initState() {
    super.initState();
    _saved = UserDataService.instance
        .isCourseSaved(widget.course['contentId'] as String? ?? '');
  }

  Future<void> _toggleSave() async {
    final contentId = widget.course['contentId'] as String? ?? '';
    if (_saved) {
      await UserDataService.instance.removeSavedCourse(contentId);
    } else {
      await UserDataService.instance.saveCourse(widget.course);
    }
    if (mounted) setState(() => _saved = !_saved);
    widget.onSaveChanged();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_saved ? '플래너에 저장됐어요!' : '플래너에서 삭제됐어요'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _goToDetail() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          course: widget.course,
          purposes: widget.purposes,
        ),
      ),
    ).then((_) {
      final contentId = widget.course['contentId'] as String? ?? '';
      if (mounted) {
        setState(() => _saved =
            UserDataService.instance.isCourseSaved(contentId));
      }
      widget.onSaveChanged();
    });
  }

  @override
  Widget build(BuildContext context) {
    final places = List<Map<String, dynamic>>.from(
        (widget.course['places'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map)));
    final distance = widget.course['distance'] as String? ?? '';
    final taketime = widget.course['taketime'] as String? ?? '';
    final region   = widget.course['region']   as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 카드 본문
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 지역
                if (region.isNotEmpty)
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 13, color: Color(0xFF2E7D6B)),
                      const SizedBox(width: 2),
                      Text(region,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D6B),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                if (region.isNotEmpty) const SizedBox(height: 6),

                // 코스명
                Text(
                  widget.course['title'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                // 거리 / 소요 시간
                if (distance.isNotEmpty || taketime.isNotEmpty)
                  Row(
                    children: [
                      if (distance.isNotEmpty) ...[
                        _InfoPill(
                            icon: Icons.straighten_outlined,
                            label: distance),
                        const SizedBox(width: 8),
                      ],
                      if (taketime.isNotEmpty)
                        _InfoPill(
                            icon: Icons.schedule_outlined,
                            label: taketime),
                    ],
                  ),
                if (distance.isNotEmpty || taketime.isNotEmpty)
                  const SizedBox(height: 12),

                // 장소 목록 (번호 + 이름)
                if (places.isNotEmpty) ...[
                  ...List.generate(
                    places.length.clamp(0, 4),
                    (i) => _PlaceRow(
                      index: i,
                      name: places[i]['subname'] as String? ?? '',
                      isLast: i == places.length.clamp(0, 4) - 1,
                    ),
                  ),
                  if (places.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(left: 32, top: 4),
                      child: Text(
                        '외 ${places.length - 4}곳',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  const SizedBox(height: 12),
                ] else ...[
                  // places 없으면 overview
                  if ((widget.course['overview'] as String? ?? '')
                      .isNotEmpty) ...[
                    Text(
                      widget.course['overview'] as String,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ],
            ),
          ),

          // 버튼 영역
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _goToDetail,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2E7D6B),
                      side: const BorderSide(color: Color(0xFF2E7D6B)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('이 코스로 여행 계획하기',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _toggleSave,
                  icon: Icon(
                    _saved ? Icons.bookmark : Icons.bookmark_add_outlined,
                    color: _saved
                        ? const Color(0xFF2E7D6B)
                        : Colors.grey[600],
                  ),
                  tooltip: _saved ? '플래너에서 삭제' : '플래너에 담기',
                  style: IconButton.styleFrom(
                    backgroundColor: _saved
                        ? const Color(0xFF2E7D6B).withValues(alpha: 0.1)
                        : Colors.grey.shade100,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 장소 행 (번호 원 + 연결선 + 이름) ────────────────────
class _PlaceRow extends StatelessWidget {
  final int index;
  final String name;
  final bool isLast;
  const _PlaceRow(
      {required this.index, required this.name, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D6B),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: const Color(0xFF2E7D6B).withValues(alpha: 0.25),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 10, top: 2),
              child: Text(
                name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF333333)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 정보 필 ──────────────────────────────────────────────
class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── 저장된 코스 BottomSheet ──────────────────────────────
class _SavedCoursesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> courses;
  final void Function(String contentId) onRemove;

  const _SavedCoursesSheet(
      {required this.courses, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, ctrl) => Column(
        children: [
          // 핸들
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Text('내 플래너',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('${courses.length}개',
                    style: TextStyle(
                        fontSize: 14, color: Colors.grey[600])),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: courses.isEmpty
                ? const Center(
                    child: Text('저장된 코스가 없어요',
                        style: TextStyle(color: Colors.grey)),
                  )
                : ListView.builder(
                    controller: ctrl,
                    itemCount: courses.length,
                    itemBuilder: (context, i) {
                      final c = courses[i];
                      return Dismissible(
                        key: ValueKey(c['contentId']),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red.shade400,
                          child:
                              const Icon(Icons.delete_outline, color: Colors.white),
                        ),
                        onDismissed: (_) =>
                            onRemove(c['contentId'] as String),
                        child: ListTile(
                          leading: const Icon(Icons.map_outlined,
                              color: Color(0xFF2E7D6B)),
                          title: Text(c['title'] as String? ?? '',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(c['region'] as String? ?? '',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.grey, size: 20),
                            onPressed: () =>
                                onRemove(c['contentId'] as String),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    CourseDetailScreen(course: c),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
