// ignore_for_file: constant_identifier_names

import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:flutter/material.dart';

/// APP SETINGS INFO CONSTANTS - SECTION ///
///
const String APP_NAME = 'WedConnex';
const Color APP_PRIMARY_COLOR = GlimpseColors.primaryColorLight;
const Color APP_ACCENT_COLOR = Colors.pinkAccent;
const int ANDROID_APP_VERSION_NUMBER = 1; // Google Play Version Number
const int IOS_APP_VERSION_NUMBER = 1; // App Store Version Number

/// FONT FAMILY CONSTANTS
const String FONT_PLUS_JAKARTA_SANS = 'Plus Jakarta Sans';

//
// Add Google Maps - API KEY required for Passport feature
//
// [OK] CHAVES MOVIDAS PARA FIREBASE (Nov/2025)
// As chaves do Google Maps agora são carregadas do Firebase Firestore.
// Localização: AppInfo > GoogleAndroidMaps e AppInfo > GoogleMapsApiKey
// 
// IMPORTANTE: Não mais hardcoded no código por segurança.
// Use GoogleMapsConfigService para acessar as chaves.
//
// IMPORTANTE: As chaves devem ter as seguintes APIs habilitadas no Google Cloud Console:
// - Maps SDK for Android / Maps SDK for iOS
// - Geolocation API
// - Geocoding API
// - Places API (New)
// - Places API
// - Identity Toolkit API
// - Token Service API
//
// Firebase Firestore fields para as chaves:
// GoogleAndroidMaps e GoogleMapsApiKey são acessados via GoogleMapsConfigService
//
// Restrições recomendadas:
// 1) Android: Restringir por package name (com.maikelgalvao.wedconnex) + SHA-1
// 2) iOS: Restringir por bundle ID (com.maikelgalvao.wedconnex)
//
//
// AGORA.IO VIDEO/AUDIO CALL CREDENTIALS
//
const String AGORA_APP_ID = '';


/// List of Supported Locales
/// Add your new supported Locale to the array list.
///
/// E.g: Locale('fr'), Locale('es'),
///
const List<Locale> SUPPORTED_LOCALES = [
  Locale('en', 'US'), // 🇺🇸 English (US)
  Locale('pt', 'BR'), // 🇧🇷 Português (Brasil)
  Locale('es', 'ES'), // 🇪🇸 Español (España)
];

///
/// END APP SETINGS - SECTION

///
/// DATABASE COLLECTIONS FIELD - SECTION
///
/// FIREBASE MESSAGING TOPIC
const NOTIFY_USERS = 'NOTIFY_USERS';

/// DATABASE COLLECTION NAMES USED IN APP
///
const String C_APP_INFO = 'AppInfo';
const String C_USERS = 'Users';
const String C_FLAGGED_USERS = 'FlaggedUsers';
const String C_CONNECTIONS = 'Connections';
const String C_CONVERSATIONS = 'Conversations';
const String C_LIKES = 'Likes';
const String C_VISITS = 'Visits';
const String C_MESSAGES = 'Messages';
const String C_NOTIFICATIONS = 'Notifications';
const String C_BLOCKED_USERS = 'BlockedUsers';

/// Collection name for wedding announcements
const String WEDDING_ANNOUNCEMENTS = 'WeddingAnnouncements';

/// DATABASE FIELDS FOR AppInfo COLLECTION  ///
///
const String ANDROID_APP_CURRENT_VERSION = 'android_app_current_version';
const String IOS_APP_CURRENT_VERSION = 'ios_app_current_version';
const String ANDROID_PACKAGE_NAME = 'android_package_name';
const String IOS_APP_ID = 'ios_app_id';
const String APP_EMAIL = 'app_email';
const String PRIVACY_POLICY_URL = 'privacy_policy_url';
const String TERMS_OF_SERVICE_URL = 'terms_of_service_url';
const String FIREBASE_SERVER_KEY = 'firebase_server_key';
const String STORE_SUBSCRIPTION_IDS = 'store_subscription_ids';
// Optional alternative schema (two fields):
const String STORE_MONTHLY_ID = 'store_monthly_id';
const String STORE_ANNUAL_ID = 'store_annual_id';
const String FREE_ACCOUNT_MAX_DISTANCE = 'free_account_max_distance';
const String VIP_ACCOUNT_MAX_DISTANCE = 'vip_account_max_distance';
// RevenueCat public API key field inside AppInfo (revenue_cat > public_api_key)
const String REVENUE_CAT_PUBLIC_API_KEY = 'public_api_key';
// Identifier for entitlement configured in RevenueCat Dashboard
const String REVENUE_CAT_ENTITLEMENT_ID = 'Wedconnex Pro';
// Package identifiers for RevenueCat products
const String REVENUE_CAT_MONTHLY_PACKAGE = r'$rc_monthly';
const String REVENUE_CAT_ANNUAL_PACKAGE = r'$rc_annual';
// Offerings identifier
const String REVENUE_CAT_OFFERINGS_ID = 'Subscriptions';

/// DATABASE FIELDS FOR USER COLLECTION  ///
///
const String USER_ID = 'user_id';
const String USER_PROFILE_PHOTO = 'user_photo_link';
const String USER_FULLNAME = 'user_fullname';
const String USER_GENDER = 'user_gender';
const String USER_BIRTH_DAY = 'user_birth_day';
const String USER_BIRTH_MONTH = 'user_birth_month';
const String USER_BIRTH_YEAR = 'user_birth_year';
const String USER_SCHOOL = 'user_school';
const String USER_JOB_TITLE = 'user_job_title';
const String USER_BIO = 'user_bio';
const String USER_PHONE_NUMBER = 'user_phone_number';
const String USER_EMAIL = 'user_email';
const String USER_GALLERY = 'user_gallery';
const String USER_VIDEOS = 'user_videos'; // mapa: video_{i}: { url, thumbnailUrl, createdAt }
const String USER_COUNTRY = 'user_country';
const String USER_LOCALITY = 'user_locality';
const String USER_STATE = 'user_state'; // Novo campo para estado
const String USER_GEO_POINT = 'user_geo_point';
const String USER_SETTINGS = 'user_settings';
const String USER_STATUS = 'user_status';
const String USER_IS_VERIFIED = 'user_is_verified';
const String USER_LEVEL = 'user_level';
const String USER_REG_DATE = 'user_reg_date';
const String USER_LAST_LOGIN = 'user_last_login';
const String USER_DEVICE_TOKEN = 'user_device_token';
const String USER_TOTAL_LIKES = 'user_total_likes';
const String USER_TOTAL_VISITS = 'profile_visits_count'; // ✅ Migrado de user_total_visits
const String USER_ROLE = 'user_role';
// Social fields (novos)
const String USER_WEBSITE = 'user_website';
const String USER_INSTAGRAM = 'user_instagram';
const String USER_TIKTOK = 'user_tiktok';
const String USER_YOUTUBE = 'user_youtube';
// New social fields
const String USER_PINTEREST = 'user_pinterest';
const String USER_VIMEO = 'user_vimeo';
// Pricing fields
const String USER_STARTING_PRICE = 'user_starting_price'; // double
const String USER_AVERAGE_PRICE = 'user_average_price'; // double
// Advanced filters for vendors
const String USER_VENDOR_ADVANCED_FILTERS = 'vendor_advanced_filters'; // Map<String, dynamic>
const String ROLE_BRIDE = 'bride'; // Role Bride (antiga provider)
const String ROLE_VENDOR = 'vendor'; // Role Vendor (antigo user comum)



// === WEDDING PLATFORM FILTER CONSTANTS ===
// Gêneros para filtros
const String GENDER_MAN = 'Male';
const String GENDER_WOMAN = 'Female';
const String GENDER_OTHER = 'Other';
const String GENDER_ALL = 'All';
const String GENDER_NOT_SPECIFIED = 'not_specified';

// NOTE: Service categories are defined in glimpse_variables.dart as:
// - interestListDisplay (with emojis for UI)
// - interestListStorage (without emojis for Firestore)
// Use interestToStorage() and interestToDisplay() helper functions

// Campos específicos do wedding platform
const String USER_WEDDING_DATE = 'user_wedding_date';
const String USER_WEDDING_LOCATION = 'user_wedding_location';
const String USER_BUDGET = 'user_budget';
const String USER_SERVICES_OFFERED = 'user_services_offered';
const String USER_OFFERS = 'user_offers';
const String USER_SERVICE_CATEGORIES = 'user_service_categories';

// User Setting map - fields
const String USER_MIN_AGE = 'user_min_age';
const String USER_MAX_AGE = 'user_max_age';
const String USER_MAX_DISTANCE = 'user_max_distance';
const String USER_SHOW_ME = 'user_show_me';



/// DATABASE FIELDS FOR Messages and Conversations COLLECTION ///
///
const String MESSAGE_TEXT = 'message_text';
const String MESSAGE_TYPE = 'message_type';
const String MESSAGE_IMG_LINK = 'message_img_link';
const String MESSAGE_READ = 'message_read';
const String LAST_MESSAGE = 'last_message';

/// DATABASE FIELDS FOR Notifications COLLECTION ///
///
const N_SENDER_ID = 'n_sender_id';
const N_SENDER_FULLNAME = 'n_sender_fullname';
const N_SENDER_PHOTO_LINK = 'n_sender_photo_link';
const N_RECEIVER_ID = 'n_receiver_id';
const N_TYPE = 'n_type'; // Semantic event type (e.g., 'like', 'visit', 'application_submitted')
const N_PARAMS = 'n_params'; // [NEW] Event parameters for translation interpolation
const N_METADATA = 'n_metadata'; // [NEW] Additional metadata (alias for n_params for backward compatibility)
const N_READ = 'n_read';
const N_RELATED_ID = 'n_related_id'; // [NEW] ID relacionado ao evento (announcement_id, message_id, etc.)

/// NOTIFICATION TYPES - Tipos semânticos para notificações
///
const String NOTIF_TYPE_LIKE = 'like';
const String NOTIF_TYPE_VISIT = 'visit';
const String NOTIF_TYPE_MATCH = 'match';
const String NOTIF_TYPE_MESSAGE = 'message';
const String NOTIF_TYPE_ALERT = 'alert';
const String NOTIF_TYPE_APPLICATION_SUBMITTED = 'application_submitted';
const String NOTIF_TYPE_APPLICATION_ACCEPTED = 'application_accepted';
const String NOTIF_TYPE_APPLICATION_REJECTED = 'application_rejected';
const String NOTIF_TYPE_APPLICATION_UPDATED = 'application_updated';
const String NOTIF_TYPE_NEW_ANNOUNCEMENT = 'new_announcement';
const String NOTIF_TYPE_ANNOUNCEMENT_UPDATED = 'announcement_updated';

/// DATABASE FIELDS FOR Likes COLLECTION
///
const String LIKED_USER_ID = 'liked_user_id';
const String LIKED_BY_USER_ID = 'liked_by_user_id';

/// DATABASE FIELDS FOR Visits COLLECTION
///
const String VISITED_USER_ID = 'visited_user_id';
const String VISITED_BY_USER_ID = 'visited_by_user_id';

/// DATABASE FIELDS FOR [BlockedUsers] (NEW) COLLECTION
///
const String BLOCKED_USER_ID = 'blocked_user_id';
const String BLOCKED_BY_USER_ID = 'blocked_by_user_id';

/// DATABASE SHARED FIELDS FOR COLLECTION
///
const String TIMESTAMP = 'timestamp';

/// FEATURE FLAGS / ACCESS GATES
///
/// When false, notifications that would normally require VIP (like/visit direct profile access)
/// will be accessible without subscription, following the VIP path by default.
/// Set to true to re-enable the subscription requirement for those notification actions.
const bool NOTIFICATIONS_REQUIRE_VIP_SUBSCRIPTION = true; // Global (mantido para notificações / outras áreas)

/// FEATURE FLAG: controla se o chat exige assinatura VIP para visualizar e abrir conversas.
/// Setar para false desativa mascaramento e bloqueio de abertura.
const bool CHAT_VIP_GATING_ENABLED = false; // Facilmente reativável

/// FEATURE FLAG: controla se o drawer de pagamento de taxa (Application Accepted) é exibido antes de acessar conversas com fee_lock.
/// Quando true: exibe o drawer de pagamento e bloqueia acesso até o pagamento ser confirmado
/// Quando false: permite acesso direto às conversas sem exibir o drawer (útil para testes ou clientes sem cobrança)
const bool APPLICATION_FEE_DRAWER_ENABLED = true;



/// Dedicated flag for the VIP-gated targeted announcement notification
/// When true, vendors must be VIP to open the targeted_announcement payload directly.
/// When false, it opens directly regardless of VIP.
const bool TARGETED_ANNOUNCEMENT_REQUIRE_VIP_SUBSCRIPTION = true;



// ==== APPLICATION FEE PRODUCTS (RevenueCat) ====
// Mapeamento direto de budgetRange para Product ID do RevenueCat
// Esses produtos devem estar configurados no RevenueCat Dashboard




/// === DISTANCE UNIT TOGGLE ===
/// When true distances are displayed in miles (mi); when false in kilometers (km).
const bool USE_MILES = true; // Toggle here

/// Precomputed mile -> km conversions for exact UI limits (avoid floating drift)
const double kMi100InKm = 160.934; // 100 miles in km
const double kMi200InKm = 321.868; // 200 miles in km
