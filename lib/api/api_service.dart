import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/models.dart';

// ⚠️  Change this to your backend URL
const String BASE_URL = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://interjectional-kim-gnostically.ngrok-free.dev/',
);
// For real device use your machine's local IP e.g. 'http://192.168.1.x:3000'
// For production use your deployed URL e.g. 'https://api.yourapp.com'

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final _storage = const FlutterSecureStorage();
  late final Dio _dio;

  void init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: BASE_URL,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // Attach both Authorization Bearer AND token header on every request automatically
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['token'] = token;
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            await _storage.delete(key: 'token');
            await _storage.delete(key: 'refreshToken');
          }
          return handler.next(error);
        },
      ),
    );
  }

  /// Builds Options with explicit token header (belt-and-suspenders for each call)
  Future<Options> _opts() async {
    final token = await _storage.read(key: 'token');
    return Options(headers: {'token': token});
  }

  String _msg(dynamic e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        final msg = data['message'];
        if (msg is List) return msg.join(', ');
        if (msg is String) return msg;
      }
    }
    return 'Something went wrong';
  }

  // ─── Auth ─────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      final token =
          res.data['accessToken'] ??
          res.data['access_token'] ??
          res.data['token'];
      final refToken = res.data['refreshToken'];
      if (token != null) await _storage.write(key: 'token', value: token);
      if (refToken != null)
        await _storage.write(key: 'refreshToken', value: refToken);
      return res.data;
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<void> signup(Map<String, dynamic> data) async {
    try {
      await _dio.post('/auth/signup', data: data);
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<void> confirmEmail(String email, String otp) async {
    try {
      await _dio.patch(
        '/auth/confirm-email',
        data: {'email': email, 'otp': otp},
      );
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final res = await _dio.get('/auth/get-profile', options: await _opts());
      return UserModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout', options: await _opts());
    } catch (_) {}
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'refreshToken');
  }

  Future<bool> hasToken() async {
    final t = await _storage.read(key: 'token');
    return t != null && t.isNotEmpty;
  }

  // ─── Shifts ────────────────────────────────────────────

  Future<List<ShiftModel>> getShifts() async {
    try {
      final res = await _dio.get('/shift/', options: await _opts());
      final list = res.data as List? ?? [];
      return list.map((e) => ShiftModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<ShiftModel> createShift(
    String name,
    String fromDate,
    String toDate,
  ) async {
    try {
      final res = await _dio.post(
        '/shift/create',
        data: {'name': name, 'fromDate': fromDate, 'toDate': toDate},
        options: await _opts(),
      );
      return ShiftModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  // ─── People ────────────────────────────────────────────

  Future<List<PersonModel>> getPeople() async {
    try {
      final res = await _dio.get('/person/people', options: await _opts());
      final list = res.data as List? ?? [];
      return list.map((e) => PersonModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<PersonModel> getPerson(String id) async {
    try {
      final res = await _dio.get('/person/$id', options: await _opts());
      return PersonModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<PersonModel> createPerson(String name, String title) async {
    try {
      final res = await _dio.post(
        '/person/create',
        data: {'name': name, 'title': title},
        options: await _opts(),
      );
      return PersonModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  // ─── Items ─────────────────────────────────────────────

  Future<List<ItemModel>> getItemsByShift(String shiftId) async {
    try {
      final res = await _dio.get(
        '/item/shift-items/$shiftId',
        options: await _opts(),
      );
      final list = res.data as List? ?? [];
      return list.map((e) => ItemModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<List<ItemModel>> getItemsByShiftAndPerson(
    String shiftId,
    String personId,
  ) async {
    try {
      final res = await _dio.get(
        '/item/shift-person-items',
        queryParameters: {'shiftId': shiftId, 'personId': personId},
        options: await _opts(),
      );
      final list = res.data as List? ?? [];
      return list.map((e) => ItemModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<ItemModel> createItem(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        '/item/create',
        data: data,
        options: await _opts(),
      );
      return ItemModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<ItemModel> updateItem(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch(
        '/item/update/$id',
        data: data,
        options: await _opts(),
      );
      return ItemModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  // ─── Transactions ──────────────────────────────────────

  Future<List<TransactionModel>> getTransactionsByShift(String shiftId) async {
    try {
      final res = await _dio.get(
        '/transaction/shift-transactions/$shiftId',
        options: await _opts(),
      );
      final list = res.data as List? ?? [];
      return list.map((e) => TransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<List<TransactionModel>> getTransactionsByPerson(
    String personId,
  ) async {
    try {
      final res = await _dio.get(
        '/transaction/person-transactions/$personId',
        options: await _opts(),
      );
      final list = res.data as List? ?? [];
      return list.map((e) => TransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<List<TransactionModel>> getTransactionsByShiftAndPerson(
    String shiftId,
    String personId,
  ) async {
    try {
      final res = await _dio.get(
        '/transaction/shift-person-transactions',
        queryParameters: {'shiftId': shiftId, 'personId': personId},
        options: await _opts(),
      );
      final list = res.data as List? ?? [];
      return list.map((e) => TransactionModel.fromJson(e)).toList();
    } on DioException catch (e) {
      throw _msg(e);
    }
  }

  Future<TransactionModel> recordPayment(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post(
        '/transaction/gave-me',
        data: data,
        options: await _opts(),
      );
      return TransactionModel.fromJson(res.data);
    } on DioException catch (e) {
      throw _msg(e);
    }
  }
}
