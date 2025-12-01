import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:flutter/foundation.dart';

/// Robust timestamp parser to support multiple representations
/// - Firestore Timestamp
/// - ISO-8601 String (with/without timezone)
/// - int/double epoch (ms or sec)
/// - Map with seconds/nanoseconds (Firestore JSON)
/// - DateTime
DateTime _parseDateTime(dynamic value, {DateTime? fallback}) {
  try {
    if (value == null) return fallback ?? DateTime.now();

    // Firestore Timestamp
    if (value is Timestamp) {
      return value.toDate();
    }

    // Already a DateTime
    if (value is DateTime) {
      return value;
    }

    // Numeric epoch
    if (value is int) {
      // Heuristic: > 10^12 is ms; otherwise seconds
      if (value > 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(value * 1000);
      }
    }
    if (value is double) {
      // Treat as seconds precision if small; else ms
      if (value > 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt());
      } else {
        return DateTime.fromMillisecondsSinceEpoch((value * 1000).toInt());
      }
    }

    // Firestore REST style map {seconds: x, nanoseconds: y} or underscored keys
    if (value is Map) {
      final seconds = value['seconds'] ?? value['_seconds'];
      final nanos = (value['nanoseconds'] ?? value['_nanoseconds']) ?? 0;
      if (seconds is int) {
        final ms = seconds * 1000 + (nanos is int ? nanos ~/ 1000000 : 0);
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }

    // ISO-8601 string
    if (value is String) {
      // Try direct parse first
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;

      // Try appending Z if missing timezone
      final parsedZ = DateTime.tryParse(value.endsWith('Z') ? value : '${value}Z');
      if (parsedZ != null) return parsedZ;
    }
  } catch (_) {
    // Fall through to fallback
  }

  return fallback ?? DateTime.now();
}

/// Modelo imutável para representar um usuário
@immutable
class User {

  // Constructor
  const User({
    required this.userId,
    required this.userProfilePhoto,
    required this.userFullname,
    required this.userGender,
    required this.userBirthDay,
    required this.userBirthMonth,
    required this.userBirthYear,
    required this.userSchool,
    required this.userJobTitle,
    required this.userBio,
    required this.userPhoneNumber,
    required this.userEmail,
    required this.userGallery,
    required this.userCountry,
    required this.userLocality,
    required this.userGeoPoint, 
    required this.userSettings, 
    required this.userVideos, 
    required this.userStatus, 
    required this.userLevel, 
    required this.userIsVerified, 
    required this.userRegDate, 
    required this.userLastLogin, 
    required this.userDeviceToken, 
    required this.userTotalLikes, 
    required this.userTotalVisits, // User Presence variables
    required this.isUserOnline, 
    this.userState, // Novo campo para estado
    this.userRole,
    this.userWebsite,
    this.userInstagram,
    this.userTiktok,
    this.userYoutube,
    this.userPinterest,
    this.userVimeo,
    this.userStartingPrice,
    this.userAveragePrice,
    this.vendorAdvancedFilters,
    this.userServicesOffered,
    this.userOffers,
  });

  /// Safe empty user to avoid LateInitializationError before auth finishes
  factory User.empty([String userId = '']) {
    return User(
      userId: userId,
      userProfilePhoto: '',
      userFullname: '',
      userGender: '',
      userBirthDay: 1,
      userBirthMonth: 1,
      userBirthYear: 2000,
      userSchool: '',
      userJobTitle: '',
      userBio: '',
      userPhoneNumber: '',
      userEmail: '',
      userGallery: const <String, dynamic>{},
      userCountry: '',
      userLocality: '',
      userGeoPoint: const GeoPoint(0, 0),
      userSettings: const <String, dynamic>{},
      userVideos: const <String, dynamic>{},
      userStatus: 'inactive',
      userLevel: '',
      userIsVerified: false,
      userRegDate: DateTime.fromMillisecondsSinceEpoch(0),
      userLastLogin: DateTime.fromMillisecondsSinceEpoch(0),
      userDeviceToken: '',
      userTotalLikes: 0,
      userTotalVisits: 0,
      isUserOnline: false,
    );
  }

  /// factory user object
  factory User.fromDocument(Map<String, dynamic> doc) {
    // Helper to normalize Map-or-List fields into Map<String, dynamic>
    Map<String, dynamic>? normalizeToMap(dynamic raw) {
      if (raw == null) return null;
      try {
        if (raw is Map) {
          // Ensure keys are strings
          return raw.map((k, v) => MapEntry(k.toString(), v));
        }
        if (raw is List) {
          final map = <String, dynamic>{};
          for (var i = 0; i < raw.length; i++) {
            final v = raw[i];
            if (v == null) continue;
            map['$i'] = v;
          }
          return map;
        }
        if (raw is String) {
          // Treat single string as first entry
          return {'0': raw};
        }
      } catch (_) {
        // fallthrough to null
      }
      return null;
    }

    // Robust extraction of verification flag supporting multiple legacy/variant keys
    dynamic rawVerified = doc[USER_IS_VERIFIED];
    rawVerified ??= doc['is_verified'];
    rawVerified ??= doc['userIsVerified'];
    rawVerified ??= doc['isVerified'];
    var parsedVerified = false;
    if (rawVerified is bool) {
      parsedVerified = rawVerified;
    } else if (rawVerified is int) {
      // Accept 1/2/3 as verified (compat with external backends). Only 0 is false.
      parsedVerified = rawVerified >= 1;
    } else if (rawVerified is String) {
      final lv = rawVerified.toLowerCase().trim();
      parsedVerified = lv == 'true' || lv == '1' || lv == 'yes';
    }

    var finalGeoPoint = const GeoPoint(0, 0);
    if (doc[USER_GEO_POINT] != null && (doc[USER_GEO_POINT] as Map?)?['geopoint'] != null) {
      final geoData = (doc[USER_GEO_POINT] as Map)['geopoint'];
      // Se for um GeoPoint direto do Firestore, usa
      if (geoData is GeoPoint) {
        finalGeoPoint = geoData;
      } 
      // Se for um Map (vindo de SessionManager/JSON), cria o GeoPoint
      else if (geoData is Map) {
        final lat = (geoData['latitude'] as num?)?.toDouble() ?? 0.0;
        final lng = (geoData['longitude'] as num?)?.toDouble() ?? 0.0;
        finalGeoPoint = GeoPoint(lat, lng);
      }
    }

    return User(
      // Suporta tanto 'user_id' (padrão do app) quanto 'id' (fallback de fetchers)
      userId: doc[USER_ID] ?? doc['id'] ?? '',
      userProfilePhoto: doc[USER_PROFILE_PHOTO] ?? doc['user_photo_link'] ?? '',
      userFullname: doc[USER_FULLNAME] ?? doc['fullname'] ?? '',
      userGender: doc[USER_GENDER] ?? doc['gender'] ?? '',
      userBirthDay: doc[USER_BIRTH_DAY] ?? doc['birth_day'] ?? 1,
      userBirthMonth: doc[USER_BIRTH_MONTH] ?? doc['birth_month'] ?? 1,
      userBirthYear: doc[USER_BIRTH_YEAR] ?? doc['birth_year'] ?? 2000,
      userSchool: doc[USER_SCHOOL] ?? '',
      userJobTitle: doc[USER_JOB_TITLE] ?? '',
      userBio: doc[USER_BIO] ?? doc['bio'] ?? '',
      userPhoneNumber: doc[USER_PHONE_NUMBER] ?? doc['phone'] ?? '',
      userEmail: doc[USER_EMAIL] ?? doc['email'] ?? '',
      // Normalize user_gallery that can be Map or List (legacy)
      userGallery: normalizeToMap(doc[USER_GALLERY]),
      userCountry: doc[USER_COUNTRY] ?? '',
      userLocality: doc[USER_LOCALITY] ?? '',
      userState: doc[USER_STATE],
      userGeoPoint: finalGeoPoint,
      // Normalize settings and videos too
      userSettings: normalizeToMap(doc[USER_SETTINGS]),
      userVideos: normalizeToMap(doc[USER_VIDEOS]),
      userStatus: doc[USER_STATUS] ?? 'active',
      userIsVerified: parsedVerified,
      userLevel: doc[USER_LEVEL] ?? 'user',
      userRegDate: _parseDateTime(doc[USER_REG_DATE], fallback: DateTime.now()),
      userLastLogin: _parseDateTime(doc[USER_LAST_LOGIN], fallback: DateTime.now()),
      userDeviceToken: '', // Token agora está em subcoleção privada
      userTotalLikes: doc[USER_TOTAL_LIKES] ?? 0,
      userTotalVisits: doc[USER_TOTAL_VISITS] ?? 0,
      userRole: doc[USER_ROLE],
      // User Presence variables
      isUserOnline: doc['user_is_online'] ?? false,
      userWebsite: doc[USER_WEBSITE],
      userInstagram: doc[USER_INSTAGRAM],
      userTiktok: doc[USER_TIKTOK],
      userYoutube: doc[USER_YOUTUBE],
      userPinterest: doc[USER_PINTEREST],
      userVimeo: doc[USER_VIMEO],
      userStartingPrice: (doc[USER_STARTING_PRICE] as num?)?.toDouble(),
      userAveragePrice: (doc[USER_AVERAGE_PRICE] as num?)?.toDouble(),
      vendorAdvancedFilters: normalizeToMap(doc[USER_VENDOR_ADVANCED_FILTERS]),
      userServicesOffered: doc[USER_SERVICES_OFFERED] ?? doc['services_offered'],
      userOffers: (doc[USER_OFFERS] as List?)?.cast<Map<String, dynamic>>(),
    );
  }
  
  /// User info
  final String userId;
  final String userProfilePhoto;
  final String userFullname;
  final String userGender;
  final int userBirthDay;
  final int userBirthMonth;
  final int userBirthYear;
  final String userSchool;
  final String userJobTitle;
  final String userBio;
  final String userPhoneNumber;
  final String userEmail;
  final String userCountry;
  final String userLocality;
  final String? userState; // Novo campo para estado
  final GeoPoint userGeoPoint;
  final String userStatus;
  final bool userIsVerified; // Legacy field mantido para compatibilidade
  final String userLevel;
  final DateTime userRegDate;
  final DateTime userLastLogin;
  final String userDeviceToken;
  final int userTotalLikes;
  final int userTotalVisits;
  final String? userRole; // Role do usuário (provider ou null para usuário normal)
  final Map<String, dynamic>? userGallery;
  final Map<String, dynamic>? userSettings;
  final Map<String, dynamic>? userVideos; // vídeos do usuário (url/thumbnail)
  // User Presence variables
  final bool isUserOnline;
  // Social links (new)
  final String? userWebsite;
  final String? userInstagram;
  final String? userTiktok;
  final String? userYoutube;
  final String? userPinterest;
  final String? userVimeo;
  // Pricing (new)
  final double? userStartingPrice;
  final double? userAveragePrice;
  // Vendor advanced filters (new)
  final Map<String, dynamic>? vendorAdvancedFilters;
  // Services Offered (vendor description of services)
  final String? userServicesOffered;
  // Offers (list of offers - vendor)
  final List<Map<String, dynamic>>? userOffers;

  /// Badge de verificação (para compatibilidade, usando campo legacy)
  bool get isVerified => userIsVerified;

  /// Verifica se é perfil de noiva
  bool get isBrideProfile {
    return userRole?.toLowerCase() == 'bride';
  }

  /// Verifica se é perfil de vendor
  bool get isVendorProfile {
    return !isBrideProfile && userRole != null && userRole!.isNotEmpty;
  }

  /// Verifica se é perfil normal (não-provider)
  bool get isNormalProfile {
    return userRole == null || userRole!.isEmpty;
  }
}