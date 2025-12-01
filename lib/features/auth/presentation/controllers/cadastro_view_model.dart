import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// ViewModel para gerenciar o fluxo de cadastro
/// TODO: Implementar lógica completa
class CadastroViewModel extends ChangeNotifier {
  // Profile
  dynamic imageFile;
  String fullName = '';
  
  // Birth date
  DateTime? birthDate;
  int? userBirthDay;
  int? userBirthMonth;
  int? userBirthYear;
  int? age; // Idade calculada
  
  // Additional info
  String selectedGender = '';
  String interests = ''; // Categorias de atividades selecionadas
  String bio = '';
  String instagram = '';
  String jobTitle = '';
  String? country;
  
  // Origin
  String? originSource;
  
  // Terms
  bool agreeTerms = false;
  
  void resetData() {
    imageFile = null;
    fullName = '';
    birthDate = null;
    age = null;
    selectedGender = '';
    interests = '';
    bio = '';
    instagram = '';
    jobTitle = '';
    country = null;
    originSource = null;
    agreeTerms = false;
    notifyListeners();
  }
  
  void setImageFile(dynamic file) {
    imageFile = file;
    notifyListeners();
  }
  
  void setFullName(String name) {
    fullName = name;
    notifyListeners();
  }
  
  void setBirthDate(DateTime date) {
    birthDate = date;
    userBirthDay = date.day;
    userBirthMonth = date.month;
    userBirthYear = date.year;
    age = _calculateAge(date); // Calcula idade automaticamente
    notifyListeners();
  }
  
  /// Calcula a idade baseada na data de nascimento
  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int calculatedAge = now.year - birthDate.year;
    
    // Ajusta se ainda não fez aniversário este ano
    if (now.month < birthDate.month || 
        (now.month == birthDate.month && now.day < birthDate.day)) {
      calculatedAge--;
    }
    
    return calculatedAge;
  }
  
  bool isUserOldEnough() {
    if (birthDate == null) return false;
    return (age ?? 0) >= 18;
  }
  
  void setInterests(String selectedInterests) {
    interests = selectedInterests;
    notifyListeners();
  }
  
  void setBio(String text) {
    bio = text;
    notifyListeners();
  }
  
  void setInstagram(String username) {
    instagram = username;
    notifyListeners();
  }
  
  void setJobTitle(String title) {
    jobTitle = title;
    notifyListeners();
  }
  
  void setGender(String gender) {
    selectedGender = gender;
    notifyListeners();
  }
  
  void setCountry(String? countryCode) {
    country = countryCode;
    notifyListeners();
  }
  
  void setOriginSource(String? source) {
    originSource = source;
    notifyListeners();
  }
  
  
  void setAgreeTerms(bool value) {
    agreeTerms = value;
    notifyListeners();
  }
  
  void createAccount({
    required Map<String, dynamic> onboardingData,
    required VoidCallback onSuccess,
    required Function(dynamic) onFail,
  }) async {
    const tag = 'CadastroViewModel';
    
    try {
      AppLogger.info('Creating user account...', tag: tag);
      
      // Verifica se o usuário está autenticado
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado');
      }
      
      final userId = currentUser.uid;
      final firestore = FirebaseFirestore.instance;
      
      // Processa os interesses (separados por vírgula) em lista
      final interestsString = onboardingData['interests'] as String? ?? '';
      final interestsList = interestsString.isNotEmpty
          ? interestsString.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : <String>[];
      
      AppLogger.info('User interests: $interestsList (${interestsList.length} items)', tag: tag);
      
      // Prepara os dados do usuário para salvar no Firestore
      final userData = <String, dynamic>{
        'userId': userId,
        'fullName': onboardingData['fullName'],
        'userType': onboardingData['userType'], // vendor
        
        // Birth date
        'birthDay': onboardingData['birthDay'],
        'birthMonth': onboardingData['birthMonth'],
        'birthYear': onboardingData['birthYear'],
        'age': onboardingData['age'],
        
        // New fields
        'instagram': onboardingData['instagram'],
        'jobTitle': onboardingData['jobTitle'],
        'gender': onboardingData['gender'],
        'bio': onboardingData['bio'],
        'country': onboardingData['country'],
        
        // Interests (até 6 atividades como array)
        'interests': interestsList,
        
        // Terms
        'agreeTerms': onboardingData['agreeTerms'],
        
        // Metadata
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'isBlocked': false,
      };
      
      AppLogger.info('Saving user data to Firestore...', tag: tag);
      
      // Salva no Firestore
      await firestore
          .collection('Users')
          .doc(userId)
          .set(userData, SetOptions(merge: true));
      
      AppLogger.success('User account created successfully', tag: tag);
      onSuccess();
      
    } catch (e) {
      AppLogger.error('Failed to create account: $e', tag: tag);
      onFail(e.toString());
    }
  }
}
