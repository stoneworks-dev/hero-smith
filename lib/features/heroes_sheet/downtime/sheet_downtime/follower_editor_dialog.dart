import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/downtime_tracking.dart';
import '../../../../core/text/heroes_sheet/downtime/follower_editor_dialog_text.dart';
import '../../../../core/theme/navigation_theme.dart';

/// Accent color for followers
const MaterialColor _followersColor = Colors.purple;

class FollowerEditorDialog extends StatefulWidget {
  const FollowerEditorDialog({
    super.key,
    required this.heroId,
    this.existingFollower,
  });

  final String heroId;
  final Follower? existingFollower;

  @override
  State<FollowerEditorDialog> createState() => _FollowerEditorDialogState();
}

class _FollowerEditorDialogState extends State<FollowerEditorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _typeController;
  late final TextEditingController _mightController;
  late final TextEditingController _agilityController;
  late final TextEditingController _reasonController;
  late final TextEditingController _intuitionController;
  late final TextEditingController _presenceController;
  late final TextEditingController _skillsController;
  late final TextEditingController _languagesController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final follower = widget.existingFollower;
    
    _nameController = TextEditingController(text: follower?.name ?? '');
    _typeController = TextEditingController(text: follower?.followerType ?? '');
    _mightController = TextEditingController(text: follower?.might.toString() ?? '0');
    _agilityController = TextEditingController(text: follower?.agility.toString() ?? '0');
    _reasonController = TextEditingController(text: follower?.reason.toString() ?? '0');
    _intuitionController = TextEditingController(text: follower?.intuition.toString() ?? '0');
    _presenceController = TextEditingController(text: follower?.presence.toString() ?? '0');
    _skillsController = TextEditingController(text: follower?.skills.join(', ') ?? '');
    _languagesController = TextEditingController(text: follower?.languages.join(', ') ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _typeController.dispose();
    _mightController.dispose();
    _agilityController.dispose();
    _reasonController.dispose();
    _intuitionController.dispose();
    _presenceController.dispose();
    _skillsController.dispose();
    _languagesController.dispose();
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
              color: _followersColor.withAlpha(40),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.existingFollower == null ? Icons.person_add : Icons.edit,
              color: _followersColor.shade300,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.existingFollower == null
                  ? FollowerEditorDialogText.titleAddFollower
                  : FollowerEditorDialogText.titleEditFollower,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: FollowerEditorDialogText.nameLabel,
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _followersColor.shade400)),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? FollowerEditorDialogText.nameRequiredError
                      : null,
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _typeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: FollowerEditorDialogText.followerTypeLabel,
                    hintText: FollowerEditorDialogText.followerTypeHint,
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _followersColor.shade400)),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? FollowerEditorDialogText.followerTypeRequiredError
                      : null,
                ),
                const SizedBox(height: 16),
                
                Text(
                  FollowerEditorDialogText.characteristicsLabel,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade300),
                ),
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildStatField(
                        FollowerEditorDialogText.statLabelM,
                        _mightController,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatField(
                        FollowerEditorDialogText.statLabelA,
                        _agilityController,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatField(
                        FollowerEditorDialogText.statLabelR,
                        _reasonController,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatField(
                        FollowerEditorDialogText.statLabelI,
                        _intuitionController,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildStatField(
                        FollowerEditorDialogText.statLabelP,
                        _presenceController,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                TextFormField(
                  controller: _skillsController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: FollowerEditorDialogText.skillsLabel,
                    hintText: FollowerEditorDialogText.skillsHint,
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _followersColor.shade400)),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                ),
                const SizedBox(height: 12),
                
                TextFormField(
                  controller: _languagesController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: FollowerEditorDialogText.languagesLabel,
                    hintText: FollowerEditorDialogText.languagesHint,
                    hintStyle: TextStyle(color: Colors.grey.shade600),
                    labelStyle: TextStyle(color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _followersColor.shade400)),
                    filled: true,
                    fillColor: Colors.grey.shade900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey.shade400),
          child: const Text(FollowerEditorDialogText.cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: _followersColor,
            foregroundColor: Colors.white,
          ),
          child: const Text(FollowerEditorDialogText.saveButtonLabel),
        ),
      ],
    );
  }

  Widget _buildStatField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade400),
        border: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade700)),
        focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: _followersColor.shade400)),
        filled: true,
        fillColor: Colors.grey.shade900,
        isDense: true,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^-?\d*')),
      ],
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final follower = widget.existingFollower?.copyWith(
      name: _nameController.text,
      followerType: _typeController.text,
      might: int.tryParse(_mightController.text) ?? 0,
      agility: int.tryParse(_agilityController.text) ?? 0,
      reason: int.tryParse(_reasonController.text) ?? 0,
      intuition: int.tryParse(_intuitionController.text) ?? 0,
      presence: int.tryParse(_presenceController.text) ?? 0,
      skills: _parseCommaSeparated(_skillsController.text),
      languages: _parseCommaSeparated(_languagesController.text),
    ) ?? Follower(
      id: '',
      heroId: widget.heroId,
      name: _nameController.text,
      followerType: _typeController.text,
      might: int.tryParse(_mightController.text) ?? 0,
      agility: int.tryParse(_agilityController.text) ?? 0,
      reason: int.tryParse(_reasonController.text) ?? 0,
      intuition: int.tryParse(_intuitionController.text) ?? 0,
      presence: int.tryParse(_presenceController.text) ?? 0,
      skills: _parseCommaSeparated(_skillsController.text),
      languages: _parseCommaSeparated(_languagesController.text),
    );

    Navigator.pop(context, follower);
  }

  List<String> _parseCommaSeparated(String text) {
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}
