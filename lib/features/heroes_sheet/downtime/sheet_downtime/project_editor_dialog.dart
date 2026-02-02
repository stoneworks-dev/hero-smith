import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/downtime_tracking.dart';
import '../../../../core/theme/navigation_theme.dart';
import '../../../../core/text/heroes_sheet/downtime/project_editor_dialog_text.dart';

/// Accent color for projects
const Color _projectsColor = NavigationTheme.projectsTabColor;

/// Dialog for creating or editing a downtime project
class ProjectEditorDialog extends StatefulWidget {
  const ProjectEditorDialog({
    super.key,
    required this.heroId,
    this.existingProject,
  });

  final String heroId;
  final HeroDowntimeProject? existingProject;

  @override
  State<ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<ProjectEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _goalController;
  late final TextEditingController _currentPointsController;
  late final TextEditingController _prerequisitesController;
  late final TextEditingController _sourceController;
  late final TextEditingController _sourceLanguageController;
  late final TextEditingController _guidesController;
  late final TextEditingController _characteristicsController;
  late final TextEditingController _notesController;
  late List<ProjectEvent> _events;
  
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final project = widget.existingProject;
    
    _nameController = TextEditingController(text: project?.name ?? '');
    _descriptionController = TextEditingController(text: project?.description ?? '');
    _goalController = TextEditingController(text: project?.projectGoal.toString() ?? '');
    _currentPointsController = TextEditingController(
      text: project?.currentPoints.toString() ?? '0',
    );
    _prerequisitesController = TextEditingController(
      text: project?.prerequisites.join(', ') ?? '',
    );
    _sourceController = TextEditingController(text: project?.projectSource ?? '');
    _sourceLanguageController = TextEditingController(text: project?.sourceLanguage ?? '');
    _guidesController = TextEditingController(text: project?.guides.join(', ') ?? '');
    _characteristicsController = TextEditingController(
      text: project?.rollCharacteristics.join(', ') ?? '',
    );
    _notesController = TextEditingController(text: project?.notes ?? '');
    _events = List<ProjectEvent>.from(project?.events ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _goalController.dispose();
    _currentPointsController.dispose();
    _prerequisitesController.dispose();
    _sourceController.dispose();
    _sourceLanguageController.dispose();
    _guidesController.dispose();
    _characteristicsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: NavigationTheme.cardBackgroundDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade800),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _projectsColor.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.existingProject == null ? Icons.add_task : Icons.edit,
              color: _projectsColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            widget.existingProject == null
                ? ProjectEditorDialogText.titleCreateProject
                : ProjectEditorDialogText.titleEditProject,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: ProjectEditorDialogText.nameLabel,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return ProjectEditorDialogText.nameRequiredError;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: ProjectEditorDialogText.descriptionLabel,
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: ProjectEditorDialogText.goalLabel,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return ProjectEditorDialogText.goalRequiredError;
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return ProjectEditorDialogText.goalValidNumberError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              if (widget.existingProject != null) ...[
                TextFormField(
                  controller: _currentPointsController,
                  decoration: const InputDecoration(
                    labelText: ProjectEditorDialogText.currentPointsLabel,
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 16),
              ],
              
              TextFormField(
                controller: _prerequisitesController,
                decoration: const InputDecoration(
                  labelText: ProjectEditorDialogText.prerequisitesLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _sourceController,
                decoration: const InputDecoration(
                  labelText: ProjectEditorDialogText.sourceLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _sourceLanguageController,
                decoration: const InputDecoration(
                  labelText: ProjectEditorDialogText.sourceLanguageLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _guidesController,
                decoration: const InputDecoration(
                  labelText: ProjectEditorDialogText.guidesLabel,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _characteristicsController,
                decoration: const InputDecoration(
                  labelText: ProjectEditorDialogText.rollCharacteristicsLabel,
                  hintText: ProjectEditorDialogText.rollCharacteristicsHint,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              // Events Section
              if (widget.existingProject != null && _events.isNotEmpty) ...[
                Text(
                  ProjectEditorDialogText.eventMilestonesLabel,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: NavigationTheme.navBarBackground,
                    border: Border.all(color: Colors.grey.shade700),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: _events.asMap().entries.map((entry) {
                      final index = entry.key;
                      final event = entry.value;
                      return _EventEditorTile(
                        event: event,
                        onDescriptionChanged: (description) {
                          setState(() {
                            _events[index] = event.copyWith(eventDescription: description);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Notes Section
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: ProjectEditorDialogText.notesLabel,
                  hintText: ProjectEditorDialogText.notesHint,
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey.shade400,
          ),
          child: const Text(ProjectEditorDialogText.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _saveProject,
          style: FilledButton.styleFrom(
            backgroundColor: _projectsColor,
            foregroundColor: Colors.white,
          ),
          child: const Text(ProjectEditorDialogText.saveButtonLabel),
        ),
      ],
    );
  }

  void _saveProject() {
    if (!_formKey.currentState!.validate()) return;

    final project = widget.existingProject?.copyWith(
      name: _nameController.text,
      description: _descriptionController.text,
      projectGoal: int.parse(_goalController.text),
      currentPoints: int.parse(_currentPointsController.text),
      prerequisites: _parseCommaSeparated(_prerequisitesController.text),
      projectSource: _sourceController.text.isEmpty ? null : _sourceController.text,
      sourceLanguage: _sourceLanguageController.text.isEmpty 
          ? null 
          : _sourceLanguageController.text,
      guides: _parseCommaSeparated(_guidesController.text),
      rollCharacteristics: _parseCommaSeparated(_characteristicsController.text),
      events: _events,
      notes: _notesController.text,
      updatedAt: DateTime.now(),
    ) ?? HeroDowntimeProject(
      id: '',
      heroId: widget.heroId,
      name: _nameController.text,
      description: _descriptionController.text,
      projectGoal: int.parse(_goalController.text),
      currentPoints: 0,
      prerequisites: _parseCommaSeparated(_prerequisitesController.text),
      projectSource: _sourceController.text.isEmpty ? null : _sourceController.text,
      sourceLanguage: _sourceLanguageController.text.isEmpty 
          ? null 
          : _sourceLanguageController.text,
      guides: _parseCommaSeparated(_guidesController.text),
      rollCharacteristics: _parseCommaSeparated(_characteristicsController.text),
      events: HeroDowntimeProject.calculateEventThresholds(
        int.parse(_goalController.text),
      ),
      notes: _notesController.text,
      isCustom: true,
      isCompleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(project);
  }

  List<String> _parseCommaSeparated(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

/// Widget for editing a single event's description
class _EventEditorTile extends StatelessWidget {
  const _EventEditorTile({
    required this.event,
    required this.onDescriptionChanged,
  });

  final ProjectEvent event;
  final ValueChanged<String> onDescriptionChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade700,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                event.triggered ? Icons.check_circle : Icons.circle_outlined,
                size: 18,
                color: event.triggered ? Colors.amber : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                'Event at ${event.pointThreshold} points',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: event.triggered ? Colors.amber.shade600 : Colors.grey.shade400,
                ),
              ),
              if (event.triggered) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    ProjectEditorDialogText.eventTriggeredLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.amber.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            initialValue: event.eventDescription ?? '',
            style: TextStyle(color: Colors.grey.shade300, fontSize: 13),
            decoration: InputDecoration(
              hintText: ProjectEditorDialogText.eventNotesHint,
              hintStyle: TextStyle(color: Colors.grey.shade600),
              isDense: true,
              filled: true,
              fillColor: NavigationTheme.cardBackgroundDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Colors.grey.shade700),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: _projectsColor),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
            maxLines: 2,
            onChanged: onDescriptionChanged,
          ),
        ],
      ),
    );
  }
}
