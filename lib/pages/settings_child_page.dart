import 'package:flutter/material.dart';

class SettingsChildPage extends StatefulWidget {
  SettingsChildPage({
    super.key,
    required this.title,
    required Map<String, String> map,
    required this.selected,
    required this.callback,
  }) {
    list = map.entries.toList();
  }

  final String title;
  late final List<MapEntry<String, String>> list;
  final String selected;
  final Function(String) callback;

  @override
  State<SettingsChildPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsChildPage> {
  late String selected;

  @override
  void initState() {
    selected = widget.selected;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: widget.list.length,
        itemBuilder: (context, index) => RadioListTile<String>(
          title: Text(widget.list[index].value),
          value: widget.list[index].key,
          groupValue: selected,
          onChanged: (value) {
            if (value != null) {
              widget.callback.call(value);

              setState(() {
                selected = value;
              });
            }
          },
        ),
      ),
    );
  }
}
