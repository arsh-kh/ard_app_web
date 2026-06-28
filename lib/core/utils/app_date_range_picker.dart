import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'app_translations.dart';

/// Opens a custom, intuitive Date Range Picker dialog.
/// It uses standard DatePickers for Start and End dates separately,
/// avoiding the confusing native Range Picker UI.
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  required String langCode,
  DateTimeRange? initialDateRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  return showDialog<DateTimeRange>(
    context: context,
    builder: (ctx) => _CustomDateRangeDialog(
      langCode: langCode,
      initialDateRange: initialDateRange,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2050),
    ),
  );
}

class _CustomDateRangeDialog extends StatefulWidget {
  final String langCode;
  final DateTimeRange? initialDateRange;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomDateRangeDialog({
    required this.langCode,
    this.initialDateRange,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomDateRangeDialog> createState() => _CustomDateRangeDialogState();
}

class _CustomDateRangeDialogState extends State<_CustomDateRangeDialog> {
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _start = widget.initialDateRange?.start;
    _end = widget.initialDateRange?.end;
  }

  String t(String key) => Tr.t(key, widget.langCode);

  static const kuMonths = [
    'مانگی یەک',
    'مانگی دوو',
    'مانگی سێ',
    'مانگی چوار',
    'مانگی پێنج',
    'مانگی شەش',
    'مانگی حەوت',
    'مانگی هەشت',
    'مانگی نۆ',
    'مانگی دە',
    'مانگی یانزە',
    'مانگی دوانزە',
  ];
  static const arMonths = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  static const enMonths = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String _getMonthName(int month) {
    if (widget.langCode == 'ku') return kuMonths[month - 1];
    if (widget.langCode == 'ar') return arMonths[month - 1];
    return enMonths[month - 1];
  }

  Future<int?> _showGridPicker(
    BuildContext context,
    List<String> items,
    int selectedIndex,
    String title,
  ) {
    // Perfectly calculate the exact scroll position before rendering to avoid frame lag
    final double viewportHeight = MediaQuery.of(context).size.height * 0.5;
    final int totalRows = (items.length / 3).ceil();
    final double contentHeight =
        totalRows * 60.0 - 12.0; // 48 height + 12 spacing

    double initialOffset = 0.0;
    if (contentHeight > viewportHeight) {
      final double maxScroll = contentHeight - viewportHeight;
      final int targetRow = selectedIndex ~/ 3;
      double offset = targetRow * 60.0;
      offset -=
          (viewportHeight / 2) - 30; // Center it vertically in the viewport
      initialOffset = offset.clamp(0.0, maxScroll);
    }

    final ScrollController scrollController = ScrollController(
      initialScrollOffset: initialOffset,
    );

    return showDialog<int>(
      context: context,
      builder: (c) {
        final theme = Theme.of(c);
        final baseColor = theme.brightness == Brightness.dark
            ? Colors.white
            : Colors.black;
        final onBase = theme.brightness == Brightness.dark
            ? Colors.black
            : Colors.white;

        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: baseColor,
                  ),
                ),
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(c).size.height * 0.5,
                  ),
                  child: Directionality(
                    textDirection: RegExp(r'^[0-9]+$').hasMatch(items.first)
                        ? TextDirection.ltr
                        : Directionality.of(c),
                    child: GridView.builder(
                      controller: scrollController,
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisExtent:
                                48, // Fixed height for precise scrolling math
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                          ),
                      itemCount: items.length,
                      itemBuilder: (ctx, i) {
                        final isSelected = i == selectedIndex;
                        return InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.pop(c, i),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? baseColor
                                  : theme.colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              items[i],
                              style: TextStyle(
                                color: isSelected ? onBase : baseColor,
                                fontWeight: isSelected
                                    ? FontWeight.w900
                                    : FontWeight.w600,
                                fontSize: 16,
                              ),
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
        );
      },
    );
  }

  Future<void> _pickDate(bool isStart) async {
    final initial = isStart
        ? (_start ?? DateTime.now())
        : (_end ?? _start ?? DateTime.now());

    final initialClamped = initial.isBefore(widget.firstDate)
        ? widget.firstDate
        : (initial.isAfter(widget.lastDate) ? widget.lastDate : initial);

    final first = isStart ? widget.firstDate : (_start ?? widget.firstDate);

    final picked = await showDialog<DateTime>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        final baseColor = isDark ? Colors.white : Colors.black;
        final onBase = isDark ? Colors.black : Colors.white;

        DateTime tempSelectedDate = initialClamped;
        int displayedMonth = tempSelectedDate.month;
        int displayedYear = tempSelectedDate.year;
        Key calendarKey = UniqueKey();

        return Dialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: StatefulBuilder(
            builder: (ctx, setState) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isStart
                          ? t('dpStartDate').toUpperCase()
                          : t('dpEndDate').toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: baseColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FOOLPROOF YEAR & MONTH STEPPERS (WITH GRID PICKER)
                    // FOOLPROOF YEAR & MONTH STEPPERS (WITH GRID PICKER)
                    Column(
                      children: [
                        // Year Stepper (Top)
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_double_arrow_right,
                                ),
                                onPressed: () {
                                  setState(() {
                                    int y = displayedYear - 1;
                                    if (y < first.year) return;
                                    displayedYear = y;
                                    if (y == first.year &&
                                        displayedMonth < first.month)
                                      displayedMonth = first.month;

                                    int d = tempSelectedDate.day;
                                    final maxDays = DateTime(
                                      displayedYear,
                                      displayedMonth + 1,
                                      0,
                                    ).day;
                                    if (d > maxDays) d = maxDays;
                                    tempSelectedDate = DateTime(
                                      displayedYear,
                                      displayedMonth,
                                      d,
                                    );
                                    calendarKey = UniqueKey();
                                  });
                                },
                              ),
                              InkWell(
                                onTap: () async {
                                  final totalYears =
                                      widget.lastDate.year - first.year + 1;
                                  final items = List.generate(
                                    totalYears,
                                    (i) => '${first.year + i}',
                                  );
                                  final res = await _showGridPicker(
                                    ctx,
                                    items,
                                    displayedYear - first.year,
                                    '$displayedYear',
                                  );
                                  if (res != null) {
                                    setState(() {
                                      int y = first.year + res;
                                      displayedYear = y;
                                      if (y == first.year &&
                                          displayedMonth < first.month)
                                        displayedMonth = first.month;
                                      if (y == widget.lastDate.year &&
                                          displayedMonth >
                                              widget.lastDate.month)
                                        displayedMonth = widget.lastDate.month;

                                      int d = tempSelectedDate.day;
                                      final maxDays = DateTime(
                                        displayedYear,
                                        displayedMonth + 1,
                                        0,
                                      ).day;
                                      if (d > maxDays) d = maxDays;
                                      tempSelectedDate = DateTime(
                                        displayedYear,
                                        displayedMonth,
                                        d,
                                      );
                                      calendarKey = UniqueKey();
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    '$displayedYear',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: baseColor,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.keyboard_double_arrow_left,
                                ),
                                onPressed: () {
                                  setState(() {
                                    int y = displayedYear + 1;
                                    if (y > widget.lastDate.year) return;
                                    displayedYear = y;
                                    if (y == widget.lastDate.year &&
                                        displayedMonth > widget.lastDate.month)
                                      displayedMonth = widget.lastDate.month;

                                    int d = tempSelectedDate.day;
                                    final maxDays = DateTime(
                                      displayedYear,
                                      displayedMonth + 1,
                                      0,
                                    ).day;
                                    if (d > maxDays) d = maxDays;
                                    tempSelectedDate = DateTime(
                                      displayedYear,
                                      displayedMonth,
                                      d,
                                    );
                                    calendarKey = UniqueKey();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Month Stepper (Bottom)
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_right),
                                onPressed: () {
                                  setState(() {
                                    int m = displayedMonth - 1;
                                    int y = displayedYear;
                                    if (m < 1) {
                                      m = 12;
                                      y--;
                                    }
                                    if (y < first.year ||
                                        (y == first.year && m < first.month))
                                      return; // Out of bounds
                                    displayedMonth = m;
                                    displayedYear = y;

                                    int d = tempSelectedDate.day;
                                    final maxDays = DateTime(y, m + 1, 0).day;
                                    if (d > maxDays) d = maxDays;
                                    tempSelectedDate = DateTime(y, m, d);
                                    calendarKey = UniqueKey();
                                  });
                                },
                              ),
                              InkWell(
                                onTap: () async {
                                  final items = List.generate(
                                    12,
                                    (i) => _getMonthName(i + 1),
                                  );
                                  final res = await _showGridPicker(
                                    ctx,
                                    items,
                                    displayedMonth - 1,
                                    _getMonthName(displayedMonth),
                                  );
                                  if (res != null) {
                                    setState(() {
                                      int m = res + 1;
                                      if (displayedYear == first.year &&
                                          m < first.month)
                                        m = first.month;
                                      if (displayedYear ==
                                              widget.lastDate.year &&
                                          m > widget.lastDate.month)
                                        m = widget.lastDate.month;
                                      displayedMonth = m;
                                      int d = tempSelectedDate.day;
                                      final maxDays = DateTime(
                                        displayedYear,
                                        m + 1,
                                        0,
                                      ).day;
                                      if (d > maxDays) d = maxDays;
                                      tempSelectedDate = DateTime(
                                        displayedYear,
                                        m,
                                        d,
                                      );
                                      calendarKey = UniqueKey();
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                  ),
                                  child: Text(
                                    _getMonthName(displayedMonth),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: baseColor,
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.keyboard_arrow_left),
                                onPressed: () {
                                  setState(() {
                                    int m = displayedMonth + 1;
                                    int y = displayedYear;
                                    if (m > 12) {
                                      m = 1;
                                      y++;
                                    }
                                    if (y > widget.lastDate.year ||
                                        (y == widget.lastDate.year &&
                                            m > widget.lastDate.month))
                                      return; // Out of bounds
                                    displayedMonth = m;
                                    displayedYear = y;

                                    int d = tempSelectedDate.day;
                                    final maxDays = DateTime(y, m + 1, 0).day;
                                    if (d > maxDays) d = maxDays;
                                    tempSelectedDate = DateTime(y, m, d);
                                    calendarKey = UniqueKey();
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 295,
                      child: ClipRect(
                        child: OverflowBox(
                          maxHeight: 360,
                          alignment: Alignment.bottomCenter,
                          child: Theme(
                            data: theme.copyWith(
                              colorScheme: theme.colorScheme.copyWith(
                                primary: baseColor,
                                onPrimary: onBase,
                                onSurface: theme.colorScheme.onSurface,
                              ),
                            ),
                            child: Localizations.override(
                              context: ctx,
                              locale: Locale(widget.langCode),
                              child: CalendarDatePicker(
                                key: calendarKey,
                                initialDate: tempSelectedDate,
                                firstDate: first,
                                lastDate: widget.lastDate,
                                onDateChanged: (date) {
                                  tempSelectedDate = date;
                                },
                                onDisplayedMonthChanged: (date) {
                                  setState(() {
                                    displayedMonth = date.month;
                                    displayedYear = date.year;
                                  });
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: TextButton.styleFrom(
                              foregroundColor: baseColor.withValues(alpha: 0.6),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              t('cancelBtn'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () =>
                                Navigator.pop(ctx, tempSelectedDate),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: baseColor,
                              foregroundColor: onBase,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: const StadiumBorder(),
                              elevation: 0,
                            ),
                            child: Text(
                              t('dpSave'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
          // Reset end date if it is before the new start date
          if (_end != null && _end!.isBefore(_start!)) {
            _end = null;
          }
        } else {
          _end = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = theme.colorScheme.onSurface;
    final bg = theme.colorScheme.surface;

    // We use English format for dates to keep numbers readable (e.g. 2026/06/15)
    final fmt = DateFormat('yyyy/MM/dd');

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('dpTitle'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: fg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Start Date Button
            _buildDateButton(
              label: t('dpStartDate'),
              date: _start,
              fmt: fmt,
              fg: fg,
              onTap: () => _pickDate(true),
            ),
            const SizedBox(height: 16),

            // End Date Button
            _buildDateButton(
              label: t('dpEndDate'),
              date: _end,
              fmt: fmt,
              fg: fg,
              onTap: () => _pickDate(false),
            ),
            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      t('cancelBtn'),
                      style: TextStyle(color: fg.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: fg,
                      foregroundColor: bg,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: (_start != null && _end != null)
                        ? () {
                            Navigator.pop(
                              context,
                              DateTimeRange(start: _start!, end: _end!),
                            );
                          }
                        : null,
                    child: Text(
                      t('dpSave'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required DateFormat fmt,
    required Color fg,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: fg.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: fg.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: date != null
                    ? fg.withValues(alpha: 0.3)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    date != null ? fmt.format(date) : '-- / -- / ----',
                    style: TextStyle(
                      fontSize: 16,
                      color: date != null ? fg : fg.withValues(alpha: 0.4),
                      fontWeight: date != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today_rounded,
                  color: fg.withValues(alpha: 0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
