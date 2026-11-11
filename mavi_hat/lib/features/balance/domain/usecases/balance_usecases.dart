import '../../../../core/errors/failure.dart';
import '../../../../core/utils/result.dart';
import '../entities/balance_entities.dart';
import '../repositories/balance_repository.dart';

class ValidateTopUpAmount {
  const ValidateTopUpAmount();

  static const double minAmount = 1.0;
  static const double maxAmount = 1000.0;

  Result<double> call(double? amount) {
    if (amount == null || amount.isNaN || amount.isInfinite) {
      return const Err(
        ValidationFailure(message: 'Lütfen geçerli bir yükleme tutarı girin.'),
      );
    }
    if (amount < minAmount) {
      return const Err(
        ValidationFailure(
          message: 'Minimum yükleme tutarı ₺1,00 olmalıdır.',
        ),
      );
    }
    if (amount > maxAmount) {
      return const Err(
        ValidationFailure(
          message: 'Tek seferde maksimum ₺1.000,00 yükleyebilirsiniz.',
        ),
      );
    }
    return Success(amount);
  }
}

class GetPaymentMethods {
  const GetPaymentMethods(this._repository);

  final BalanceRepository _repository;

  Future<Result<List<PaymentMethod>>> call() => _repository.getPaymentMethods();
  List<PaymentMethod> sync() => _repository.getPaymentMethodsSync();
}

class AddPaymentMethod {
  const AddPaymentMethod(this._repository);

  final BalanceRepository _repository;

  Future<Result<PaymentMethod>> call({
    required String rawCardNumber,
    required String cardholderName,
    required String expiryInput,
    required String cvv,
    bool saveForFuture = true,
  }) async {
    final digits = rawCardNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 15 || digits.length > 19) {
      return const Err(
        ValidationFailure(
          message: 'Lütfen 16 haneli geçerli bir kart numarası girin.',
        ),
      );
    }
    final cleanHolder = cardholderName.trim();
    if (cleanHolder.length < 3 || !cleanHolder.contains(' ')) {
      return const Err(
        ValidationFailure(
          message: 'Lütfen kart üzerindeki ad ve soyadı tam girin.',
        ),
      );
    }
    final expParts = expiryInput.trim().split('/');
    if (expParts.length != 2) {
      return const Err(
        ValidationFailure(
          message: 'Son kullanma tarihini AA/YY formatında girin.',
        ),
      );
    }
    final month = int.tryParse(expParts[0]) ?? 0;
    final year = int.tryParse(expParts[1]) ?? 0;
    if (month < 1 || month > 12 || year < 25 || year > 40) {
      return const Err(
        ValidationFailure(
          message: 'Geçersiz son kullanma tarihi (Ay 01-12, Yıl 25-40).',
        ),
      );
    }
    final cleanCvv = cvv.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanCvv.length < 3 || cleanCvv.length > 4) {
      return const Err(
        ValidationFailure(message: 'CVV güvenlik kodu 3 veya 4 haneli olmalıdır.'),
      );
    }

    return _repository.addPaymentMethod(
      rawCardNumber: digits,
      cardholderName: cleanHolder.toUpperCase(),
      expiryMonth: month,
      expiryYear: year,
      cvv: cleanCvv,
      saveForFuture: saveForFuture,
    );
  }
}

class RemovePaymentMethod {
  const RemovePaymentMethod(this._repository);

  final BalanceRepository _repository;

  Future<Result<List<PaymentMethod>>> call(String methodId) =>
      _repository.removePaymentMethod(methodId);
}

class SetDefaultPaymentMethod {
  const SetDefaultPaymentMethod(this._repository);

  final BalanceRepository _repository;

  Future<Result<List<PaymentMethod>>> call(String methodId) =>
      _repository.setDefaultPaymentMethod(methodId);
}

class ConfirmTopUpPayment {
  const ConfirmTopUpPayment(this._repository);

  final BalanceRepository _repository;

  Future<Result<TopUpResult>> call({
    required TopUpRequest request,
    required String otpCode,
  }) async {
    final validator = const ValidateTopUpAmount();
    final amountValidation = validator(request.amount);
    if (amountValidation is Err<double>) {
      return Err(amountValidation.failure);
    }
    final cleanOtp = otpCode.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanOtp.length != 6) {
      return const Err(
        ValidationFailure(
          message: '3D Secure doğrulaması için 6 haneli SMS kodunu girin.',
        ),
      );
    }
    return _repository.confirmTopUpPayment(
      request: request,
      otpCode: cleanOtp,
    );
  }
}

