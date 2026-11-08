import 'package:atlas/modules/main/controllers/feature_controllers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a missing cart price cannot become a zero total', () {
    final cart = CartController();
    cart.cartItems.value = [
      {'price': null, 'quantity': 2},
    ];
    expect(cart.totalPrice, isNull);

    cart.cartItems.value = [
      {'price': 12.5, 'quantity': 2},
    ];
    expect(cart.totalPrice, 25);
  });
}
