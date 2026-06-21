import 'package:flutter/material.dart';

class CareGiver extends StatefulWidget {
  const CareGiver({super.key});

  @override
  State<CareGiver> createState() => _CareGiverState();
}

class _CareGiverState extends State<CareGiver> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Care Giver"));
  }
}
