// ignore_for_file: constant_identifier_names

import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:flutter/material.dart';

/// APP SETINGS INFO CONSTANTS - SECTION ///
///
const String APP_NAME = 'WedConnex';
const Color APP_PRIMARY_COLOR = GlimpseColors.primaryColorLight;
const int ANDROID_APP_VERSION_NUMBER = 1; // Google Play Version Number
const int IOS_APP_VERSION_NUMBER = 1; // App Store Version Number

/// FONT FAMILY CONSTANTS
const String FONT_PLUS_JAKARTA_SANS = 'Plus Jakarta Sans';

/// GENDER CONSTANTS
const String GENDER_MAN = 'Male';
const String GENDER_WOMAN = 'Female';
const String GENDER_OTHER = 'Non-Binary';
const String GENDER_ALL = 'All';


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
const String C_NOTIFICATIONS = 'Notifications';
const String C_CONNECTIONS = 'Connections';
const String C_CONVERSATIONS = 'Conversations';
const String C_MESSAGES = 'Messages';
const String C_BLOCKED_USERS = 'BlockedUsers';



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
const String NOTIF_TYPE_MESSAGE = 'message';




/// DATABASE SHARED FIELDS FOR COLLECTION
///
const String TIMESTAMP = 'timestamp';
const String USER_ID = 'user_id';
const String USER_PROFILE_PHOTO = 'user_photo_link';
const String USER_FULLNAME = 'user_fullname';
const String MESSAGE_TYPE = 'message_type';
const String MESSAGE_READ = 'message_read';
const String LAST_MESSAGE = 'last_message';
const String SENDER_ID = 'sender_id';
const String MESSAGE = 'message';
const String IMG_LINK = 'img_link';

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
