import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/measurements_view_model.dart';
import '../../data/repositories/measurement_repository_impl.dart';
import '../../domain/entities/measurement.dart';
import 'add_measurement_screen.dart';
import '../../utils/auth_guard.dart'; // Import AuthGuard
import '../../l10n/app_localizations.dart';

class MeasurementsScreen extends StatelessWidget {
  final bool isTab;
  const MeasurementsScreen({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeasurementsViewModel(
        repository: MeasurementRepositoryImpl(), 
      )..loadMeasurements(),
      child: _MeasurementsView(isTab: isTab),
    );
  }
}

class _MeasurementsView extends StatelessWidget {
  final bool isTab;
  const _MeasurementsView({this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<MeasurementsViewModel>();
    final measurements = viewModel.measurements;
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: isTab ? null : AppBar(title: Text(loc.translate('measurements'))),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header (Type Selector)
            Container(
              padding: const EdgeInsets.all(16),
              color: colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: MeasurementType.values.map((type) {
                        final isSelected = viewModel.selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilterChip(
                            showCheckmark: false,
                            selected: isSelected,
                            label: Text(loc.translate(type.name)), 
                            onSelected: (bool selected) {
                              if (selected) {
                                viewModel.setType(type);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Graph (unchanged)
            if (measurements.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(
                  painter: _TrendGraphPainter(
                    measurements: measurements,
                    color: colorScheme.primary,
                  ),
                ),
              ),

            if (measurements.isEmpty && !viewModel.isLoading)
               Padding(
                 padding: const EdgeInsets.all(32.0),
                 child: Center(child: Text("${loc.translate('no_data_for')} ${loc.translate(viewModel.selectedType.name)}")),
               ),

            // 3. List
            Expanded(
              child: viewModel.isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                : RefreshIndicator(
                    onRefresh: () async {
                      viewModel.loadMeasurements();
                    },
                    child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: measurements.length,
                    itemBuilder: (context, index) {
                      final m = measurements[index];
                      // Use device locale for formatting
                      final locale = Localizations.localeOf(context).toString();
                      
                      String valueText;
                      if (m.type == MeasurementType.pressure && m.value2 != null) {
                        valueText = '${m.value?.toInt()}/${m.value2?.toInt()} ${m.unit}';
                      } else {
                        valueText = '${m.value?.toStringAsFixed(1) ?? "--"} ${m.unit}';
                      }

                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
                        margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                          onTap: () {
                             Navigator.push(
                               context,
                               MaterialPageRoute(
                                 builder: (_) => ChangeNotifierProvider.value(
                                   value: viewModel,
                                   child: AddMeasurementScreen(measurementToEdit: m),
                                 ),
                               ),
                             ).then((_) => viewModel.loadMeasurements()); 
                          },
                          leading: CircleAvatar(
                            backgroundColor: colorScheme.primaryContainer.withOpacity(0.5),
                            child: Icon(_getIconForType(m.type), color: colorScheme.primary, size: 20),
                          ),
                          title: Text(
                            valueText,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(DateFormat.yMMMd(locale).add_jm().format(m.date)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                            onPressed: () async {
                              AuthGuard.protect(context, () async {
                                 final confirm = await showDialog<bool>(
                                   context: context,
                                   builder: (ctx) => AlertDialog(
                                     title: Text(loc.translate('delete_confirm_title')),
                                     content: Text(loc.translate('delete_measurement_confirm')),
                                     actions: [
                                       TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.translate('no'))),
                                       TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(loc.translate('yes'))),
                                     ],
                                   ),
                                 );
                                 if (confirm == true && m.id != null) {
                                   await viewModel.deleteMeasurement(m.id!);
                                 }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AuthGuard.protect(context, () {
          Navigator.push(
            context,
            MaterialPageRoute(
               builder: (_) => ChangeNotifierProvider.value(
                 value: viewModel,
                 child: AddMeasurementScreen(initialType: viewModel.selectedType),
               ),
            ),
          ).then((_) => viewModel.loadMeasurements());
        }),
        label: Text(loc.translate('add_log')),
        icon: const Icon(Icons.add),
      ),
    );
  }

  IconData _getIconForType(MeasurementType type) {
    switch (type) {
      case MeasurementType.weight: return Icons.monitor_weight;
      case MeasurementType.sugar: return Icons.bloodtype;
      case MeasurementType.pressure: return Icons.favorite;
      case MeasurementType.pulse: return Icons.monitor_heart;
      case MeasurementType.temperature: return Icons.thermostat;
      default: return Icons.show_chart;
    }
  }
}

class _TrendGraphPainter extends CustomPainter {
  final List<Measurement> measurements;
  final Color color;

  _TrendGraphPainter({required this.measurements, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (measurements.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
      
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Second line paint (for Diastolic)
    final paint2 = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint2 = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    
    // 1. Sort by date
    final sorted = List<Measurement>.from(measurements);
    sorted.sort((a, b) => a.date.compareTo(b.date)); 

    // 2. Find Min/Max
    double minVal = double.infinity;
    double maxVal = double.negativeInfinity;
    
    for (var m in sorted) {
      if (m.value != null) {
        if (m.value! < minVal) minVal = m.value!;
        if (m.value! > maxVal) maxVal = m.value!;
      }
      if (m.value2 != null) {
        if (m.value2! < minVal) minVal = m.value2!;
        if (m.value2! > maxVal) maxVal = m.value2!;
      }
    }
    
    if (minVal == double.infinity) return;
    
    final range = maxVal - minVal;
    final bottomY = minVal - (range * 0.2); // 20% padding
    final topY = maxVal + (range * 0.2);
    final effectiveRange = (topY - bottomY) == 0 ? 1.0 : (topY - bottomY);

    final path = Path();
    final path2 = Path(); // For value2
    bool path2Started = false;

    final widthStep = size.width / (sorted.length > 1 ? sorted.length - 1 : 1);

    for (int i = 0; i < sorted.length; i++) {
       final m = sorted[i];
       if (m.value == null) continue;

       final x = i * widthStep;
       
       // Draw Value 1 (Systolic)
       final normalizedY = (m.value! - bottomY) / effectiveRange; 
       final y = size.height - (normalizedY * size.height);
       
       if (i == 0) path.moveTo(x, y);
       else path.lineTo(x, y);
       canvas.drawCircle(Offset(x, y), 4, dotPaint);

       // Draw Value 2 (Diastolic)
       if (m.value2 != null) {
           final normalizedY2 = (m.value2! - bottomY) / effectiveRange; 
           final y2 = size.height - (normalizedY2 * size.height);

           if (!path2Started) {
             path2.moveTo(x, y2);
             path2Started = true;
           } else {
             path2.lineTo(x, y2);
           }
           canvas.drawCircle(Offset(x, y2), 4, dotPaint2);
       }
    }
    
    canvas.drawPath(path, paint);
    if (path2Started) {
      canvas.drawPath(path2, paint2);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
