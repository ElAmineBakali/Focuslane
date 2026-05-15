import 'package:flutter/material.dart';
import 'package:focuslane/screens/study/models/study_models.dart';

class InteractiveScheduleGrid extends StatefulWidget {
  final List<StudyClassBlock> blocks;
  final Map<String, Course> courseById;
  final ValueChanged<StudyClassBlock>? onBlockTap;
  final ValueChanged<StudyClassBlock>? onBlockLongPress;

  const InteractiveScheduleGrid({
    super.key,
    required this.blocks,
    required this.courseById,
    this.onBlockTap,
    this.onBlockLongPress,
  });

  @override
  State<InteractiveScheduleGrid> createState() =>
      _InteractiveScheduleGridState();
}

class _InteractiveScheduleGridState extends State<InteractiveScheduleGrid> {
  double _scale = 1.0;
  late TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    const hours = [
      '8:00',
      '9:00',
      '10:00',
      '11:00',
      '12:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00',
      '18:00',
      '19:00',
      '20:00',
      '21:00',
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.zoom_out),
                onPressed: () {
                  setState(() => _scale = (_scale - 0.1).clamp(0.5, 2.0));
                },
              ),
              Expanded(
                child: Slider(
                  value: _scale,
                  min: 0.5,
                  max: 2.0,
                  onChanged: (v) => setState(() => _scale = v),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.zoom_in),
                onPressed: () {
                  setState(() => _scale = (_scale + 0.1).clamp(0.5, 2.0));
                },
              ),
              Text(
                '${(_scale * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),

        Expanded(
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 2.0,
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _ScheduleTable(
                  blocks: widget.blocks,
                  courseById: widget.courseById,
                  days: days,
                  hours: hours,
                  onBlockTap: widget.onBlockTap,
                  onBlockLongPress: widget.onBlockLongPress,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScheduleTable extends StatelessWidget {
  final List<StudyClassBlock> blocks;
  final Map<String, Course> courseById;
  final List<String> days;
  final List<String> hours;
  final ValueChanged<StudyClassBlock>? onBlockTap;
  final ValueChanged<StudyClassBlock>? onBlockLongPress;

  const _ScheduleTable({
    required this.blocks,
    required this.courseById,
    required this.days,
    required this.hours,
    this.onBlockTap,
    this.onBlockLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(
        color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
      ),
      columnWidths: <int, TableColumnWidth>{
        0: const FixedColumnWidth(60),
        for (int i = 1; i <= 7; i++) i: const FixedColumnWidth(100),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          children: [
            const SizedBox(),
            ...days.map(
              (d) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    d,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        ...hours.asMap().entries.map((entry) {
          final hour = entry.value;
          final hourInt = int.parse(hour.split(':')[0]);
          return TableRow(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    hour,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              ...List.generate(7, (dowIdx) {
                final dow = dowIdx + 1;
                final blocksHere =
                    blocks
                        .where(
                          (b) =>
                              b.daysOfWeek.contains(dow) &&
                              b.start.hour == hourInt,
                        )
                        .toList();

                return GestureDetector(
                  onTap: () {
                    if (blocksHere.isNotEmpty && onBlockTap != null) {
                      onBlockTap!(blocksHere.first);
                    }
                  },
                  onLongPress: () {
                    if (blocksHere.isNotEmpty && onBlockLongPress != null) {
                      onBlockLongPress!(blocksHere.first);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children:
                          blocksHere.map((b) {
                            final course = courseById[b.courseId];
                            final color =
                                course?.color ??
                                Theme.of(context).colorScheme.primary;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 2),
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                border: Border(
                                  left: BorderSide(color: color, width: 3),
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    (course?.name ?? 'N/A').length > 15
                                        ? '${(course?.name ?? 'N/A').substring(0, 15)}...'
                                        : (course?.name ?? 'N/A'),
                                    style:
                                        Theme.of(context).textTheme.labelSmall,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (b.room != null)
                                    Text(
                                      b.room!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(fontSize: 10),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}
