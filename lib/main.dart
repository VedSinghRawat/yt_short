import 'package:flutter/material.dart';
import 'package:myapp/constants/constants.dart';
import 'package:myapp/core/widgets/yt_shorts_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Youtube Shorts',
      theme: ThemeData.dark(
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Youtube Shorts'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: YoutubeShortsList(videoIds: shortIds),
      ),
    );
  }
}
