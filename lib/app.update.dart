import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateRequiredPage extends StatelessWidget {
  final String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.speed.client';

  Future<void> _openPlayStore() async {
    if (await canLaunch(playStoreUrl)) {
      await launch(playStoreUrl);
    } else {
      throw 'Could not launch $playStoreUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'A new version is available!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openPlayStore,
              child: const Text('Update Now'),
            ),
          ],
        ),
      ),
    );
  }
}
