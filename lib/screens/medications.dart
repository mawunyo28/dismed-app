import 'package:flutter/material.dart';

class Medications extends StatefulWidget {
  const Medications({super.key});

  @override
  State<Medications> createState() => _MedicationsState();
}

class _MedicationsState extends State<Medications> {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Medications"));
  }
}
