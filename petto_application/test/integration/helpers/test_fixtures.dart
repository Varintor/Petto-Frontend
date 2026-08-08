/// Test fixtures for integration tests
///
/// Test data follows UTC (Unit Test) Test Data specifications from Test Record v1.0.0
library;

/// Authentication test fixtures (from UTC-01, UTC-02, STC-01, STC-02)
class AuthFixtures {
  // Valid test data
  static const String validEmail = 'jamal.j@gmail.com';
  static const String validPassword = 'Password123!';
  static const String validName = 'Jamal Johnson';
  static const String validToken = 'test-access-token-123';

  // Invalid test data
  static const String weakPassword = 'pass';
  static const String wrongPassword = 'wrongpassword';
  static const String invalidEmail = 'jamal.com';
  static const String duplicateEmail = 'existing.user@gmail.com';
  static const String unregisteredEmail = 'notregistered@gmail.com';

  // Success response (like UTC-01-TC-01, UTC-02-TC-01)
  static Map<String, dynamic> successRegisterResponse() => {
    'access_token': validToken,
    'token_type': 'bearer',
    'user': {'id': 1, 'email': validEmail, 'name': validName},
  };

  static Map<String, dynamic> successLoginResponse() => {
    'access_token': validToken,
    'token_type': 'bearer',
    'user': {'id': 1, 'email': validEmail, 'name': validName},
  };

  // Error response (like UTC-01-TC-02, UTC-02-TC-02)
  static Map<String, dynamic> duplicateEmailErrorResponse() => {
    'detail': 'Email already registered',
  };

  static Map<String, dynamic> invalidCredentialsErrorResponse() => {
    'detail': 'Invalid email or password',
  };

  // Me endpoint response (for token validation)
  static Map<String, dynamic> successMeResponse() => {
    'id': 1,
    'email': validEmail,
    'name': validName,
  };
}

/// Pet management test fixtures (from UTC-03, UTC-04, STC-03)
class PetFixtures {
  static const int validUserId = 1;
  static const int validPetId = 1;
  static const String validName = 'Buddy';
  static const String validSpecies = 'Dog';
  static const String validBreed = 'Golden Retriever';
  static const double validWeight = 12.5;
  static const String validGender = 'Male';

  // Valid pet JSON (like UTC-03-TC-01)
  static Map<String, dynamic> validPetResponse() => {
    'id': validPetId,
    'user_id': validUserId,
    'name': validName,
    'species': validSpecies,
    'breed': validBreed,
    'weight_kg': validWeight,
    'gender': validGender,
    'date_of_birth': '2020-01-01',
    'blood_type': 'DEA 1.1',
    'avatar_uri': null,
    'created_at': '2026-06-17T10:00:00',
  };

  // Updated pet response (like UTC-04-TC-01)
  static Map<String, dynamic> updatedPetResponse() => {
    'id': validPetId,
    'user_id': validUserId,
    'name': 'Max',
    'species': validSpecies,
    'breed': validBreed,
    'weight_kg': 10.5,
    'gender': validGender,
    'date_of_birth': '2020-01-01',
    'blood_type': 'DEA 1.1',
    'avatar_uri': null,
    'created_at': '2026-06-17T10:00:00',
  };

  // Multiple pets response
  static List<Map<String, dynamic>> multiplePetsResponse() => [
    validPetResponse(),
    {
      'id': 2,
      'user_id': validUserId,
      'name': 'Milo',
      'species': 'Cat',
      'breed': 'Siamese',
      'weight_kg': 4.5,
      'gender': 'Male',
      'date_of_birth': '2021-05-15',
      'blood_type': 'DEA 1.1',
      'avatar_uri': null,
      'created_at': '2026-06-16T14:30:00',
    },
  ];

  // Error responses
  static Map<String, dynamic> petNotFoundErrorResponse() => {
    'detail': 'Pet not found',
  };
}

/// Health assessment test fixtures (from UTC-05, STC-04)
class AssessmentFixtures {
  static const int validPetId = 1;
  static const int validAssessmentId = 1;
  static const String validSymptoms = 'Lethargic, loss of appetite';
  static const String moderateRisk = 'Moderate Risk';
  static const String highRisk = 'High Risk';
  static const String lowRisk = 'Low Risk';
  static const String aiUnavailable = 'AI service unavailable';

  // Success response with AI analysis
  static Map<String, dynamic> successAssessmentResponse() => {
    'id': validAssessmentId,
    'pet_id': validPetId,
    'symptom_description': validSymptoms,
    'image_uri': 'https://storage.test/symptom.jpg',
    'risk_level': highRisk,
    'ai_raw_response': 'See a vet within 24 hours.',
    'status': 'completed',
    'error_code': null,
    'created_at': '2026-06-17T14:20:00',
  };

  // AI unavailable response (like UTC-05-TC-01)
  static Map<String, dynamic> aiUnavailableResponse() => {
    'id': validAssessmentId,
    'pet_id': validPetId,
    'symptom_description': 'Limping on front paw',
    'image_uri': 'https://storage.test/paw.jpg',
    'risk_level': null,
    'ai_raw_response': null,
    'status': 'failed',
    'error_code': 'AI_SERVICE_UNAVAILABLE',
    'created_at': '2026-07-05T09:00:00',
  };

  // Assessment history response
  static List<Map<String, dynamic>> assessmentHistoryResponse() => [
    successAssessmentResponse(),
    {
      'id': 2,
      'pet_id': validPetId,
      'symptom_description': 'Vomiting',
      'image_uri': 'https://storage.test/vomit.jpg',
      'risk_level': highRisk,
      'ai_raw_response': 'Could be serious, see vet soon.',
      'status': 'completed',
      'error_code': null,
      'created_at': '2026-06-18T10:30:00',
    },
  ];

  // Error response for non-image file (like UTC-05-TC-02)
  static Map<String, dynamic> invalidFileErrorResponse() => {
    'detail': 'File must be an image',
  };
}

/// Activity tracking test fixtures (from UTC-07, STC-05)
class ActivityFixtures {
  static const int validPetId = 1;
  static const int validActivityId = 1;
  static const String walkingType = 'walking';
  static const String runningType = 'running';
  static const double validDuration = 20.0;
  static const double validDistance = 1500.0;
  static const double validCalories = 15.0;

  // Success activity response (like UTC-07-TC-01)
  static Map<String, dynamic> successActivityResponse() => {
    'id': validActivityId,
    'pet_id': validPetId,
    'mission_id': null,
    'source': 'phone',
    'activity_type': walkingType,
    'duration_minutes': validDuration,
    'distance_meters': validDistance,
    'calories_burned': validCalories,
    'avg_speed_kmh': 4.5,
    'max_speed_kmh': 6.0,
    'steps': 2000,
    'is_mission_completed': true,
    'started_at': '2026-06-17T08:00:00',
    'ended_at': '2026-06-17T08:20:00',
    'created_at': '2026-06-17T08:20:00',
  };

  // Short walk response (like UTC-07-TC-03)
  static Map<String, dynamic> shortWalkResponse() => {
    'id': 2,
    'pet_id': validPetId,
    'mission_id': null,
    'source': 'phone',
    'activity_type': walkingType,
    'duration_minutes': 10.0,
    'distance_meters': 750.0,
    'calories_burned': 7.5,
    'avg_speed_kmh': 4.5,
    'max_speed_kmh': 5.5,
    'steps': 1000,
    'is_mission_completed': false,
    'started_at': '2026-06-17T09:00:00',
    'ended_at': '2026-06-17T09:10:00',
    'created_at': '2026-06-17T09:10:00',
  };

  // Activity stats response (like UTC-08-TC-01)
  static Map<String, dynamic> activityStatsResponse() => {
    'pet_id': validPetId,
    'total_activities': 2,
    'total_duration_minutes': 50.0,
    'total_distance_meters': 3750.0,
    'completed_missions': 1,
  };
}

/// Missions test fixtures (from UTC-06, STC-05)
class MissionFixtures {
  static const int validPetId = 1;
  static const int validMissionId = 1;

  // Mission types
  static const String walkType = 'walk';
  static const String waterType = 'water';
  static const String aiCheckType = 'ai_check';

  // Today's missions response (like UTC-06-TC-01)
  static List<Map<String, dynamic>> todayMissionsResponse() => [
    {
      'id': validMissionId,
      'pet_id': validPetId,
      'mission_date': '2026-06-17',
      'mission_type': walkType,
      'title': 'Morning Walk',
      'description': 'Take your pet for a 15-minute walk',
      'target_value': 15.0,
      'unit': 'minutes',
      'is_completed': false,
      'completed_at': null,
      'reward_treats': 10,
      'created_at': '2026-06-17T00:00:00',
    },
    {
      'id': 2,
      'pet_id': validPetId,
      'mission_date': '2026-06-17',
      'mission_type': waterType,
      'title': 'Stay Hydrated',
      'description': 'Ensure fresh water is available',
      'target_value': 1.0,
      'unit': 'times',
      'is_completed': false,
      'completed_at': null,
      'reward_treats': 5,
      'created_at': '2026-06-17T00:00:00',
    },
    {
      'id': 3,
      'pet_id': validPetId,
      'mission_date': '2026-06-17',
      'mission_type': aiCheckType,
      'title': 'Health Check',
      'description': 'Perform an AI health assessment',
      'target_value': 1.0,
      'unit': 'times',
      'is_completed': false,
      'completed_at': null,
      'reward_treats': 15,
      'created_at': '2026-06-17T00:00:00',
    },
    {
      'id': 4,
      'pet_id': validPetId,
      'mission_date': '2026-06-17',
      'mission_type': 'grooming',
      'title': 'Grooming Time',
      'description': 'Brush your pet\'s coat',
      'target_value': 1.0,
      'unit': 'times',
      'is_completed': false,
      'completed_at': null,
      'reward_treats': 5,
      'created_at': '2026-06-17T00:00:00',
    },
    {
      'id': 5,
      'pet_id': validPetId,
      'mission_date': '2026-06-17',
      'mission_type': 'play',
      'title': 'Play Time',
      'description': 'Play with your pet for 10 minutes',
      'target_value': 10.0,
      'unit': 'minutes',
      'is_completed': false,
      'completed_at': null,
      'reward_treats': 8,
      'created_at': '2026-06-17T00:00:00',
    },
  ];

  // Completed mission response (like UTC-06-TC-03)
  static Map<String, dynamic> completedMissionResponse() => {
    'id': validMissionId,
    'pet_id': validPetId,
    'mission_date': '2026-06-17',
    'mission_type': walkType,
    'title': 'Morning Walk',
    'description': 'Take your pet for a 15-minute walk',
    'target_value': 15.0,
    'unit': 'minutes',
    'is_completed': true,
    'completed_at': '2026-06-17T08:20:00',
    'reward_treats': 10,
    'created_at': '2026-06-17T00:00:00',
  };

  // Dashboard stats response (like UTC-08-TC-01, UTC-10-TC-01)
  static Map<String, dynamic> dashboardStatsResponse() => {
    'pet_id': validPetId,
    'health_score': 80,
    'activities_this_month': 7,
    'total_duration_minutes': 150.0,
    'total_distance_meters': 12000.0,
    'missions_completed_this_week': 3,
    'vaccination_status': 'up_to_date',
    'recent_risk_level': 'Low Risk',
  };

  // Empty pet stats response (like UTC-08-TC-02, UTC-10-TC-02)
  static Map<String, dynamic> emptyStatsResponse() => {
    'pet_id': validPetId,
    'health_score': 0,
    'activities_this_month': 0,
    'total_duration_minutes': 0.0,
    'total_distance_meters': 0.0,
    'missions_completed_this_week': 0,
    'vaccination_status': 'no_records',
    'recent_risk_level': null,
  };
}
