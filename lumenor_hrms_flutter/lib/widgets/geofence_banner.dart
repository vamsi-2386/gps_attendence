import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'themed_text.dart';

/// Geofence Status Banner
///
/// Shows if user is inside or outside office geofence
class GeofenceBanner extends StatelessWidget {
  final bool isInsideGeofence;
  final String? officeName;
  final double distance; // in meters
  final VoidCallback? onDismiss;

  const GeofenceBanner({
    Key? key,
    required this.isInsideGeofence,
    this.officeName,
    this.distance = 0.0,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isInsideGeofence) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
          vertical: AppTheme.spacingSmall,
        ),
        color: AppTheme.successColor.withOpacity(0.1),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppTheme.successColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                BodySmallText(
                  'Inside ${officeName ?? "office"} geofence',
                  color: AppTheme.successColor,
                ),
              ],
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppTheme.successColor,
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingMedium,
        vertical: AppTheme.spacingSmall,
      ),
      color: AppTheme.errorColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.location_off,
                  color: AppTheme.errorColor,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BodySmallText(
                        'Outside ${officeName ?? "office"} geofence',
                        color: AppTheme.errorColor,
                      ),
                      if (distance > 0)
                        BodySmallText(
                          '${distance.toStringAsFixed(0)}m away',
                          color: AppTheme.errorColor,
                          fontSize: 10,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Icon(
                Icons.close,
                size: 18,
                color: AppTheme.errorColor,
              ),
            ),
        ],
      ),
    );
  }
}

/// Expandable Geofence Info Card
class GeofenceInfoCard extends StatefulWidget {
  final String officeName;
  final double distance; // in meters
  final bool isInsideGeofence;
  final double radius; // in meters
  final String? address;

  const GeofenceInfoCard({
    Key? key,
    required this.officeName,
    required this.distance,
    required this.isInsideGeofence,
    required this.radius,
    this.address,
  }) : super(key: key);

  @override
  State<GeofenceInfoCard> createState() => _GeofenceInfoCardState();
}

class _GeofenceInfoCardState extends State<GeofenceInfoCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isInsideGeofence
            ? AppTheme.successColor.withOpacity(0.05)
            : AppTheme.warningColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: widget.isInsideGeofence
              ? AppTheme.successColor.withOpacity(0.3)
              : AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeadingMediumText(
                          widget.officeName,
                          color: widget.isInsideGeofence
                              ? AppTheme.successColor
                              : AppTheme.warningColor,
                        ),
                        const SizedBox(height: AppTheme.spacingXSmall),
                        BodySmallText(
                          'Distance: ${widget.distance.toStringAsFixed(0)}m '
                          '(Radius: ${widget.radius.toStringAsFixed(0)}m)',
                          color: AppTheme.mediumGray,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: AppTheme.mediumGray,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppTheme.lightGray),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow(
                    icon: Icons.location_on,
                    label: 'Status',
                    value: widget.isInsideGeofence ? 'Inside' : 'Outside',
                    valueColor: widget.isInsideGeofence
                        ? AppTheme.successColor
                        : AppTheme.warningColor,
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  _infoRow(
                    icon: Icons.straighten,
                    label: 'Distance',
                    value: '${widget.distance.toStringAsFixed(2)}m',
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  _infoRow(
                    icon: Icons.adjust,
                    label: 'Geofence Radius',
                    value: '${widget.radius.toStringAsFixed(0)}m',
                  ),
                  if (widget.address != null) ...[
                    const SizedBox(height: AppTheme.spacingSmall),
                    _infoRow(
                      icon: Icons.location_city,
                      label: 'Address',
                      value: widget.address!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppTheme.mediumGray,
        ),
        const SizedBox(width: AppTheme.spacingSmall),
        Expanded(
          child: BodySmallText(
            label,
            color: AppTheme.mediumGray,
          ),
        ),
        BodySmallText(
          value,
          color: valueColor ?? AppTheme.darkGray,
          fontWeight: FontWeight.w600,
        ),
      ],
    );
  }
}
