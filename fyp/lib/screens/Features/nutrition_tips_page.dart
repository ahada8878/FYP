import 'package:flutter/material.dart';


class NutritionTipsPage extends StatefulWidget {
  const NutritionTipsPage({super.key});

  @override
  State<NutritionTipsPage> createState() => _NutritionTipsPageState();
}

class _NutritionTipsPageState extends State<NutritionTipsPage> {


  @override
  void initState() {
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Health Data")),
      body: Center(
        child: Column(

        ),
      ),
    );
  }
}
