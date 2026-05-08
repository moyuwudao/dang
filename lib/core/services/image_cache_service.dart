import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  
  factory ImageCacheService() => _instance;
  
  ImageCacheService._internal();

  Directory? _cacheDir;
  final Map<String, File> _memoryCache = {};
  final int _maxMemoryCacheSize = 50;
  final Duration _cacheDuration = Duration(days: 7);

  Future<void> init() async {
    if (_cacheDir == null) {
      final appDocDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDocDir.path}/image_cache');
      await _cacheDir!.create(recursive: true);
      await _cleanExpiredCache();
    }
  }

  Future<File?> getImage(String url) async {
    await init();
    
    final cacheKey = _generateCacheKey(url);
    final cachedFile = _memoryCache[cacheKey];
    
    if (cachedFile != null && await cachedFile.exists()) {
      return cachedFile;
    }
    
    final filePath = '${_cacheDir!.path}/$cacheKey';
    final file = File(filePath);
    
    if (await file.exists()) {
      final stat = await file.stat();
      if (DateTime.now().difference(stat.modified) < _cacheDuration) {
        _addToMemoryCache(cacheKey, file);
        return file;
      } else {
        await file.delete();
      }
    }
    
    return null;
  }

  Future<File> saveImage(String url, List<int> bytes) async {
    await init();
    
    final cacheKey = _generateCacheKey(url);
    final filePath = '${_cacheDir!.path}/$cacheKey';
    final file = File(filePath);
    
    await file.writeAsBytes(bytes);
    _addToMemoryCache(cacheKey, file);
    
    return file;
  }

  void _addToMemoryCache(String key, File file) {
    if (_memoryCache.length >= _maxMemoryCacheSize) {
      final oldestKey = _memoryCache.keys.first;
      _memoryCache.remove(oldestKey);
    }
    _memoryCache[key] = file;
  }

  String _generateCacheKey(String url) {
    return Uri.encodeComponent(url).replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
  }

  Future<void> _cleanExpiredCache() async {
    if (_cacheDir == null) return;
    
    try {
      final files = await _cacheDir!.list().toList();
      
      for (var file in files) {
        if (file is File) {
          final stat = await file.stat();
          if (DateTime.now().difference(stat.modified) > _cacheDuration) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to clean cache: $e');
    }
  }

  Future<void> clearCache() async {
    await init();
    _memoryCache.clear();
    
    try {
      final files = await _cacheDir!.list().toList();
      for (var file in files) {
        if (file is File) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Failed to clear cache: $e');
    }
  }

  Future<int> getCacheSize() async {
    await init();
    
    try {
      final files = await _cacheDir!.list().whereType<File>().toList();
      int totalBytes = 0;
      
      for (var file in files) {
        final stat = await file.stat();
        totalBytes += stat.size;
      }
      
      return totalBytes;
    } catch (e) {
      debugPrint('Failed to get cache size: $e');
      return 0;
    }
  }
}