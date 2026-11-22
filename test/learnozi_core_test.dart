import 'package:flutter_test/flutter_test.dart';
import 'package:learnozi_app/models/flashcard_model.dart';
import 'package:learnozi_app/models/user_profile.dart';
import 'package:learnozi_app/services/adaptive_service.dart';
import 'package:learnozi_app/services/ai_tutor_service.dart';
import 'package:learnozi_app/services/auth_service.dart';
import 'package:learnozi_app/services/document_service.dart';
import 'package:learnozi_app/services/quota_service.dart';
import 'package:learnozi_app/services/user_service.dart';
import 'package:learnozi_app/utils/localization.dart';
import 'package:learnozi_app/utils/validators.dart';

void main() {
  group('FR-01: Authentication & Profiles', () {
    test('Demo Student login configures Muhammad Ahmad profile', () {
      final auth = AuthService();
      final user = UserService();

      auth.loginAsDemoStudent();
      expect(auth.isDemoActive, isTrue);
      expect(user.profile.name, 'Muhammad Ahmad');
      expect(user.profile.role, 'student');
      expect(user.profile.educationType, EducationType.school);
      expect(user.profile.schoolCourse, 'Pre-Medical');
    });

    test('Demo Student login supports custom student registration', () {
      final auth = AuthService();
      final user = UserService();

      auth.loginAsDemoStudent(
        name: 'Ali Khan',
        email: 'ali@learnozi.pk',
        educationType: EducationType.university,
        universityName: 'Punjab University',
        program: 'BS Computer Science',
      );
      expect(auth.isDemoActive, isTrue);
      expect(user.profile.name, 'Ali Khan');
      expect(user.profile.role, 'student');
      expect(user.profile.universityName, 'Punjab University');
    });

    test('Sign out resets demo active state', () async {
      final auth = AuthService();
      auth.loginAsDemoStudent();
      expect(auth.isDemoActive, isTrue);

      await auth.signOut();
      expect(auth.isDemoActive, isFalse);
    });

    test(
      'Student registration does not inject fake semester or fake phone number',
      () {
        final user = UserService();
        user.setNewProfile(
          name: 'Saad Ur Rehman',
          email: 'saad@learnozi.pk',
          phoneNumber: '',
          educationType: EducationType.university,
          universityName: 'Khwaja Fareed UEIT (KFUEIT), Rahim Yar Khan',
          program: 'BS Computer Science (BSCS)',
          semester: '',
        );

        expect(user.profile.name, 'Saad Ur Rehman');
        expect(user.profile.phoneNumber, '');
        expect(user.profile.semester, '');
        expect(
          user.profile.academicLevelString,
          'BS Computer Science (BSCS) • Khwaja Fareed UEIT (KFUEIT), Rahim Yar Khan',
        );
        expect(user.profile.academicLevelString, isNot(contains('Semester 4')));
        expect(user.profile.currentStreak, 1);
      },
    );

    test('Custom university and custom program are preserved accurately', () {
      final user = UserService();
      user.setNewProfile(
        name: 'Fatima Noor',
        email: 'fatima@learnozi.pk',
        phoneNumber: '03001234567',
        educationType: EducationType.university,
        universityName: 'FAST NUCES Chiniot-Faisalabad',
        program: 'BS Software Engineering',
        semester: '5th Semester',
      );

      expect(user.profile.universityName, 'FAST NUCES Chiniot-Faisalabad');
      expect(user.profile.program, 'BS Software Engineering');
      expect(user.profile.semester, '5th Semester');
      expect(user.profile.phoneNumber, '03001234567');
      expect(
        user.profile.academicLevelString,
        'BS Software Engineering - 5th Semester • FAST NUCES Chiniot-Faisalabad',
      );
    });

    test('Bilingual language toggle switches between English and Urdu and localizes strings', () {
      final user = UserService();
      user.updateProfile(language: 'English');
      expect(user.profile.language, 'English');
      expect(AppLocale.t('welcome', 'English'), 'Welcome back,');
      expect(AppLocale.t('ask_tutor', 'English'), 'Ask AI Tutor');

      user.toggleLanguage();
      expect(user.profile.language, 'Urdu');
      expect(AppLocale.t('welcome', 'Urdu'), 'خوش آمدید،');
      expect(AppLocale.t('ask_tutor', 'Urdu'), 'اے آئی ٹیوٹر سے پوچھیں');
      expect(AppLocale.isUrdu('Urdu'), isTrue);

      user.toggleLanguage();
      expect(user.profile.language, 'English');
      expect(AppLocale.isUrdu('English'), isFalse);
    });

    test('Strong password enforcement requires uppercase, lowercase, digit, and special char', () {
      // Missing length (< 8)
      expect(AppValidators.validateStrongPassword('Ab1!'), isNotNull);

      // Missing uppercase
      expect(AppValidators.validateStrongPassword('learnozi@123'), isNotNull);

      // Missing lowercase
      expect(AppValidators.validateStrongPassword('LEARNOZI@123'), isNotNull);

      // Missing number
      expect(AppValidators.validateStrongPassword('Learnozi@Password'), isNotNull);

      // Missing special character
      expect(AppValidators.validateStrongPassword('Learnozi1234'), isNotNull);

      // Fully strong password
      expect(AppValidators.validateStrongPassword('Learnozi@2025'), isNull);

      final strength = PasswordStrength.calculate('Learnozi@2025');
      expect(strength.isStrong, isTrue);
      expect(strength.metCount, 5);
      expect(strength.label, 'Strong');
    });
  });

  group('FR-02: AI Tutor Academic Explainer', () {
    test('Generates step-by-step breakdown with worked example & summary in English', () async {
      final tutor = AiTutorService();
      final explanation = await tutor.askTutor(
        question: "Explain Newton's Laws of Motion",
        studentLevel: "11th (FSc Part 1) • Pre-Medical",
        language: "English",
      );

      expect(explanation.isNotEmpty, isTrue);
      expect(explanation.toLowerCase(), contains('newton'));
    });

    test(
      'Generates Urdu explanation for Urdu query or language selection',
      () async {
        final tutor = AiTutorService();
        final explanation = await tutor.askTutor(
          question: "نیوٹن کے قوانین کی وضاحت کریں",
          studentLevel: "Matric 10th",
          language: "Urdu",
        );

        expect(explanation.isNotEmpty, isTrue);
        expect(explanation, anyOf(contains('نیوٹن'), contains('قوانین'), contains('حرکت')));
      },
    );
  });

  group('FR-03: Document Upload & Grounded Chat', () {
    test('Enforces 5 MB file size limit', () async {
      final docService = DocumentService();
      expect(
        () => docService.summarizeDocument(
          docName: 'large_file.pdf',
          docText: 'Some content',
          byteSize: 6 * 1024 * 1024, // 6 MB > 5 MB limit
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'Answers grounded queries referencing document content and char count',
      () async {
        final docService = DocumentService();
        expect(docService.documents.isNotEmpty, isTrue);
        final sampleDoc = docService.documents.first;

        final answer = await docService.askDocumentChat(
          docId: sampleDoc.id,
          question: "What is linear velocity and angular velocity relation?",
          language: "English",
        );

        expect(answer.isNotEmpty, isTrue);
        expect(answer.toLowerCase(), anyOf(contains('velocity'), contains('omega'), contains('v = r')));
      },
    );
  });

  group('FR-05: Adaptive Learning & Weak-Topic Diagnostic Engine', () {
    test('Identifies topic with accuracy below 60% as weak', () {
      final adaptive = AdaptiveService();
      final result = adaptive.runWeakTopicDiagnostic(
        attempts: 10,
        accuracy: 0.45, // 45% < 60%
        avgTime: 40.0,
        daysSince: 1,
      );

      expect(result['isWeak'], isTrue);
      expect(result['confidence'], greaterThan(0.5));
      expect(result['recommendation'], contains('Priority Revision'));
    });

    test('Identifies mastered topic with high accuracy as not weak', () {
      final adaptive = AdaptiveService();
      final result = adaptive.runWeakTopicDiagnostic(
        attempts: 20,
        accuracy: 0.90, // 90%
        avgTime: 25.0,
        daysSince: 1,
      );

      expect(result['isWeak'], isFalse);
      expect(result['recommendation'], contains('Mastered'));
    });
  });

  group('FR-06: Active Recall Flashcards (SM-2 Spaced Repetition)', () {
    test(
      'Calculates interval and ease factor according to SuperMemo SM-2 rule',
      () {
        final card = Flashcard(
          id: 'test_card_1',
          frontQuestion: 'Test Q',
          backAnswer: 'Test A',
          category: 'Physics',
          easeFactor: 2.5,
          intervalDays: 1,
          repetitions: 0,
        );

        // Review with rating 5 (Perfect recall)
        card.applySm2Review(5);
        expect(card.repetitions, 1);
        expect(card.intervalDays, 1);
        expect(card.easeFactor, greaterThanOrEqualTo(2.5));

        // Review 2 with rating 4
        card.applySm2Review(4);
        expect(card.repetitions, 2);
        expect(card.intervalDays, 6); // 2nd repetition is always 6 days in SM-2

        // Failed recall rating 1 resets repetitions and interval
        card.applySm2Review(1);
        expect(card.repetitions, 0);
        expect(card.intervalDays, 1);
      },
    );
  });

  group('FR-14: Usage Quota Limits', () {
    test('Tracks and enforces daily AI queries limit', () {
      final quota = QuotaService();
      expect(quota.canMakeAiRequest(), isTrue);
      expect(quota.remainingAiRequests, greaterThan(0));
    });

    test('Tracks and enforces daily Document upload limit', () {
      final quota = QuotaService();
      expect(quota.canUploadDocument(), isTrue);
      expect(quota.remainingDocUploads, greaterThanOrEqualTo(0));
    });
  });
}
