import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../providers/sync_provider.dart';
import '../models/sync_item.dart';

class TrayService {
  final SystemTray _systemTray = SystemTray();
  final ProviderContainer _container;
  ProviderSubscription<SyncState>? _subscription;

  TrayService(this._container);

  Future<void> init() async {
    await _systemTray.initSystemTray(
      title: 'Folder Diff Sync',
      iconPath: Platform.isWindows ? 'assets/logo.ico' : 'assets/logo.png',
      toolTip: 'Folder Diff Sync',
    );

    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        windowManager.show();
        windowManager.focus();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });

    // Reactive listener to update menu when syncing state changes.
    _subscription = _container.listen(syncProvider, (previous, next) {
      // Update if syncing status changes OR if sync is complete and we need to show the final count.
      final syncStarted = !(previous?.isSyncing ?? false) && next.isSyncing;
      final syncFinished = (previous?.isSyncing ?? false) && !next.isSyncing;

      // Also update during sync if the count changes, to show progress in the status label.
      final countChanged = previous?.syncedFilesCount != next.syncedFilesCount;

      if (syncStarted || syncFinished || (next.isSyncing && countChanged)) {
        _rebuildMenu(next);
      }
    }, fireImmediately: true);
  }

  Future<void> _rebuildMenu(SyncState state) async {
    final items = <MenuItemBase>[];

    // --- Dynamic Status Header ---
    if (state.isSyncing) {
      items.add(
        MenuItemLabel(
          label:
              '🔄  Status: Syncing (${state.syncedFilesCount}/${state.totalFilesToSync} files)',
          enabled: false,
        ),
      );
    } else if (state.syncProgress >= 1.0 && state.syncTotalCount > 0) {
      items.add(
        MenuItemLabel(
          label: '✅  Status: Sync Complete (${state.syncedFilesCount} files)',
          enabled: false,
        ),
      );
    } else {
      items.add(
        MenuItemLabel(label: '✦  Folder Diff Sync Pro', enabled: false),
      );
    }
    items.add(MenuSeparator());

    // --- Navigation Shortcuts ---
    items.add(
      MenuItemLabel(
        label: '📂  Open Folder Sync',
        onClicked: (_) {
          _container.read(syncProvider.notifier).setMode(AppMode.folderSync);
          windowManager.show();
          windowManager.focus();
        },
      ),
    );

    items.add(
      MenuItemLabel(
        label: '📝  Open Env Sync',
        onClicked: (_) {
          _container.read(syncProvider.notifier).setMode(AppMode.envSync);
          windowManager.show();
          windowManager.focus();
        },
      ),
    );

    items.add(MenuSeparator());

    // --- Window Controls ---
    items.add(
      MenuItemLabel(
        label: '🪟  Restore Window',
        onClicked: (_) {
          windowManager.show();
          windowManager.focus();
        },
      ),
    );

    items.add(
      MenuItemLabel(
        label: '❌  Exit Application',
        onClicked: (_) {
          _subscription?.close();
          _systemTray.destroy();
          exit(0);
        },
      ),
    );

    final menu = Menu();
    await menu.buildFrom(items);
    await _systemTray.setContextMenu(menu);

    // Update Tooltip
    String tip = 'Folder Diff Sync';
    if (state.isSyncing) {
      tip =
          'Syncing: ${state.syncedFilesCount}/${state.totalFilesToSync} files';
    } else if (state.syncProgress >= 1.0 && state.syncTotalCount > 0) {
      tip = 'Sync Complete: ${state.syncedFilesCount} files';
    }
    await _systemTray.setToolTip(tip);
  }
}
