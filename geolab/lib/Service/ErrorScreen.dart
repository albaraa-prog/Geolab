/*
import 'package:flutter/material.dart';
import 'package:geolab/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                'Initialization Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(error),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await Supabase.initialize(
                      url: supabaseUrl,
                      anonKey: supabaseKey,
                    );
                    Navigator.pushReplacementNamed(context, '/signin');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Retry failed: ${e.toString()}')),
                    );
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
*/