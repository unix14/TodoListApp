import 'package:flutter_example/common/consts.dart';
import 'package:flutter_example/models/shared_list_config.dart';
import 'package:flutter_example/models/todo_list_item.dart';
import 'package:flutter_example/models/user.dart' as AppUser;
import 'package:flutter_example/repo/firebase_realtime_database_repository.dart';
import 'package:flutter_example/repo/firebase_repo_interactor.dart';
import 'package:flutter_test/flutter_test.dart';

// --- Manual Mocks ---

class MockFirebaseRealtimeDatabaseRepository extends FirebaseRealtimeDatabaseRepository {
  MockFirebaseRealtimeDatabaseRepository() : super.internal(); // Assuming a protected constructor

  // Map to store expected data for getData calls
  Map<String, Map<String, dynamic>> mockData = {};
  // Map to track saved data for verification
  Map<String, Map<String, dynamic>> savedData = {};
  // Queue for getNewKey results
  List<String> newKeyQueue = [];

  void expectGetData(String path, String child, Map<String, dynamic> data) {
    mockData["$path/$child"] = data;
  }

  void expectGetDataFullPath(String fullPath, Map<String, dynamic> data) {
    mockData[fullPath] = data;
  }

  void expectGetNewKey(String key) {
    newKeyQueue.add(key);
  }

  @override
  Future<Map<String, dynamic>> getData(String path, String child, {bool isFullPath = false}) async {
    String key = isFullPath ? path : "$path/$child";
    print("MockFirebase: getData called for key: $key. Returning: ${mockData[key]}");
    return Future.value(mockData[key] ?? {});
  }

  @override
  Future<bool> saveData(String path, Map<String, dynamic>? data, {String? child, bool isFullPath = false}) async {
    String key = isFullPath ? path : (child != null ? "$path/$child" : path);
     print("MockFirebase: saveData called for key: $key with data: $data");
    if (data == null) { // Simulate deletion
      savedData.remove(key);
    } else {
      savedData[key] = data;
    }
    return Future.value(true);
  }

  @override
  String getNewKey({required String basePath}) {
    if (newKeyQueue.isNotEmpty) {
      return newKeyQueue.removeAt(0);
    }
    return "mock_new_key_${DateTime.now().millisecondsSinceEpoch}";
  }

  // getStream is harder to mock simply without a library like mockito or rxdart for behavior.
  // For now, it will return an empty stream or throw if not overridden in a specific test setup.
  @override
  Stream<dynamic> getStream(String path, {bool isFullPath = false}) {
    // This would need a StreamController that tests can push events to.
    // For basic unit tests of other methods, this might not be called.
    print("MockFirebase: getStream called for path: $path. Returning empty stream.");
    return Stream.value({}); // Or Stream.empty()
  }

  void clearData() {
    mockData.clear();
    savedData.clear();
    newKeyQueue.clear();
  }
}

void main() {
  group('FirebaseRepoInteractor Tests', () {
    late FirebaseRepoInteractor interactor;
    late MockFirebaseRealtimeDatabaseRepository mockDbRepo;

    setUp(() {
      // Create a new mock instance for each test
      mockDbRepo = MockFirebaseRealtimeDatabaseRepository();
      // This is tricky: FirebaseRepoInteractor uses a singleton `instance`.
      // For proper unit testing, the dependency should be injectable.
      // Workaround: Assuming we can replace the internal repo instance for testing,
      // or that FirebaseRepoInteractor is modified to allow injection.
      // For this example, I'll assume a hypothetical setter or test-specific constructor.
      // If FirebaseRepoInteractor.instance cannot be easily controlled, these tests would be
      // integration tests or require more complex setup (like using get_it and replacing bindings).

      // Let's assume FirebaseRepoInteractor is refactored to take the repo in constructor for tests:
      // interactor = FirebaseRepoInteractor(firebaseRepo: mockDbRepo);

      // OR, if there's a static way to set the internal instance for testing (less ideal but common):
      // FirebaseRepoInteractor.setTestInstance(mockDbRepo);

      // For now, we can't directly inject. Tests will operate on the real singleton,
      // but its *internal* _firebaseRepo needs to be our mock. This is hard without modifying
      // the singleton's structure or using a DI framework like get_it.
      // The provided FirebaseRealtimeDatabaseRepository also uses a singleton.
      // This makes true unit testing of FirebaseRepoInteractor difficult without refactoring.

      // Given the constraints, these tests will be more like "testing via the singleton",
      // and we'd have to hope the mock setup for FirebaseRealtimeDatabaseRepository.instance
      // is effective, or refactor the singleton access.
      // For the purpose of this exercise, I will proceed as if `interactor` somehow uses `mockDbRepo`.
      // This might involve temporarily modifying `FirebaseRealtimeDatabaseRepository.instance` to return `mockDbRepo`
      // which is not ideal for parallel tests but might work for sequential ones.

      // A better way would be to use a DI framework (like get_it) to provide instances.
      // Then in tests, we can register the mock implementation.
      // For now, I'll write the tests with the assumption that `interactor` is using `mockDbRepo`.
      // This implies `FirebaseRealtimeDatabaseRepository.instance` would need to be `mockDbRepo`
      // which is tricky with final singletons.

      // Let's assume we add a test-only setter to FirebaseRealtimeDatabaseRepository:
      FirebaseRealtimeDatabaseRepository.testInstance = mockDbRepo;
      interactor = FirebaseRepoInteractor.instance; // Now it should use the mockDbRepo via its own singleton.

    });

    tearDown(() {
      mockDbRepo.clearData();
      FirebaseRealtimeDatabaseRepository.testInstance = null; // Clean up static instance
    });

    group('createOrUpdateSharedList', () {
      final String testCategoryId = "cat123";
      final String testCategoryName = "My Test Category";
      final String testAdminUserId = "adminUserUid";
      final String testInitialShortLink = "my-test-link";
      final String normalizedInitialLink = "my-test-link"; // Assuming it's already normalized

      test('Scenario: New List Sharing - Success', () async {
        // Arrange
        // 1. No existing SharedListConfig for this categoryId
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedListConfigs/$testCategoryId", {});
        // 2. Desired short link path is available
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedLinkPaths/$normalizedInitialLink", {});
        // 3. User's personal todos (for migration)
        final userTodos = [
          TodoListItem("Task 1", category: testCategoryName, id: "t1"),
          TodoListItem("Task 2", category: "Other Category", id: "t2"),
          TodoListItem("Task 3", category: testCategoryName, id: "t3"),
        ];
        final appUser = AppUser.User(email: "admin@test.com", imageURL: "", name: "Admin", todoListItems: userTodos);
        mockDbRepo.expectGetDataFullPath("$kDBPathUsers/$testAdminUserId", appUser.toJson());

        // Act
        final resultShortLink = await interactor.createOrUpdateSharedList(
          categoryId: testCategoryId,
          categoryName: testCategoryName,
          adminUserId: testAdminUserId,
          desiredShortLinkPath: testInitialShortLink,
        );

        // Assert
        expect(resultShortLink, normalizedInitialLink);

        // Verify SharedListConfig saved
        final savedConfigData = mockDbRepo.savedData["$kDBPathSharedListConfigs/$testCategoryId"];
        expect(savedConfigData, isNotNull);
        final savedConfig = SharedListConfig.fromJson(savedConfigData!);
        expect(savedConfig.id, testCategoryId);
        expect(savedConfig.originalCategoryName, testCategoryName);
        expect(savedConfig.adminUserId, testAdminUserId);
        expect(savedConfig.shortLinkPath, normalizedInitialLink);
        expect(savedConfig.authorizedUserIds[testAdminUserId], true);

        // Verify link path lookup saved
        final savedLinkPathData = mockDbRepo.savedData["$kDBPathSharedLinkPaths/$normalizedInitialLink"];
        expect(savedLinkPathData, isNotNull);
        expect(savedLinkPathData!['list_id'], testCategoryId);

        // Verify todo migration
        final savedSharedTodosData = mockDbRepo.savedData["$kDBPathSharedTodos/$testCategoryId/$kDBPathSharedTodosItems"];
        expect(savedSharedTodosData, isNotNull);
        expect(savedSharedTodosData!.length, 2); // Only 'Task 1' and 'Task 3'
        expect(savedSharedTodosData['t1'], isNotNull);
        expect(savedSharedTodosData['t3'], isNotNull);
        expect(savedSharedTodosData['t2'], isNull);

        // Verify metadata migration
        final savedMetadata = mockDbRepo.savedData["$kDBPathSharedTodos/$testCategoryId/$kDBPathSharedTodosMetadata"];
        expect(savedMetadata, isNotNull);
        expect(savedMetadata!['adminUserId'], testAdminUserId);
        expect(savedMetadata['originalCategoryName'], testCategoryName);
      });

      test('Scenario: Updating Existing Shared List - Change short link', () async {
        // Arrange
        final existingShortLink = "existing-link";
        final newShortLink = "new-link";
        final normalizedNewLink = "new-link";

        final existingConfig = SharedListConfig(
          id: testCategoryId,
          originalCategoryName: testCategoryName,
          shortLinkPath: existingShortLink,
          adminUserId: testAdminUserId,
          authorizedUserIds: {testAdminUserId: true},
          sharedTimestamp: DateTime.now().subtract(Duration(days: 1)),
        );

        // 1. Return existing config for categoryId
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedListConfigs/$testCategoryId", existingConfig.toJson());
        // 2. New short link path is available
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedLinkPaths/$normalizedNewLink", {});
        // 3. Old short link path exists (to simulate it might need to be cleaned up, though current code doesn't explicitly delete old path lookups on rename)
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedLinkPaths/$existingShortLink", {'list_id': testCategoryId});


        // Act
        final resultShortLink = await interactor.createOrUpdateSharedList(
          categoryId: testCategoryId,
          categoryName: testCategoryName, // Should not change original name
          adminUserId: testAdminUserId,
          desiredShortLinkPath: newShortLink,
        );

        // Assert
        expect(resultShortLink, normalizedNewLink);

        // Verify SharedListConfig updated
        final savedConfigData = mockDbRepo.savedData["$kDBPathSharedListConfigs/$testCategoryId"];
        expect(savedConfigData, isNotNull);
        final savedConfig = SharedListConfig.fromJson(savedConfigData!);
        expect(savedConfig.shortLinkPath, normalizedNewLink); // New path
        expect(savedConfig.id, testCategoryId); // ID and admin should be same
        expect(savedConfig.adminUserId, testAdminUserId);
        expect(savedConfig.sharedTimestamp.isAfter(existingConfig.sharedTimestamp), isTrue); // Timestamp updated

        // Verify new link path lookup saved
        final newLinkPathData = mockDbRepo.savedData["$kDBPathSharedLinkPaths/$normalizedNewLink"];
        expect(newLinkPathData, isNotNull);
        expect(newLinkPathData!['list_id'], testCategoryId);

        // Verify NO todo migration happened (items path should not have been touched)
        expect(mockDbRepo.savedData["$kDBPathSharedTodos/$testCategoryId/$kDBPathSharedTodosItems"], isNull);
        expect(mockDbRepo.savedData["$kDBPathSharedTodos/$testCategoryId/$kDBPathSharedTodosMetadata"], isNull);
      });

      test('Scenario: New List Sharing - Short Link Collision', () async {
        // Arrange
        final desiredPath = "taken-path";
        final normalizedDesiredPath = "taken-path";
        final suffixedPath = "$normalizedDesiredPath-mockSuffix"; // Mock the suffix generation

        mockDbRepo.expectGetDataFullPath("$kDBPathSharedListConfigs/$testCategoryId", {}); // No existing config
        // 1. First desired path is taken
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedLinkPaths/$normalizedDesiredPath", {'list_id': 'someOtherListId'});
        // 2. Path with suffix is available (mocking the random suffix part)
        // The Uuid().v4().substring(0,6) will generate a random suffix. We can't predict it easily.
        // So we check if *any* suffixed path is attempted. For a more deterministic test, Uuid could be injected/mocked.
        // For now, we'll check that a *different* path than the original desired one is saved.
        // And assume the generated one is free.
        mockDbRepo.newKeyQueue.add("t1_shared"); // For todo item id if needed, though not primary focus here.
        mockDbRepo.newKeyQueue.add("t2_shared");

        // For simplicity, we'll assume the first generated suffixed path is free.
        // If `getData` is called for the suffixed path, it should return empty.
        // This part is tricky to test without more control over Uuid or a loop in the SUT.
        // The current SUT only tries one suffix.

        final appUser = AppUser.User(email: "admin@test.com", imageURL: "", name: "Admin", todoListItems: []);
        mockDbRepo.expectGetDataFullPath("$kDBPathUsers/$testAdminUserId", appUser.toJson());


        // Act
        final resultShortLink = await interactor.createOrUpdateSharedList(
          categoryId: testCategoryId,
          categoryName: testCategoryName,
          adminUserId: testAdminUserId,
          desiredShortLinkPath: desiredPath,
        );

        // Assert
        expect(resultShortLink, isNot(normalizedDesiredPath)); // It should have a suffix
        expect(resultShortLink.startsWith(normalizedDesiredPath), isTrue);

        // Verify SharedListConfig saved with the new suffixed path
        final savedConfigData = mockDbRepo.savedData["$kDBPathSharedListConfigs/$testCategoryId"];
        expect(savedConfigData, isNotNull);
        final savedConfig = SharedListConfig.fromJson(savedConfigData!);
        expect(savedConfig.shortLinkPath, resultShortLink);

        // Verify link path lookup saved with the new suffixed path
        final savedLinkPathData = mockDbRepo.savedData["$kDBPathSharedLinkPaths/$resultShortLink"];
        expect(savedLinkPathData, isNotNull);
        expect(savedLinkPathData!['list_id'], testCategoryId);
      });
    });

    group('joinSharedList', () {
      final String testShortLinkPath = "join-this-list";
      final String testListId = "listIdForJoin";
      final String joiningUserId = "joiningUserUid";
      final String adminUserId = "originalAdminUid";

      test('Scenario: User Joins Successfully', () async {
        // Arrange
        final initialConfig = SharedListConfig(
          id: testListId,
          originalCategoryName: "Joinable List",
          shortLinkPath: testShortLinkPath,
          adminUserId: adminUserId,
          authorizedUserIds: {adminUserId: true}, // Only admin initially
          sharedTimestamp: DateTime.now(),
        );
        // Mock getSharedListConfigByPath (which internally calls getData for link path then for config)
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedLinkPaths/$testShortLinkPath", {'list_id': testListId});
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedListConfigs/$testListId", initialConfig.toJson());

        // Act
        final resultConfig = await interactor.joinSharedList(testShortLinkPath, joiningUserId);

        // Assert
        expect(resultConfig, isNotNull);
        expect(resultConfig!.id, testListId);
        expect(resultConfig.authorizedUserIds[joiningUserId], isTrue);
        expect(resultConfig.authorizedUserIds.length, 2); // Admin + new user

        // Verify that the config was saved
        final savedConfigData = mockDbRepo.savedData["$kDBPathSharedListConfigs/$testListId"];
        expect(savedConfigData, isNotNull);
        final savedConfig = SharedListConfig.fromJson(savedConfigData!);
        expect(savedConfig.authorizedUserIds[joiningUserId], isTrue);
      });

      test('Scenario: User Already Authorized', () async {
        // Arrange
        final initialConfig = SharedListConfig(
          id: testListId,
          originalCategoryName: "Joinable List",
          shortLinkPath: testShortLinkPath,
          adminUserId: adminUserId,
          authorizedUserIds: {adminUserId: true, joiningUserId: true}, // User already authorized
          sharedTimestamp: DateTime.now(),
        );
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedLinkPaths/$testShortLinkPath", {'list_id': testListId});
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedListConfigs/$testListId", initialConfig.toJson());

        // Act
        final resultConfig = await interactor.joinSharedList(testShortLinkPath, joiningUserId);

        // Assert
        expect(resultConfig, isNotNull);
        expect(resultConfig!.id, testListId);
        expect(resultConfig.authorizedUserIds[joiningUserId], isTrue);
        expect(resultConfig.authorizedUserIds.length, 2); // Still 2 users
        // Ensure no save operation was called because no change was needed
        expect(mockDbRepo.savedData["$kDBPathSharedListConfigs/$testListId"], isNull);
      });

      test('Scenario: User is Admin (already authorized by definition)', () async {
        // Arrange
        final initialConfig = SharedListConfig(
          id: testListId,
          originalCategoryName: "Joinable List",
          shortLinkPath: testShortLinkPath,
          adminUserId: adminUserId, // joiningUserId is the admin
          authorizedUserIds: {adminUserId: true},
          sharedTimestamp: DateTime.now(),
        );
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedLinkPaths/$testShortLinkPath", {'list_id': testListId});
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedListConfigs/$testListId", initialConfig.toJson());

        // Act
        final resultConfig = await interactor.joinSharedList(testShortLinkPath, adminUserId); // Admin tries to "join"

        // Assert
        expect(resultConfig, isNotNull);
        expect(resultConfig!.adminUserId, adminUserId);
        expect(resultConfig.authorizedUserIds.length, 1);
        // Ensure no save operation was called
        expect(mockDbRepo.savedData["$kDBPathSharedListConfigs/$testListId"], isNull);
      });


      test('Scenario: List Not Found for shortLinkPath', () async {
        // Arrange
        mockDbRepo.expectGetDataFullPath("$kDBPathSharedLinkPaths/$testShortLinkPath", {}); // No list_id found

        // Act
        final resultConfig = await interactor.joinSharedList(testShortLinkPath, joiningUserId);

        // Assert
        expect(resultConfig, isNull);
      });
    });

    group('getUsersDetails', () {
      final String userId1 = "user1";
      final AppUser.User user1Data = AppUser.User(email: "user1@example.com", name: "User One", imageURL: "url1", profilePictureUrl: "picUrl1");
      final String userId2 = "user2";
      final AppUser.User user2Data = AppUser.User(email: "user2@example.com", name: "User Two", imageURL: "url2", profilePictureUrl: "picUrl2");
      final String userId3NotFound = "user3";

      test('Scenario: All users found', () async {
        // Arrange
        mockDbRepo.expectGetDataFullPath("$kDBPathUsers/$userId1", user1Data.toJson());
        mockDbRepo.expectGetDataFullPath("$kDBPathUsers/$userId2", user2Data.toJson());

        // Act
        final results = await interactor.getUsersDetails([userId1, userId2]);

        // Assert
        expect(results.length, 2);
        expect(results.any((u) => u.id == userId1 && u.name == "User One"), isTrue);
        expect(results.any((u) => u.id == userId2 && u.name == "User Two"), isTrue);
      });

      test('Scenario: Some users found, some not', () async {
        // Arrange
        mockDbRepo.expectGetDataFullPath("$kDBPathUsers/$userId1", user1Data.toJson());
        mockDbRepo.expectGetDataFullPath("$kDBPathUsers/$userId3NotFound", {}); // User 3 not found

        // Act
        final results = await interactor.getUsersDetails([userId1, userId3NotFound]);

        // Assert
        expect(results.length, 1); // Only user1 should be returned
        expect(results.first.id, userId1);
        expect(results.first.name, "User One");
      });

      test('Scenario: No users found', () async {
        // Arrange
        mockDbRepo.expectGetDataFullPath("$kDBPathUsers/$userId3NotFound", {});

        // Act
        final results = await interactor.getUsersDetails([userId3NotFound]);

        // Assert
        expect(results.isEmpty, isTrue);
      });

      test('Scenario: Empty input list', () async {
        // Act
        final results = await interactor.getUsersDetails([]);

        // Assert
        expect(results.isEmpty, isTrue);
      });
    });
  });
}

// Note: FirebaseRealtimeDatabaseRepository might need a static setter for its instance for this mocking to work easily.
// e.g., in FirebaseRealtimeDatabaseRepository:
// static FirebaseRealtimeDatabaseRepository? _testInstance;
// static FirebaseRealtimeDatabaseRepository get instance => _testInstance ?? _instance;
// static set testInstance(FirebaseRealtimeDatabaseRepository? repo) => _testInstance = repo;
// And ensure _instance is created like:
// static final FirebaseRealtimeDatabaseRepository _instance = FirebaseRealtimeDatabaseRepository.internal();
// The constructor `FirebaseRealtimeDatabaseRepository()` should be removed or made private,
// and `FirebaseRealtimeDatabaseRepository.internal()` used for the singleton.
// This is a common pattern to allow test injection for singletons.
// I've updated the mock to assume `FirebaseRealtimeDatabaseRepository.internal()` constructor and a static `testInstance` setter.
