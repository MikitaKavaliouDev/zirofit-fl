/// Factory for generating test Client JSON payloads.
///
/// All JSON keys use snake_case to match the backend wire format.
class ClientFixture {
  static Map<String, dynamic> createJson({
    String id = 'test-client-id',
    String name = 'Test Client',
    String email = 'client@test.com',
    String phone = '+1234567890',
    String status = 'active',
    String trainerId = 'test-trainer-id',
    int createdAt = 1700000000000,
    int updatedAt = 1700000000000,
  }) =>
      {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'status': status,
        'trainer_id': trainerId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
