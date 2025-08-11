import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/youtube_models.dart';

class YouTubeFirebaseCache {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Global collections (not user-specific)
  static CollectionReference get _playlistsCollection => _firestore.collection('youtube_playlists');
  static CollectionReference get _videosCollection => _firestore.collection('youtube_videos');
  static CollectionReference get _liveStreamsCollection => _firestore.collection('youtube_live_streams');
  static CollectionReference get _cacheMetadataCollection => _firestore.collection('youtube_cache_metadata');
  
  static const String _channelId = 'UChMsjzqgMrj4laOTWYyJBQw';
  static const Duration _cacheExpiry = Duration(hours: 24); // 24 hour cache for optimization
  
  static void _debugLog(String message) {
    print('🔥 YouTubeFirebaseCache: $message');
  }
  
  // =================== CACHE VALIDATION ===================
  
  static Future<bool> _isCacheValid(String cacheType) async {
    try {
      final doc = await _cacheMetadataCollection.doc(cacheType).get();
      
      if (!doc.exists) {
        _debugLog('Cache metadata not found for $cacheType');
        return false;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
      final now = DateTime.now();
      final isValid = now.difference(lastUpdated) < _cacheExpiry;
      
      _debugLog('Cache $cacheType is ${isValid ? "valid" : "expired"} (age: ${now.difference(lastUpdated).inHours}h)');
      return isValid;
    } catch (e) {
      _debugLog('Error checking cache validity for $cacheType: $e');
      return false;
    }
  }
  
  static Future<void> _updateCacheMetadata(String cacheType, {Map<String, dynamic>? additionalData}) async {
    try {
      final data = {
        'lastUpdated': FieldValue.serverTimestamp(),
        'cacheType': cacheType,
        'channelId': _channelId,
        ...?additionalData,
      };
      
      await _cacheMetadataCollection.doc(cacheType).set(data, SetOptions(merge: true));
      _debugLog('Updated cache metadata for $cacheType');
    } catch (e) {
      _debugLog('Error updating cache metadata for $cacheType: $e');
    }
  }
  
  // Public method for updating cache metadata
  static Future<void> updateCacheMetadata(String cacheType, {Map<String, dynamic>? additionalData}) async {
    await _updateCacheMetadata(cacheType, additionalData: additionalData);
  }
  
  // =================== PLAYLISTS ===================
  
  static Future<void> cachePlaylists(List<PlaylistInfo> playlists) async {
    try {
      _debugLog('Caching ${playlists.length} playlists to Firebase');
      
      final batch = _firestore.batch();
      
      for (final playlist in playlists) {
        final docRef = _playlistsCollection.doc(playlist.id);
        batch.set(docRef, {
          ...playlist.toJson(),
          'channelId': _channelId,
          'cachedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      await _updateCacheMetadata('playlists', additionalData: {
        'count': playlists.length,
      });
      
      _debugLog('✅ Successfully cached ${playlists.length} playlists');
    } catch (e) {
      _debugLog('❌ Error caching playlists: $e');
      throw e;
    }
  }
  
  static Future<List<PlaylistInfo>?> getCachedPlaylists() async {
    try {
      if (!await _isCacheValid('playlists')) {
        _debugLog('Playlists cache is invalid or expired');
        return null;
      }
      
      _debugLog('Retrieving playlists from Firebase cache');
      
      final querySnapshot = await _playlistsCollection
          .where('channelId', isEqualTo: _channelId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        _debugLog('No cached playlists found');
        return null;
      }
      
      final playlists = querySnapshot.docs
          .map((doc) => PlaylistInfo.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      _debugLog('✅ Retrieved ${playlists.length} playlists from cache');
      return playlists;
    } catch (e) {
      _debugLog('❌ Error retrieving cached playlists: $e');
      return null;
    }
  }
  
  // =================== VIDEOS ===================
  
  static Future<void> cachePlaylistVideos(String playlistId, List<YouTubeVideo> videos) async {
    try {
      if (videos.isEmpty) return;
      
      _debugLog('Caching ${videos.length} videos for playlist $playlistId');
      
      final batch = _firestore.batch();
      
      for (final video in videos) {
        final docRef = _videosCollection.doc(video.id);
        batch.set(docRef, {
          ...video.toJson(),
          'playlistId': playlistId,
          'channelId': _channelId,
          'cachedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      await _updateCacheMetadata('videos_$playlistId', additionalData: {
        'playlistId': playlistId,
        'count': videos.length,
      });
      
      _debugLog('✅ Successfully cached ${videos.length} videos for playlist $playlistId');
    } catch (e) {
      _debugLog('❌ Error caching videos for playlist $playlistId: $e');
      throw e;
    }
  }
  
  static Future<List<YouTubeVideo>?> getCachedPlaylistVideos(String playlistId) async {
    try {
      if (!await _isCacheValid('videos_$playlistId')) {
        _debugLog('Videos cache for playlist $playlistId is invalid or expired');
        return null;
      }
      
      _debugLog('Retrieving videos for playlist $playlistId from Firebase cache');
      
      final querySnapshot = await _videosCollection
          .where('playlistId', isEqualTo: playlistId)
          .where('channelId', isEqualTo: _channelId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        _debugLog('No cached videos found for playlist $playlistId');
        return null;
      }
      
      final videos = querySnapshot.docs
          .map((doc) => YouTubeVideo.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      _debugLog('✅ Retrieved ${videos.length} videos from cache for playlist $playlistId');
      return videos;
    } catch (e) {
      _debugLog('❌ Error retrieving cached videos for playlist $playlistId: $e');
      return null;
    }
  }
  
  static Future<List<YouTubeVideo>?> getAllCachedVideos() async {
    try {
      if (!await _isCacheValid('all_videos')) {
        _debugLog('All videos cache is invalid or expired');
        return null;
      }
      
      _debugLog('Retrieving all videos from Firebase cache');
      
      final querySnapshot = await _videosCollection
          .where('channelId', isEqualTo: _channelId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        _debugLog('No cached videos found');
        return null;
      }
      
      final videos = querySnapshot.docs
          .map((doc) => YouTubeVideo.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      _debugLog('✅ Retrieved ${videos.length} videos from cache');
      return videos;
    } catch (e) {
      _debugLog('❌ Error retrieving all cached videos: $e');
      return null;
    }
  }
  
  // =================== SEARCH ===================
  
  static Future<List<YouTubeVideo>> searchCachedVideos(String query, {int limit = 20}) async {
    try {
      _debugLog('Searching videos in Firebase cache for query: "$query"');
      
      final allVideos = await getAllCachedVideos();
      
      if (allVideos == null || allVideos.isEmpty) {
        _debugLog('No cached videos available for search');
        return [];
      }
      
      final queryLower = query.toLowerCase();
      final filteredVideos = allVideos.where((video) {
        return video.title.toLowerCase().contains(queryLower) ||
               video.description.toLowerCase().contains(queryLower);
      }).take(limit).toList();
      
      _debugLog('✅ Found ${filteredVideos.length} videos matching query "$query"');
      return filteredVideos;
    } catch (e) {
      _debugLog('❌ Error searching cached videos: $e');
      return [];
    }
  }
  
  // =================== LIVE STREAMS ===================
  
  static Future<void> cacheLiveStreams(List<LiveStream> liveStreams) async {
    try {
      _debugLog('Caching ${liveStreams.length} live streams');
      
      // Clear existing live streams first (since they change frequently)
      final existingStreams = await _liveStreamsCollection
          .where('channelId', isEqualTo: _channelId)
          .get();
      
      final batch = _firestore.batch();
      
      // Delete existing streams
      for (final doc in existingStreams.docs) {
        batch.delete(doc.reference);
      }
      
      // Add new streams
      for (final stream in liveStreams) {
        final docRef = _liveStreamsCollection.doc(stream.id);
        batch.set(docRef, {
          ...stream.toJson(),
          'channelId': _channelId,
          'cachedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      await _updateCacheMetadata('live_streams', additionalData: {
        'count': liveStreams.length,
      });
      
      _debugLog('✅ Successfully cached ${liveStreams.length} live streams');
    } catch (e) {
      _debugLog('❌ Error caching live streams: $e');
      throw e;
    }
  }
  
  static Future<List<LiveStream>?> getCachedLiveStreams() async {
    try {
      // Live streams have shorter cache validity (30 minutes)
      const liveCacheExpiry = Duration(minutes: 30);
      
      final doc = await _cacheMetadataCollection.doc('live_streams').get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final lastUpdated = (data['lastUpdated'] as Timestamp).toDate();
        final now = DateTime.now();
        
        if (now.difference(lastUpdated) >= liveCacheExpiry) {
          _debugLog('Live streams cache is expired');
          return null;
        }
      } else {
        _debugLog('Live streams cache metadata not found');
        return null;
      }
      
      _debugLog('Retrieving live streams from Firebase cache');
      
      final querySnapshot = await _liveStreamsCollection
          .where('channelId', isEqualTo: _channelId)
          .get();
      
      if (querySnapshot.docs.isEmpty) {
        _debugLog('No cached live streams found');
        return null;
      }
      
      final liveStreams = querySnapshot.docs
          .map((doc) => LiveStream.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
      
      _debugLog('✅ Retrieved ${liveStreams.length} live streams from cache');
      return liveStreams;
    } catch (e) {
      _debugLog('❌ Error retrieving cached live streams: $e');
      return null;
    }
  }
  
  // =================== CACHE MANAGEMENT ===================
  
  static Future<void> clearAllCache() async {
    try {
      _debugLog('Clearing all Firebase cache');
      
      final batch = _firestore.batch();
      
      // Clear all collections
      final collections = [
        _playlistsCollection,
        _videosCollection,
        _liveStreamsCollection,
        _cacheMetadataCollection,
      ];
      
      for (final collection in collections) {
        final docs = await collection.where('channelId', isEqualTo: _channelId).get();
        for (final doc in docs.docs) {
          batch.delete(doc.reference);
        }
      }
      
      await batch.commit();
      _debugLog('✅ All Firebase cache cleared');
    } catch (e) {
      _debugLog('❌ Error clearing Firebase cache: $e');
    }
  }
  
  static Future<bool> hasAnyCache() async {
    try {
      final playlistsValid = await _isCacheValid('playlists');
      final videosQuery = await _cacheMetadataCollection
          .where('cacheType', whereIn: ['all_videos'])
          .get();
      
      return playlistsValid || videosQuery.docs.isNotEmpty;
    } catch (e) {
      _debugLog('Error checking cache status: $e');
      return false;
    }
  }
}
