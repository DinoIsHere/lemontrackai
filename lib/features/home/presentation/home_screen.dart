import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/date_utils.dart';
import '../../../features/chat/presentation/chat_controller.dart';
import '../../../features/schedule/presentation/widgets/event_editor_sheet.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/user_provider.dart';
import '../../../shared/widgets/chat_input_bar.dart';
import '../../../shared/widgets/lemon_drawer.dart';
import 'widgets/aurora_effect.dart';
import 'widgets/schedule_widget.dart';
import 'widgets/suggestion_chips.dart';
import 'widgets/welcome_header.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _selectedDay;
  List<dynamic> _events = const [];
  Set<DateTime> _busyDays = {};
  bool _loading = false;
  final TextEditingController _controller = TextEditingController();

  late AnimationController _introController;
  late Animation<double> _logoMoveAnimation;
  late Animation<double> _textMoveAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = DateTime(now.year, now.month, now.day);
    _load();

    _introController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _logoMoveAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );

    _textMoveAnimation = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _introController.forward();
      }
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = ref.read(scheduleRepositoryProvider);
    final events = await repo.getEventsForDay(_selectedDay);
    final rangeStart = startOfWeek(DateTime.now());
    final rangeEnd = rangeStart.add(const Duration(days: 7));
    final weekEvents = await repo.getEventsForRange(rangeStart, rangeEnd);
    if (!mounted) return;
    setState(() {
      _events = events;
      _busyDays = weekEvents.map((e) => DateTime(e.start.year, e.start.month, e.start.day)).toSet();
      _loading = false;
    });
  }

  Future<void> _onSelect(DateTime day) async {
    setState(() => _selectedDay = DateTime(day.year, day.month, day.day));
    final repo = ref.read(scheduleRepositoryProvider);
    final events = await repo.getEventsForDay(_selectedDay);
    if (!mounted) return;
    setState(() => _events = events);
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final chatRepo = ref.read(chatRepositoryProvider);
    final thread = await chatRepo.createThread(title: null);
    await chatRepo.sendMessage(thread.id, text);
    ref.invalidate(threadsProvider);
    if (!mounted) return;
    Navigator.of(context).pushNamed('/chat', arguments: thread.id);
  }

  void _addEvent() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EventEditorSheet(
        initialStart: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, DateTime.now().hour + 1),
        initialEnd: DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, DateTime.now().hour + 2),
      ),
    ).then((_) => _load());
  }

  @override
  void dispose() {
    _controller.dispose();
    _introController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(userNameProvider);
    final theme = Theme.of(context);
    final greeting = greetingForHour(DateTime.now().hour);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      drawer: const LemonDrawer(),
      appBar: AppBar(
        title: const Text('Lemon Track'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedBuilder(
                              animation: _introController,
                              builder: (context, child) {
                                final t = _logoMoveAnimation.value;
                                return Opacity(
                                  opacity: 1 - t * 0.3,
                                  child: Transform.translate(
                                    offset: Offset(0, 200 * (1 - t)),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          const SizedBox(height: 32),
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme.surfaceContainerHighest,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.auto_awesome,
                                              color: theme.colorScheme.onSurface,
                                              size: 36,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '$greeting, $name',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'How can I help you today?',
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 24),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_loading)
                                    const Center(
                                        child: CircularProgressIndicator())
                                  else
                                    ScheduleWidget(
                                      selectedDay: _selectedDay,
                                      events: _events.cast(),
                                      busyDays: _busyDays,
                                      onSelect: _onSelect,
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: TextButton.icon(
                                        onPressed: _addEvent,
                                        icon: const Icon(Icons.add),
                                        label: const Text('Add event'),
                                      ),
                                    ),
                                  const SizedBox(height: 16),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: SuggestionChips(
                                      onTap: (label) {
                                        _controller.text = label;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom: -80,
                    left: -MediaQuery.of(context).size.width * 0.25,
                    right: -MediaQuery.of(context).size.width * 0.25,
                    child: SizedBox(
                      height: 200,
                      child: const AuroraEffect(),
                    ),
                  ),
                  ChatInputBar(controller: _controller, onSend: _send),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
