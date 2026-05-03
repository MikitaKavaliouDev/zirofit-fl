import 'package:flutter_test/flutter_test.dart';
import 'package:zirofit_fl/data/models/support_ticket.dart';
import 'package:zirofit_fl/data/models/enums/support_ticket_category.dart';

void main() {
  group('SupportTicket', () {
    final json = {
      'id': 'ticket-1',
      'user_id': 'user-1',
      'category': 'BUG_REPORT',
      'message': 'App crashes on login',
      'app_version': '1.2.3',
      'os_version': 'iOS 17.0',
      'status': 'OPEN',
      'created_at': 1700000000000,
      'updated_at': 1700000100000,
    };

    test('fromJson parses all fields', () {
      final ticket = SupportTicket.fromJson(json);

      expect(ticket.id, 'ticket-1');
      expect(ticket.userId, 'user-1');
      expect(ticket.category, SupportTicketCategory.bugReport);
      expect(ticket.message, 'App crashes on login');
      expect(ticket.appVersion, '1.2.3');
      expect(ticket.osVersion, 'iOS 17.0');
      expect(ticket.status, 'OPEN');
      expect(ticket.createdAt, DateTime.fromMillisecondsSinceEpoch(1700000000000));
      expect(ticket.updatedAt, DateTime.fromMillisecondsSinceEpoch(1700000100000));
    });

    test('toJson roundtrip', () {
      final ticket = SupportTicket.fromJson(json);
      final output = ticket.toJson();

      expect(output['id'], 'ticket-1');
      expect(output['user_id'], 'user-1');
      expect(output['category'], 'BUG_REPORT');
      expect(output['message'], 'App crashes on login');
      expect(output['app_version'], '1.2.3');
      expect(output['os_version'], 'iOS 17.0');
      expect(output['status'], 'OPEN');
      expect(output['created_at'], 1700000000000);
      expect(output['updated_at'], 1700000100000);
    });

    test('fromJson handles null optionals', () {
      final minimal = {
        'id': 'ticket-2',
        'user_id': 'user-2',
        'category': 'FEATURE_REQUEST',
        'message': 'Add dark mode',
        'created_at': 1700000000000,
        'updated_at': 1700000100000,
      };

      final ticket = SupportTicket.fromJson(minimal);

      expect(ticket.id, 'ticket-2');
      expect(ticket.appVersion, isNull);
      expect(ticket.osVersion, isNull);
      expect(ticket.status, 'OPEN');
    });

    test('equality', () {
      final a = SupportTicket.fromJson(json);
      final b = SupportTicket.fromJson(json);

      expect(a, equals(b));
    });

    test('hashCode', () {
      final a = SupportTicket.fromJson(json);
      final b = SupportTicket.fromJson(json);

      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
