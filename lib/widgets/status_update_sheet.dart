import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/incident.dart';
import '../providers/auth_provider.dart';
import '../providers/incident_provider.dart';
import '../utils/incident_styles.dart';
import 'app_text_field.dart';
import 'primary_button.dart';

class StatusUpdateSheet extends StatefulWidget {
  final Incident incident;
  const StatusUpdateSheet({super.key, required this.incident});

  @override
  State<StatusUpdateSheet> createState() => _StatusUpdateSheetState();
}

class _StatusUpdateSheetState extends State<StatusUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _status;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _status = widget.incident.status;
    _noteController = TextEditingController(text: widget.incident.staffNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final staff = context.read<AuthProvider>().profile;
    if (staff == null) return;

    final success = await context.read<IncidentProvider>().updateStatus(
          incidentId: widget.incident.id,
          status: _status,
          note: _noteController.text,
          staff: staff,
        );
    if (!mounted) return;
    Navigator.pop(context, success);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context.watch<IncidentProvider>().isSubmitting;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Update status', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: IncidentStatus.all.map((status) {
                return ChoiceChip(
                  avatar: Icon(StatusStyle.icon(status), size: 18, color: StatusStyle.color(status)),
                  label: Text(IncidentStatus.label(status)),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _noteController,
              label: 'Note for the student (optional)',
              icon: Icons.notes,
              maxLines: 3,
              // A rejected report must explain why: fair to the student
              validator: (value) {
                final empty = value == null || value.trim().isEmpty;
                if (_status == IncidentStatus.rejected && empty) {
                  return 'Please explain why this report is rejected';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Save', onPressed: _save, isLoading: isSaving),
          ],
        ),
      ),
    );
  }
}