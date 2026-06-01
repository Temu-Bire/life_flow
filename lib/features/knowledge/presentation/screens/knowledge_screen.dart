import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/design_system.dart';
import '../../domain/models/note_model.dart';
import '../viewmodels/knowledge_viewmodel.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../../../shared/widgets/premium_button.dart';

class KnowledgeScreen extends ConsumerStatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  ConsumerState<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends ConsumerState<KnowledgeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openNoteEditor(BuildContext context, [NoteModel? note]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NoteEditorBottomSheet(note: note),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(filteredNotesProvider);
    final tags = ref.watch(allNoteTagsProvider);
    final activeTag = ref.watch(noteTagFilterProvider);

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
                    Text("Second Brain", style: AppTextStyles.titleLarge),
                    const SizedBox(height: 4),
                    Text("Capture notes, study items, and link ideas", style: AppTextStyles.bodyMedium),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.secondary, size: 36),
                  onPressed: () => _openNoteEditor(context),
                  tooltip: "New Note",
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: AppDecorations.glassDecoration(borderRadius: 14),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  ref.read(noteSearchProvider.notifier).state = val;
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search Second Brain...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tag chips list
            if (tags.isNotEmpty) ...[
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => ref.read(noteTagFilterProvider.notifier).state = null,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: activeTag == null ? AppColors.secondary : Colors.white.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: activeTag == null ? AppColors.secondaryLight : Colors.white.withOpacity(0.05),
                          ),
                        ),
                        child: Text(
                          "All Notes",
                          style: TextStyle(
                            color: activeTag == null ? Colors.white : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    ...tags.map((tag) {
                      final isSelected = activeTag == tag;
                      return GestureDetector(
                        onTap: () => ref.read(noteTagFilterProvider.notifier).state = tag,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.secondary : Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? AppColors.secondaryLight : Colors.white.withOpacity(0.05),
                            ),
                          ),
                          child: Text(
                            "#$tag",
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 18),
            ],

            // Notes list
            Expanded(
              child: notes.isEmpty
                  ? EmptyStateView(
                      icon: Icons.bubble_chart,
                      title: "Vault is empty",
                      description: "Unleash your creativity. Use Wiki-links [[Title]] to connect your notes together.",
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return _buildNoteCard(context, note);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, NoteModel note) {
    return GestureDetector(
      onTap: () => _openNoteEditor(context, note),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => ref.read(noteListProvider.notifier).deleteNote(note.id),
                  child: const Icon(Icons.delete, color: AppColors.danger, size: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                note.content,
                style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.4),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),
            // Tags row representation
            if (note.tags.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: note.tags
                      .map((t) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "#$t",
                              style: const TextStyle(color: AppColors.secondaryLight, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ))
                      .toList(),
                ),
              )
            else
              Text(
                DateFormat('MMM d, y').format(note.lastModified),
                style: TextStyle(color: Colors.white24, fontSize: 9),
              ),
          ],
        ),
      ),
    );
  }
}

// Note creation/modification form sheet
class NoteEditorBottomSheet extends ConsumerStatefulWidget {
  final NoteModel? note;
  const NoteEditorBottomSheet({super.key, this.note});

  @override
  ConsumerState<NoteEditorBottomSheet> createState() => _NoteEditorBottomSheetState();
}

class _NoteEditorBottomSheetState extends ConsumerState<NoteEditorBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  final List<String> _tags = [];
  final _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!.title;
      _contentController.text = widget.note!.content;
      _tags.addAll(widget.note!.tags);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    if (_tagController.text.isNotEmpty) {
      setState(() {
        final t = _tagController.text.trim().replaceAll('#', '');
        if (t.isNotEmpty && !_tags.contains(t)) {
          _tags.add(t);
        }
        _tagController.clear();
      });
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final wikiLinks = ref.read(noteListProvider.notifier).parseWikiLinks(_contentController.text);

      if (widget.note == null) {
        ref.read(noteListProvider.notifier).addNote(
              title: _titleController.text,
              content: _contentController.text,
              tags: _tags,
              linkedNoteIds: wikiLinks,
            );
      } else {
        final updated = widget.note!.copyWith(
          title: _titleController.text,
          content: _contentController.text,
          tags: _tags,
          linkedNoteIds: wikiLinks,
        );
        ref.read(noteListProvider.notifier).updateNote(updated);
      }
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                widget.note == null ? "Capture Insight Note" : "Edit Brain Note",
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: 18),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "Title",
                  labelStyle: TextStyle(color: AppColors.textSecondary),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                ),
                validator: (val) => val == null || val.isEmpty ? "Title is required" : null,
              ),
              const SizedBox(height: 16),

              // Content with markdown & Wiki-link directions
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.5),
                decoration: const InputDecoration(
                  labelText: "Content (Markdown & Wiki-links [[Note Title]] supported)",
                  labelStyle: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.secondaryLight)),
                ),
              ),
              const SizedBox(height: 16),

              // Tags Creator
              Text("Knowledge Tags (${_tags.length})", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              if (_tags.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  children: _tags
                      .map((t) => Chip(
                            backgroundColor: Colors.white10,
                            label: Text("#$t", style: const TextStyle(color: AppColors.secondaryLight, fontSize: 11)),
                            onDeleted: () => setState(() => _tags.remove(t)),
                            deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.danger),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: "Add tag...",
                        hintStyle: TextStyle(color: AppColors.textMuted),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: AppColors.secondaryLight),
                    onPressed: _addTag,
                  ),
                ],
              ),
              const Divider(color: Colors.white10),
              const SizedBox(height: 20),

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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
                    child: const Text("Save Note", style: TextStyle(color: Colors.white)),
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
