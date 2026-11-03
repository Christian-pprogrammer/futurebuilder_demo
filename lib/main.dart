import 'package:flutter/material.dart';

void main() => runApp(const ProfileApp());

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FutureBuilder Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const ProfilePage(),
    );
  }
}

class Profile {
  final String name;
  final String email;
  final int coursesEnrolled;
  final String lastUpdated;

  const Profile({
    required this.name,
    required this.email,
    required this.coursesEnrolled,
    required this.lastUpdated,
  });
}

Future<Profile> fetchProfile({required bool shouldFail}) async {
  await Future.delayed(const Duration(seconds: 3));

  if (shouldFail) {
    throw Exception('No internet connection');
  }

  final now = DateTime.now();
  return Profile(
    name: 'Christian Mpano',
    email: 'c.mpano@example.com',
    coursesEnrolled: 4,
    lastUpdated:
        '${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
  );
}

const cachedProfile = Profile(
  name: 'Christian Mpano',
  email: 'c.mpano@example.com',
  coursesEnrolled: 3,
  lastUpdated: 'yesterday (cached)',
);

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<Profile> _profileFuture;
  bool _simulateNoInternet = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = fetchProfile(shouldFail: _simulateNoInternet);
  }

  void _reload() {
    setState(() {
      _profileFuture = fetchProfile(shouldFail: _simulateNoInternet);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // STEP 5: lets me make the next load fail on purpose.
            SwitchListTile(
              title: const Text('Simulate no internet'),
              subtitle: const Text('Turn on, then tap Reload'),
              value: _simulateNoInternet,
              onChanged: (value) => setState(() => _simulateNoInternet = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Profile>(
                // PROPERTY 1: future -> the task FutureBuilder watches.
                future: _profileFuture,

                initialData: cachedProfile,

                // PROPERTY 3: builder -> decides what to show for each state.
                builder: (context, snapshot) {
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;

                  // STEP 4a: the future failed.
                  if (snapshot.hasError && !isLoading) {
                    return _ErrorView(
                      message: snapshot.error.toString(),
                      onRetry: _reload,
                    );
                  }

                  // STEP 4b: we have data (fresh, or initialData while loading).
                  if (snapshot.hasData) {
                    return _ProfileView(
                      profile: snapshot.data!,
                      isRefreshing: isLoading,
                    );
                  }

                  // STEP 4c: still waiting and nothing to show yet.
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Loading your profile...'),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _reload,
        icon: const Icon(Icons.refresh),
        label: const Text('Reload'),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  final Profile profile;
  final bool isRefreshing;

  const _ProfileView({required this.profile, required this.isRefreshing});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        // Thin bar on top when old data is showing and new data is loading.
        if (isRefreshing) const LinearProgressIndicator(),
        const SizedBox(height: 24),
        CircleAvatar(
          radius: 40,
          child: Text(profile.name[0], style: text.headlineMedium),
        ),
        const SizedBox(height: 16),
        Text(profile.name, style: text.headlineSmall),
        Text(profile.email, style: text.bodyLarge),
        const SizedBox(height: 16),
        Text(
          '${profile.coursesEnrolled} courses enrolled',
          style: text.titleMedium,
        ),
        const SizedBox(height: 4),
        Text('Last updated: ${profile.lastUpdated}', style: text.bodySmall),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 56),
          const SizedBox(height: 12),
          const Text("Couldn't load your profile."),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
