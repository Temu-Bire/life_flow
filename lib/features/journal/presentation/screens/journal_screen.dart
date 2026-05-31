import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/models/journal_model.dart';
import '../viewmodels/journal_viewmodel.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';

class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _unlockedEntryIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEntrySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddJournalBottomSheet(),
    );
  }

  // Verification dialog when opening a locked journal log
  void _verifyAndOpenLockedEntry(JournalModel entry) {
    if (_unlockedEntryIds.contains(entry.id)) {
      _showViewEntryDialog(entry);
      return;
    }

    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: const [
            Icon(Icons.lock, color: AppColors.primaryLight, size: 20),
            SizedBox(width: 8),
            Text("Locked Entry", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "This journal entry is locked. Enter your 4-digit PIN to access.",
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                hintText: "PIN (Try 1234)",
                hintStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              if (pinController.text == "1234") {
                setState(() {
                  _unlockedEntryIds.add(entry.id);
                });
                Navigator.of(ctx).pop();
                _showViewEntryDialog(entry);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Incorrect PIN!"), backgroundColor: AppColors.danger),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Unlock", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showViewEntryDialog(JournalModel entry) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, y').format(entry.date),
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.title.isNotEmpty ? entry.title : "Untitled Entry",
                          style: AppTextStyles.titleMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text("Mood: ${_getMoodEmoji(entry.mood)} ${entry.mood}", style: AppTextStyles.caption),
                    if (entry.isLocked) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.lock, color: AppColors.primaryLight, size: 12),
                      const SizedBox(width: 4),
                      Text("Locked Log", style: AppTextStyles.caption.copyWith(color: AppColors.primaryLight)),
                    ],
                  ],
                ),
                if (entry.prompt.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Text(
                      "Prompt: ${entry.prompt}",
                      style: AppTextStyles.caption.copyWith(fontStyle: FontStyle.italic, color: AppColors.textSecondary),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  entry.content,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      ref.read(journalListProvider.notifier).deleteEntry(entry.id);
                      Navigator.of(ctx).pop();
                    },
                    icon: const Icon(Icons.delete, color: AppColors.danger, size: 16),
                    label: const Text("Delete Entry", style: TextStyle(color: AppColors.danger)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'Happy':
        return '😊';
      case 'Calm':
        return '😌';
      case 'Neutral':
        return '😐';
      case 'Sad':
        return '😢';
      case 'Angry':
        return '😡';
      case 'Stressed':
        return '🤯';
      default:
        return '😌';
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchedEntries = ref.watch(searchedJournalEntriesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "My Journal",
                      style: AppTextStyles.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Your digital, secure space to reflect",
                      style: AppTextStyles.bodyMedium,
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEntrySheet(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.edit_note, color: Colors.white, size: 18),
                  label: const Text("Write", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search Journals
            Container(
              decoration: AppDecorations.glassDecoration(borderRadius: 14),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(journalSearchQueryProvider.notifier).state = val;
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search entries, moods, prompts...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Timeline entries feed
            Expanded(
              child: searchedEntries.isEmpty
                  ? EmptyStateView(
                      icon: Icons.book_outlined,
                      title: "Your feed is empty",
                      description: "Daily self-reflection is the pathway to clarity. Start writing a journal entry today!",
                      actionText: "Write Log",
                      onActionTap: () => _showAddEntrySheet(context),
                    )
                  : ListView.builder(
                      itemCount: searchedEntries.length,
                      itemBuilder: (context, index) {
                        final entry = searchedEntries[index];
                        final isLocked = entry.isLocked && !_unlockedEntryIds.contains(entry.id);

                        return _buildTimelineCard(entry, isLocked);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Timeline Item Visual Container
  Widget _buildTimelineCard(JournalModel entry, bool isLocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left timeline circle line
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    _getMoodEmoji(entry.mood),
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 80,
                color: Colors.white.withOpacity(0.05),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Main Card contents
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (isLocked) {
                  _verifyAndOpenLockedEntry(entry);
                } else {
                  _showViewEntryDialog(entry);
                }
              },
              child: GlassCard(
                borderRadius: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMM d, h:mm a').format(entry.date),
                          style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold),
                        ),
                        if (entry.isLocked)
                          Icon(
                            isLocked ? Icons.lock : Icons.lock_open,
                            color: AppColors.primaryLight,
                            size: 16,
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isLocked ? "Secure Entry Locked" : (entry.title.isNotEmpty ? entry.title : "Untitled Entry"),
                      style: AppTextStyles.titleMedium.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isLocked
                          ? "Tap and enter your passcode to view secure reflections."
                          : entry.content,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isLocked && entry.prompt.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "Reflected on Daily Prompt",
                          style: AppTextStyles.caption.copyWith(fontSize: 9, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Add Journal Bottom Sheet Creator
class AddJournalBottomSheet extends ConsumerStatefulWidget {
  const AddJournalBottomSheet({super.key});

  @override
  ConsumerState<AddJournalBottomSheet> createState() => _AddJournalBottomSheetState();
}

class _AddJournalBottomSheetState extends ConsumerState<AddJournalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  String _selectedMood = "Calm";
  bool _isLocked = false;
  String _activePrompt = "";

  @override
  void initState() {
    super.initState();
    // Fetch a random reflection prompt for the editor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _activePrompt = ref.read(journalListProvider.notifier).getRandomPrompt();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(journalListProvider.notifier).addEntry(
            title: _titleController.text,
            content: _contentController.text,
            mood: _selectedMood,
            isLocked: _isLocked,
            prompt: _activePrompt,
          );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final moods = ['Happy', 'Calm', 'Neutral', 'Sad', 'Angry', 'Stressed'];
    final moodEmojis = ['😊', '😌', '😐', '😢', '😡', '🤯'];

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Write Journal Log", style: AppTextStyles.titleMedium),
                  Row(
                    children: [
                      // Lock Log Toggle
                      IconButton(
                        icon: Icon(
                          _isLocked ? Icons.lock : Icons.lock_open_outlined,
                          color: _isLocked ? AppColors.primaryLight : AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _isLocked = !_isLocked;
                          });
                        },
                        tooltip: "Secure Lock Entry",
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reflection prompt suggestion banner
              if (_activePrompt.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Daily Reflection Prompt", style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _activePrompt = ref.read(journalListProvider.notifier).getRandomPrompt();
                              });
                            },
                            child: const Icon(Icons.refresh, size: 14, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _activePrompt,
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mood selector
              Text(
                "How are you feeling?",
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(moods.length, (index) {
                    final mood = moods[index];
                    final emoji = moodEmojis[index];
                    final isSelected = _selectedMood == mood;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedMood = mood;
                        });
                      },
                      child: AnimatedContainer(
                        duration: AppTransitions.fast,
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryLight.withOpacity(0.4) : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 6),
                            Text(
                              mood,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),

              // Title input
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Entry Title (e.g. A peaceful morning)",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.primaryLight)),
                ),
              ),
              const SizedBox(height: 16),

              // Minimalist editor body input
              TextFormField(
                controller: _contentController,
                maxLines: 6,
                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                decoration: InputDecoration(
                  hintText: "Start typing your thoughts, memories, reflections...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  border: InputBorder.none,
                ),
                validator: (val) => val == null || val.isEmpty ? "Please write some thoughts before saving!" : null,
              ),
              const SizedBox(height: 24),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    child: const Text("Save Log", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
