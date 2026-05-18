import 'package:clinical_application/core/services/networking/dio_consumer.dart';
import 'package:clinical_application/features/finance/data/models/debt_model.dart';
import 'package:clinical_application/features/finance/data/models/expense_category_model.dart';
import 'package:clinical_application/features/finance/data/models/invoice_model.dart';
import 'package:clinical_application/features/finance/data/models/purchase_line_model.dart';
import 'package:clinical_application/features/finance/data/models/purchase_model.dart';
import 'package:clinical_application/features/finance/data/models/treasury_model.dart';
import 'package:clinical_application/features/settings/data/models/branch_model.dart';

class FinanceDatasource {
  FinanceDatasource() : _dio = DioConsumer();

  final DioConsumer _dio;

  // ── Shared reference data ──────────────────────────────────────────────────

  Future<List<Branch>> getBranches() async {
    final response = await _dio.get('/branches');
    return (response as List<dynamic>)
        .map((e) => Branch.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<String>> getUsernames() async {
    final response = await _dio.get('/system_users');
    return (response as List<dynamic>)
        .map((e) => (e as Map<String, dynamic>)['username'] as String)
        .toList();
  }

  Future<List<ExpenseCategory>> getCategories() async {
    final response = await _dio.get('/expense_categories');
    return (response as List<dynamic>)
        .map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Purchases ──────────────────────────────────────────────────────────────

  Future<List<PurchaseModel>> getPurchases({
    String? createdDate,
    int? branchId,
    String? username,
  }) async {
    final params = <String, dynamic>{};
    if (createdDate != null && createdDate.isNotEmpty) params['created_date'] = createdDate;
    if (branchId != null) params['branch_id'] = branchId;
    if (username != null && username.isNotEmpty) params['username'] = username;
    final response = await _dio.get('/purchases', queryParameters: params);
    return (response as List<dynamic>)
        .map((e) => PurchaseModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PurchaseLineModel>> getPurchaseLines(int purchaseId) async {
    final response = await _dio.get('/purchases/$purchaseId/lines');
    return (response as List<dynamic>)
        .map((e) => PurchaseLineModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createPurchase({
    required String username,
    String? description,
    required int categoryId,
    required int branchId,
    String? createdDate,
    required List<Map<String, dynamic>> lines,
  }) async {
    await _dio.post('/purchases', data: {
      'username': username,
      if (description != null && description.isNotEmpty) 'description': description,
      'category_id': categoryId,
      'branch_id': branchId,
      'status': 'مديونية',
      if (createdDate != null && createdDate.isNotEmpty) 'created_date': createdDate,
      'lines': lines,
    });
  }

  Future<void> updatePurchase(
    int purchaseId, {
    String? username,
    String? description,
    int? categoryId,
    int? branchId,
    List<Map<String, dynamic>>? lines,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (description != null) body['description'] = description;
    if (categoryId != null) body['category_id'] = categoryId;
    if (branchId != null) body['branch_id'] = branchId;
    if (lines != null) body['lines'] = lines;
    await _dio.put('/purchases/$purchaseId', data: body);
  }

  Future<void> deletePurchase(int purchaseId) async {
    await _dio.delete('/purchases/$purchaseId');
  }

  Future<void> payPurchase(int purchaseId, String username) async {
    await _dio.put('/purchase_pay/$purchaseId', queryParameters: {'username': username});
  }

  // ── Invoices ───────────────────────────────────────────────────────────────

  Future<List<InvoiceModel>> getInvoices({
    int? branchId,
    String? createdDate,
    String? username,
  }) async {
    final params = <String, dynamic>{};
    if (branchId != null) params['branch_id'] = branchId;
    if (createdDate != null && createdDate.isNotEmpty) params['created_date'] = createdDate;
    if (username != null && username.isNotEmpty) params['username'] = username;
    final response = await _dio.get('/invoices', queryParameters: params);
    return (response as List<dynamic>)
        .map((e) => InvoiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createInvoice({
    required String username,
    required String name,
    required double price,
    required int branchId,
    String? description,
    required int categoryId,
    String? createdDate,
  }) async {
    await _dio.post('/invoices', data: {
      'username': username,
      'name': name,
      'price': price,
      'branch_id': branchId,
      if (description != null && description.isNotEmpty) 'description': description,
      'status': 'مديونية',
      'category_id': categoryId,
      if (createdDate != null && createdDate.isNotEmpty) 'created_date': createdDate,
    });
  }

  Future<void> updateInvoice(
    int invoiceId, {
    String? username,
    String? name,
    double? price,
    int? branchId,
    String? description,
    int? categoryId,
  }) async {
    final body = <String, dynamic>{};
    if (username != null) body['username'] = username;
    if (name != null) body['name'] = name;
    if (price != null) body['price'] = price;
    if (branchId != null) body['branch_id'] = branchId;
    if (description != null) body['description'] = description;
    if (categoryId != null) body['category_id'] = categoryId;
    await _dio.put('/invoices/$invoiceId', data: body);
  }

  Future<void> deleteInvoice(int invoiceId) async {
    await _dio.delete('/invoices/$invoiceId');
  }

  Future<void> payInvoice(int invoiceId, String username) async {
    await _dio.put('/invoice_pay/$invoiceId', queryParameters: {'username': username});
  }

  // ── Debts ──────────────────────────────────────────────────────────────────

  Future<List<DebtModel>> getDebts({
    String? createdDate,
    String? paymentDate,
    String? username,
    int? branchId,
  }) async {
    final params = <String, dynamic>{};
    if (createdDate != null && createdDate.isNotEmpty) params['created_date'] = createdDate;
    if (paymentDate != null && paymentDate.isNotEmpty) params['payment_date'] = paymentDate;
    if (username != null && username.isNotEmpty) params['username'] = username;
    if (branchId != null) params['branch_id'] = branchId;
    final response = await _dio.get('/debts', queryParameters: params);
    return (response as List<dynamic>)
        .map((e) => DebtModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateDebt(int debtId, {double? amount, String? paymentDate}) async {
    final body = <String, dynamic>{};
    if (amount != null) body['amount'] = amount;
    if (paymentDate != null) body['payment_date'] = paymentDate;
    await _dio.put('/debts/$debtId', data: body);
  }

  Future<void> deleteDebt(int debtId) async {
    await _dio.delete('/debts/$debtId');
  }

  Future<void> payDebt(int debtId, String username) async {
    await _dio.put('/debt_pay/$debtId', queryParameters: {'username': username});
  }

  // ── Treasury ───────────────────────────────────────────────────────────────

  Future<List<TreasuryModel>> getTreasury({
    String? createdDate,
    String? transactionType,
    String? username,
    int? branchId,
  }) async {
    final params = <String, dynamic>{};
    if (createdDate != null && createdDate.isNotEmpty) params['created_date'] = createdDate;
    if (transactionType != null && transactionType.isNotEmpty) params['transaction_type'] = transactionType;
    if (username != null && username.isNotEmpty) params['username'] = username;
    if (branchId != null) params['branch_id'] = branchId;
    final response = await _dio.get('/treasury', queryParameters: params);
    return (response as List<dynamic>)
        .map((e) => TreasuryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateTreasury(int treasuryId, {double? amount, String? transactionType}) async {
    final body = <String, dynamic>{};
    if (amount != null) body['amount'] = amount;
    if (transactionType != null) body['transaction_type'] = transactionType;
    await _dio.put('/treasury/$treasuryId', data: body);
  }

  Future<void> deleteTreasury(int treasuryId) async {
    await _dio.delete('/treasury/$treasuryId');
  }
}
