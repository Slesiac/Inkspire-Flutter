import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // per SystemNavigator.pop()
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_providers.dart';
import '../../providers/cache_buster.dart';

class AppScaffold extends ConsumerWidget {
  // Riceve un child e lo incapsula in uno Scaffold (return Scaffold) con AppBar, NavigationBar e Fab.
  final Widget child;
  const AppScaffold({super.key, required this.child});

  // Calcola l’indice della tab attiva a partire dal percorso corrente.
  int _indexFromPath(String path) {
    if (path.startsWith('/app/artists')) return 1;
    if (path.startsWith('/app/profile')) return 2;
    return 0;
  }

  // Titolo dinamico dell’AppBar in base alla rotta.
  String _titleFromPath(String location) {
    if (location.startsWith('/app/home')) return 'Home';
    if (location.startsWith('/app/artists')) return 'Artists';
    if (location.startsWith('/app/profile')) return 'Profile';
    return '';
  }

  Future<bool> _confirmExit(BuildContext context) async {
    // Usare addPostFrame evita assert strani in alcuni casi di back predittivo
    await Future<void>.delayed(Duration.zero);
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exit'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Exit')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Calcola quale tab è attiva (_indexFromPath) in base al percorso corrente del router (path)
    final state = GoRouterState.of(context);
    final path = state.uri.path;
    final idx = _indexFromPath(path);
    final location = state.uri.toString();

    return PopScope(
      // intercettiamo sempre noi il back nella shell
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final router = GoRouter.of(context);

        // Se NON sono in Home, il back porta alla Home (niente dialog)
        if (!path.startsWith('/app/home')) {
          // post-frame per non interferire con il ciclo di pop
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) router.go('/app/home');
          });
          return;
        }

        // Se sono in Home -> dialog di conferma exit
        final exit = await _confirmExit(context);
        if (exit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titleFromPath(location)),
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          // Su /app/profile mostra le azioni riferite al profilo proprio
          actions: [
            if (path.startsWith('/app/profile')) ...[
              IconButton(
                tooltip: 'Edit profile',
                icon: const Icon(Icons.edit),
                onPressed: () => context.push('/app/profile/edit'),
              ),
              IconButton(
                tooltip: 'Logout',
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Logout')),
                      ],
                    ),
                  );
                  if (ok != true) return;

                  // Evita l'uso del BuildContext dopo await: cattura il router prima
                  final router = GoRouter.of(context);
                  await ref.read(authRepositoryProvider).signOut();
                  invalidateAfterAuthChange(ref); // Invalidazione cache vecchia
                  if (!context.mounted) return;
                  router.go('/login');
                },
              ),
            ],
          ],
        ),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: idx,
          onDestinationSelected: (i) {
            switch (i) {
              case 0:
                context.go('/app/home');
                break;
              case 1:
                context.go('/app/artists');
                break;
              case 2:
                context.go('/app/profile');
                break;
            }
          },
          destinations: const [
            // Icone e nomi delle sezioni della NavBar
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.people_alt_outlined), label: 'Artists'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/app/challenge/add'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}