import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class _InputDropdown extends StatelessWidget {
  const _InputDropdown({
    Key key,
    this.child,
    this.labelText,
    this.valueText,
    this.valueStyle,
    this.onPressed }) : super(key: key);

  final String labelText;
  final String valueText;
  final TextStyle valueStyle;
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(valueText, style: valueStyle),
      ),
    );
  }
}

class DatePicker extends StatelessWidget {
  const DatePicker({
    Key key,
    this.labelText,
    this.selectedDate,
    this.selectDate,
  }) : super(key: key);

  final String labelText;
  final DateTime selectedDate;
  final ValueChanged<DateTime> selectDate;

  Future<void> _selectDate(BuildContext context) async {
    DateTime now = DateTime.now();
    DateTime initialDate = selectedDate;
    if (now.isAfter(selectedDate)) {
      initialDate = now;
    }
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: initialDate,
        firstDate: new DateTime(now.year, now.month, now.day),
        lastDate: DateTime(2101)
    );
    if (picked != null && picked != selectedDate) {
      selectDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle valueStyle = new TextStyle(
      fontSize: 50.0,
    );

    return _InputDropdown(
      labelText: labelText,
      valueText: DateFormat.yMMMd().format(selectedDate),
      valueStyle: valueStyle,
      onPressed: () { _selectDate(context); },
    );
  }
}