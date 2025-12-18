import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:goldfinch_crm/models/driver.dart';
import 'package:goldfinch_crm/state/providers.dart';
import 'package:goldfinch_crm/theme.dart';
import 'package:goldfinch_crm/ui/components/shad_button.dart';
import 'package:goldfinch_crm/ui/components/shad_text_field.dart';
import 'package:goldfinch_crm/ui/components/success_snackbar.dart';

class DriverModal extends ConsumerStatefulWidget {
  final Driver? existingDriver;

  const DriverModal({super.key, this.existingDriver});

  static Future<void> show(BuildContext context, {Driver? driver}) =>
      showDialog(
        context: context,
        useRootNavigator: true,
        builder: (context) => DriverModal(existingDriver: driver),
      );

  @override
  ConsumerState<DriverModal> createState() => _DriverModalState();
}

class _DriverModalState extends ConsumerState<DriverModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;
  late TextEditingController _emailController;
  late TextEditingController _vehicleController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingDriver;
    _nameController = TextEditingController(text: existing?.name ?? '');
    _codeController = TextEditingController(text: existing?.code ?? '');
    _emailController = TextEditingController(text: existing?.email ?? '');
    _vehicleController = TextEditingController(text: existing?.vehicleReg ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _emailController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.shad)),
    child: Container(
      width: 600,
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingDriver == null ? 'Add Driver' : 'Edit Driver',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 24),
            ShadTextField(
              label: 'Driver Name',
              controller: _nameController,
              validator: (v) => (v == null || v.isEmpty) ? 'Name required' : null,
            ),
            const SizedBox(height: 16),
            ShadTextField(
              label: 'Code',
              controller: _codeController,
              validator: (v) => (v == null || v.isEmpty) ? 'Code required' : null,
            ),
            const SizedBox(height: 16),
            ShadTextField(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.isEmpty) ? 'Email required' : null,
            ),
            const SizedBox(height: 16),
            ShadTextField(
              label: 'Vehicle Registration',
              controller: _vehicleController,
              validator: (v) => (v == null || v.isEmpty) ? 'Vehicle registration required' : null,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton(
                  label: 'Cancel',
                  onPressed: _saving ? null : () => Navigator.of(context).pop(),
                  variant: ShadButtonVariant.ghost,
                ),
                const SizedBox(width: 12),
                ShadButton(
                  label: _saving ? 'Saving...' : 'Save',
                  onPressed: _saving ? null : _handleSave,
                  variant: ShadButtonVariant.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    final now = DateTime.now();
    final driver = Driver(
      id: widget.existingDriver?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      code: _codeController.text.trim(),
      email: _emailController.text.trim(),
      vehicleReg: _vehicleController.text.trim(),
      ownerId: widget.existingDriver?.ownerId ?? '',
      createdAt: widget.existingDriver?.createdAt ?? now,
      updatedAt: now,
    );

    await ref.read(driversProvider.notifier).upsert(driver);

    if (mounted) {
      Navigator.of(context).pop();
      SuccessSnackbar.show(
        context,
        widget.existingDriver == null ? 'Driver created successfully' : 'Driver updated successfully',
      );
    }
  }
}
