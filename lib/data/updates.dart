import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Проверка обновлений StudMate по релизам GitHub.
///
/// Релизы: https://github.com/lkorss/studmate/releases
/// API: https://api.github.com/repos/lkorss/studmate/releases/latest
class AppUpdate {
  const AppUpdate(this.version, this.downloadUrl, this.releaseUrl);

  /// Версия релиза без ведущего «v» (например, «1.0.1»).
  final String version;

  /// Прямая ссылка на APK из релиза.
  final String downloadUrl;

  /// Страница релиза (fallback, если asset-ов нет).
  final String releaseUrl;
}

const String kUpdateRepoOwner = 'lkorss';
const String kUpdateRepoName = 'studmate';

bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

/// Скачивает APK релиза в приватное хранилище приложения с прогрессом (0…1).
/// Возвращает путь к файлу. Сетевые ошибки кидаются, файл при этом удаляется, —
/// вызывающий сам решает, что показывать. [registerCancel] получает HttpClient:
/// закройте его, чтобы прервать загрузку.
Future<String> downloadApk(
  AppUpdate update, {
  void Function(double progress)? onProgress,
  void Function(HttpClient cancelByClose)? registerCancel,
}) async {
  final dir = await _updatesDir();
  final file = File('${dir.path}${Platform.pathSeparator}'
      'studmate-${update.version}.apk');

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  registerCancel?.call(client);
  try {
    final request = await client.getUrl(Uri.parse(update.downloadUrl));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}');
    }

    final total = int.tryParse(
          response.headers.value(HttpHeaders.contentLengthHeader) ?? '',
        ) ??
        -1;
    var received = 0;
    final sink = file.openWrite();
    try {
      await for (final chunk in response) {
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) onProgress?.call(received / total);
      }
      await sink.flush();
      await sink.close();
    } catch (_) {
      await sink.close();
      if (await file.exists()) await file.delete();
      rethrow;
    }
    if (total > 0) onProgress?.call(1.0);
    return file.path;
  } finally {
    client.close(force: true);
  }
}

Future<Directory> _updatesDir() async {
  final external = await getExternalStorageDirectory();
  final dir = external ?? await getApplicationSupportDirectory();
  final updates = Directory('${dir.path}${Platform.pathSeparator}updates');
  await updates.create(recursive: true);
  return updates;
}

/// Проверяет, есть ли релиз новее [currentVersion] (например, «1.0.0»).
///
/// Возвращает null, если: newer-релиза нет, релизов нет, нет ответа сети,
/// исчерпан лимит GitHub API — во всех случаях приложение ведёт себя
/// так, будто обновления нет.
Future<AppUpdate?> checkForUpdate(String currentVersion) async {
  // flutter test: никаких сетевых запросов.
  if (_isTest) return null;

  final uri = Uri.parse(
    'https://api.github.com/repos/$kUpdateRepoOwner/$kUpdateRepoName/releases/latest',
  );
  try {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.userAgentHeader, 'StudMate');
    request.headers.set(HttpHeaders.acceptHeader, 'application/vnd.github+json');
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    final body = await response.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    return _parseRelease(json, currentVersion);
  } catch (_) {
    // Оффлайн / лимит — считаем, что обновления нет.
    return null;
  }
}

AppUpdate? _parseRelease(Map<String, dynamic> json, String currentVersion) {
  final tag = (json['tag_name'] as String?) ?? '';
  final latest = _parseVersion(tag);
  if (latest == null) return null;

  final current = _parseVersion(currentVersion) ?? const [];
  if (!_isNewer(latest, current)) return null;

  // Приоритет asset-ов: universal → arm64 → любой .apk.
  final assets = (json['assets'] as List<Object?>? ?? const [])
      .whereType<Map<String, dynamic>>();
  final apks = assets
      .where((a) => ((a['name'] as String?) ?? '').toLowerCase().endsWith('.apk'))
      .toList();
  final browsers = apks
      .map((a) => (a['browser_download_url'] as String?) ?? '')
      .where((u) => u.isNotEmpty)
      .toList();
  if (browsers.isEmpty) {
    // APK нет в релизе — есть только страница релиза.
    final html = json['html_url'] as String?;
    if (html == null) return null;
    return AppUpdate(_versionToString(latest), html, html);
  }

  String pick(List<String> urls) {
    for (final marker in ['universal', 'arm64']) {
      for (final u in urls) {
        if (u.toLowerCase().contains(marker)) return u;
      }
    }
    return urls.first;
  }

  final downloadUrl = pick(browsers);
  final releaseUrl = json['html_url'] as String? ?? downloadUrl;
  return AppUpdate(_versionToString(latest), downloadUrl, releaseUrl);
}

/// «v1.2.3+4» / «1.2.3» → [1, 2, 3] (+build игнорируется).
List<int>? _parseVersion(String raw) {
  var s = raw.trim();
  if (s.startsWith('v')) s = s.substring(1);
  if (s.isEmpty) return null;
  final plus = s.indexOf('+');
  if (plus >= 0) s = s.substring(0, plus);
  final parts = s.split('.');
  final out = <int>[];
  for (final p in parts) {
    final n = int.tryParse(p);
    if (n == null) return null;
    out.add(n);
  }
  return out.isEmpty ? null : out;
}

String _versionToString(List<int> v) => v.join('.');

/// Сравнение по числовым сегментам с выравниванием длины (1.2 → 1.2.0).
bool _isNewer(List<int> latest, List<int> current) {
  final len = latest.length > current.length
      ? latest.length
      : current.length;
  int at(List<int> v, int i) => i < v.length ? v[i] : 0;
  for (var i = 0; i < len; i++) {
    if (at(latest, i) != at(current, i)) {
      return at(latest, i) > at(current, i);
    }
  }
  return false;
}
