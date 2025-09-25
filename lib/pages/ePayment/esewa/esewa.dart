import 'package:flutter/material.dart';
import 'package:chessgame/values/constant.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';

class EsewaPaymentScreen extends StatefulWidget {
  const EsewaPaymentScreen({Key? key}) : super(key: key);

  @override
  State<EsewaPaymentScreen> createState() => _EsewaPaymentScreenState();
}

class _EsewaPaymentScreenState extends State<EsewaPaymentScreen> {
  String _paymentStatus = '';
  bool _isLoading = false;

  Future<void> _initiatePayment() async {
    setState(() {
      _isLoading = true;
      _paymentStatus = 'Processing payment...';
    });

    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          clientId: AppInfo.EsewaCLIENT_ID,
          secretId: AppInfo.EsewaSECRET_KEY,
          environment: Environment.test,
        ),
        esewaPayment: EsewaPayment(
          productId: "1d71jd81",
          productName: "Product One",
          productPrice: "20",
          callbackUrl: 'https://example.com/payment/success/',
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult result) {
          setState(() {
            _paymentStatus = 'Payment Successful!\nRef ID: ${result.refId}';
            _isLoading = false;
          });
          _verifyPayment(result);
        },
        onPaymentFailure: () {
          setState(() {
            _paymentStatus = 'Payment Failed. Please try again.';
            _isLoading = false;
          });
        },
        onPaymentCancellation: () {
          setState(() {
            _paymentStatus = 'Payment Cancelled by user.';
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _paymentStatus = 'Error occurred: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _verifyPayment(EsewaPaymentSuccessResult result) {
    // Implement payment verification logic here
    debugPrint('Verifying payment with ref ID: ${result.refId}');
    // You can call your backend API here to verify the payment
  }

  void _resetPayment() {
    setState(() {
      _paymentStatus = '';
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('eSewa Payment'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product Info Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Details',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Product One',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Rs. 20',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Colors.green[600],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Product ID: 1d71jd81',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Payment Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _initiatePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('Processing...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment),
                          const SizedBox(width: 8),
                          const Text(
                            'Pay with eSewa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 24),

            // Status Display
            if (_paymentStatus.isNotEmpty)
              Card(
                color: _paymentStatus.contains('Successful')
                    ? Colors.green[50]
                    : _paymentStatus.contains('Failed') ||
                          _paymentStatus.contains('Error')
                    ? Colors.red[50]
                    : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _paymentStatus.contains('Successful')
                                ? Icons.check_circle
                                : _paymentStatus.contains('Failed') ||
                                      _paymentStatus.contains('Error')
                                ? Icons.error
                                : Icons.info,
                            color: _paymentStatus.contains('Successful')
                                ? Colors.green[600]
                                : _paymentStatus.contains('Failed') ||
                                      _paymentStatus.contains('Error')
                                ? Colors.red[600]
                                : Colors.orange[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Payment Status',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _paymentStatus,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (_paymentStatus.isNotEmpty && !_isLoading) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _resetPayment,
                          child: const Text('Make Another Payment'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Footer
            Text(
              'Secure payment powered by eSewa',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
