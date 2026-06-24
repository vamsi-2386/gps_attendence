import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/app_session.dart';
import '../../services/hrms_repository.dart';
import '../../widgets/themed_text.dart';
import '../../widgets/themed_button.dart';

/// Apply Leave Screen
///
/// Shows the remaining leave balance, a leave-type dropdown, start/end date
/// pickers (showDatePicker), an auto-computed working-day count (weekends
/// excluded), a reason field, and a Submit button that fires a success
/// SnackBar and pops back to the previous screen.
class ApplyLeaveScreen extends StatefulWidget {
  final String employeeName;
  final int totalLeaveDays;
  final int usedLeaveDays;

  const ApplyLeaveScreen({
    super.key,
    this.employeeName = 'Priya Sharma',
    this.totalLeaveDays = 20,
    this.usedLeaveDays = 6,
  });

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  static const List<String> _leaveTypes = ['Casual', 'Sick', 'Earned'];

  String _leaveType = 'Casual';
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();
  bool _isSubmitting = false;

  int get _remainingDays => widget.totalLeaveDays - widget.usedLeaveDays;

  /// Inclusive working-day count between start and end, skipping Sat/Sun.
  int get _workingDays {
    if (_startDate == null || _endDate == null) return 0;
    if (_endDate!.isBefore(_startDate!)) return 0;
    var count = 0;
    var cursor = _startDate!;
    while (!cursor.isAfter(_endDate!)) {
      if (cursor.weekday != DateTime.saturday &&
          cursor.weekday != DateTime.sunday) {
        count++;
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return count;
  }

  bool get _canSubmit =>
      _startDate != null &&
      _endDate != null &&
      _workingDays > 0 &&
      _reasonController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      builder: (context, child) {
        // Force the dark color scheme onto the picker dialog.
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.white,
              surface: AppTheme.darkElements,
              onSurface: AppTheme.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppTheme.darkElements,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        // Keep the range valid.
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = picked;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Select date';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// ISO 'yyyy-MM-dd' for the DB (start_date / end_date columns).
  String _isoDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) return;
    setState(() => _isSubmitting = true);
    final days = _workingDays;
    try {
      await HrmsRepository.instance.applyLeave(
        employeeId: AppSession.instance.employeeId,
        companyId: AppSession.instance.companyId,
        startDate: _isoDate(_startDate!),
        endDate: _isoDate(_endDate!),
        reason: _reasonController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.successColor,
          content: Text(
            'Leave request submitted ($days working day'
            '${days == 1 ? '' : 's'})',
            style: const TextStyle(color: AppTheme.white),
          ),
        ),
      );
      Navigator.pop(context);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppTheme.errorColor,
          content: Text(
            'Could not submit leave request. Please try again.',
            style: TextStyle(color: AppTheme.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const HeadingMediumText('Apply Leave'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        children: [
          _buildBalanceCard(),
          const SizedBox(height: AppTheme.spacingLarge),
          const LabelText('Leave Type'),
          const SizedBox(height: AppTheme.spacingSmall),
          _buildTypeDropdown(),
          const SizedBox(height: AppTheme.spacingLarge),
          const LabelText('Duration'),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Start',
                  value: _formatDate(_startDate),
                  onTap: () => _pickDate(isStart: true),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _buildDateField(
                  label: 'End',
                  value: _formatDate(_endDate),
                  onTap: () => _pickDate(isStart: false),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          _buildWorkingDaysBanner(),
          const SizedBox(height: AppTheme.spacingLarge),
          const LabelText('Reason'),
          const SizedBox(height: AppTheme.spacingSmall),
          _buildReasonField(),
          const SizedBox(height: AppTheme.spacingXLarge),
          ThemedButton(
            label: 'Submit Request',
            icon: Icons.send,
            isEnabled: _canSubmit,
            isLoading: _isSubmitting,
            onPressed: () {
              if (_canSubmit) _submit();
            },
          ),
          const SizedBox(height: AppTheme.spacingMedium),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    // Live remaining balance; fall back to the mock count while loading or on
    // error so the card never renders blank.
    return FutureBuilder<int>(
      future: HrmsRepository.instance.leaveBalance(
        AppSession.instance.employeeId,
      ),
      builder: (context, snap) {
        final remaining = (snap.connectionState == ConnectionState.done &&
                !snap.hasError &&
                snap.data != null)
            ? snap.data!
            : _remainingDays;
        return _buildBalanceCardBody(remaining);
      },
    );
  }

  Widget _buildBalanceCardBody(int remaining) {
    final fraction = widget.totalLeaveDays == 0
        ? 0.0
        : remaining / widget.totalLeaveDays;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppTheme.borders, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.event_available,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              const BodyMediumText('Leave Balance'),
              const Spacer(),
              HeadingLargeText(
                '$remaining',
                color: AppTheme.successColor,
              ),
              BodyMediumText(
                ' / ${widget.totalLeaveDays}',
                color: AppTheme.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppTheme.darkBackground,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.successColor),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          BodySmallText(
            '$remaining of ${widget.totalLeaveDays} days remaining',
            color: AppTheme.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.darkElements,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppTheme.borders),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _leaveType,
          isExpanded: true,
          dropdownColor: AppTheme.darkElements,
          iconEnabledColor: AppTheme.textPrimary,
          style: AppTheme.bodyLarge,
          items: _leaveTypes
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type,
                  child: BodyLargeText('$type Leave'),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _leaveType = value);
          },
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    final hasValue = value != 'Select date';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        decoration: BoxDecoration(
          color: AppTheme.darkElements,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(color: AppTheme.borders),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BodySmallText(label, color: AppTheme.textSecondary),
            const SizedBox(height: AppTheme.spacingXSmall),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: BodyMediumText(
                    value,
                    color: hasValue
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkingDaysBanner() {
    final days = _workingDays;
    final hasRange = _startDate != null && _endDate != null;
    final exceedsBalance = days > _remainingDays;
    final color = !hasRange
        ? AppTheme.textSecondary
        : exceedsBalance
            ? AppTheme.errorColor
            : AppTheme.infoColor;
    final text = !hasRange
        ? 'Pick a start and end date'
        : exceedsBalance
            ? '$days working days exceeds your balance'
            : '$days working day${days == 1 ? '' : 's'} (weekends excluded)';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(
            exceedsBalance ? Icons.warning_amber : Icons.schedule,
            color: color,
            size: 18,
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          Expanded(child: BodyMediumText(text, color: color)),
        ],
      ),
    );
  }

  Widget _buildReasonField() {
    return TextField(
      controller: _reasonController,
      maxLines: 4,
      style: AppTheme.bodyLarge,
      cursorColor: AppTheme.primaryColor,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'Briefly describe the reason for your leave...',
        hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
        filled: true,
        fillColor: AppTheme.darkElements,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.borders),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.borders),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
        ),
      ),
    );
  }
}
