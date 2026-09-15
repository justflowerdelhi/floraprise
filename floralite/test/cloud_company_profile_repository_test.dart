import 'package:floraprise/data/repositories/cloud_company_profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('updateCompanyProfile PUTs only the provided fields to the company profile endpoint', () async {
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final repository = CloudCompanyProfileRepository(
      sender: (method, uri, {body}) async {
        requests.add((method: method, uri: uri, body: body));
        return {
          'id': '11111111-1111-4111-8111-111111111111',
          'name': 'Jai Bajrang Bali',
          'phone': '9876500000',
          'email': 'shop@example.com',
          'address': 'Main Bazaar',
          'shortDescription': 'Flower shop',
          'timeZone': 'Asia/Kolkata',
          'currencyCode': 'INR',
          'taxIdentifier': 'GSTIN123',
          'region': 'IN',
          'isActive': true,
          'createdAtUtc': '2026-01-01T00:00:00Z',
        };
      },
    );

    final profile = await repository.updateCompanyProfile(
      baseUrl: 'https://api.test.floraprise.local',
      accessToken: 'token-123',
      name: 'Jai Bajrang Bali',
      phone: '9876500000',
      email: 'shop@example.com',
      address: 'Main Bazaar',
      taxIdentifier: 'GSTIN123',
    );

    expect(requests.single.method, 'PUT');
    expect(requests.single.uri.path, '/api/v1/mobile/company/profile');
    expect(requests.single.body, {
      'name': 'Jai Bajrang Bali',
      'phone': '9876500000',
      'email': 'shop@example.com',
      'address': 'Main Bazaar',
      'taxIdentifier': 'GSTIN123',
    });
    expect(profile.name, 'Jai Bajrang Bali');
    expect(profile.taxIdentifier, 'GSTIN123');
  });

  test('updateCompanyProfile omits fields that were not changed', () async {
    final requests = <({String method, Uri uri, Map<String, dynamic>? body})>[];
    final repository = CloudCompanyProfileRepository(
      sender: (method, uri, {body}) async {
        requests.add((method: method, uri: uri, body: body));
        return {
          'id': '11111111-1111-4111-8111-111111111111',
          'name': 'Existing Name',
          'timeZone': 'UTC',
          'currencyCode': 'USD',
          'region': 'IN',
          'isActive': true,
          'createdAtUtc': '2026-01-01T00:00:00Z',
        };
      },
    );

    await repository.updateCompanyProfile(
      baseUrl: 'https://api.test.floraprise.local',
      accessToken: 'token-123',
      phone: '9999999999',
    );

    expect(requests.single.body, {'phone': '9999999999'});
  });

  test('fetchCompanyProfile uses http.Client and parses response without dart:io HttpClient', () async {
    final client = MockClient((request) async {
      expect(request.method, 'GET');
      expect(request.url.path, '/api/v1/mobile/company/profile');
      expect(request.headers['authorization'], 'Bearer token-abc');
      return http.Response(
        '''
        {
          "id": "11111111-1111-4111-8111-111111111111",
          "name": "Floral Shop Web",
          "phone": "9876543210",
          "timeZone": "Asia/Kolkata",
          "currencyCode": "INR",
          "region": "IN",
          "isActive": true,
          "createdAtUtc": "2026-01-01T00:00:00Z"
        }
        ''',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final repository = CloudCompanyProfileRepository(client: client);
    final profile = await repository.fetchCompanyProfile(
      baseUrl: 'https://api.test.floraprise.local',
      accessToken: 'token-abc',
    );

    expect(profile, isNotNull);
    expect(profile!.name, 'Floral Shop Web');
    expect(profile.phone, '9876543210');
  });
}
