import 'dart:convert';
import 'dart:developer';
import 'package:chessgame/values/constant.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:khalti_checkout_flutter/khalti_checkout_flutter.dart';

class KhaltiSDKDemo extends StatefulWidget {
  const KhaltiSDKDemo({super.key});

  @override
  State<KhaltiSDKDemo> createState() => _KhaltiSDKDemoState();
}

class _KhaltiSDKDemoState extends State<KhaltiSDKDemo> {
  Khalti? khaltiInstance;
  bool isLoading = false;
  String? currentPidx;
  PaymentResult? paymentResult;

  // Replace with your actual Khalti secret key for server-side requests
  final String secretKey = AppInfo.khaltiSecretKey;
  final String publicKey = AppInfo.khaltiPublictKey;

  @override
  void initState() {
    super.initState();
  }

  // Generate pidx by calling Khalti's API
  Future<String?> _generatePidx() async {
    try {
      const url = 'https://a.khalti.com/api/v2/epayment/initiate/';

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'key $secretKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'return_url': 'https://example.com/payment/success/',
          'website_url': 'https://example.com/',
          'amount': 2200, // Amount in paisa (Rs. 22 = 2200 paisa)
          'purchase_order_id': 'order_${DateTime.now().millisecondsSinceEpoch}',
          'purchase_order_name': '1 day fee',
          'customer_info': {
            'name': 'Customer Name',
            'email': 'customer@example.com',
            'phone': '9800000000',
          },
          'product_details': [
            {
              'identity': 'day_pass',
              'name': '1 day fee',
              'total_price': 2200,
              'quantity': 1,
              'unit_price': 2200,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['pidx'];
      } else {
        log('Failed to generate pidx: ${response.body}');
        return null;
      }
    } catch (e) {
      log('Error generating pidx: $e');
      return null;
    }
  }

  // Initialize Khalti with fresh pidx
  Future<void> _initializeKhalti(String pidx) async {
    final payConfig = KhaltiPayConfig(
      publicKey: publicKey,
      pidx: pidx,
      environment:
          Environment.test, // Change to Environment.prod for production
    );

    khaltiInstance = await Khalti.init(
      enableDebugging: true,
      payConfig: payConfig,
      onPaymentResult: (paymentResult, khalti) {
        log(paymentResult.toString());
        setState(() {
          this.paymentResult = paymentResult;
          isLoading = false;
        });
        khalti.close(context);
      },
      onMessage:
          (
            khalti, {
            description,
            statusCode,
            event,
            needsPaymentConfirmation,
          }) async {
            log(
              'Description: $description, Status Code: $statusCode, Event: $event, NeedsPaymentConfirmation: $needsPaymentConfirmation',
            );

            if (needsPaymentConfirmation == true) {
              setState(() {
                isLoading = false;
              });
              _showPaymentResult('Payment needs confirmation', Colors.orange);
            } else {
              khalti.close(context);
              setState(() {
                isLoading = false;
              });
              _showPaymentResult('Payment failed or cancelled', Colors.red);
            }
          },
      onReturn: () {
        log('Successfully redirected to return_url.');
        setState(() {
          isLoading = false;
        });
        _showPaymentResult('Payment completed successfully!', Colors.green);
      },
    );
  }

  void _showPaymentResult(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _initiatePayment() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Generate fresh pidx
      final pidx = await _generatePidx();
      if (pidx == null) {
        setState(() {
          isLoading = false;
        });
        _showPaymentResult('Failed to initialize payment', Colors.red);
        return;
      }

      setState(() {
        currentPidx = pidx;
      });

      // Initialize Khalti with fresh pidx
      await _initializeKhalti(pidx);

      // Open Khalti payment
      if (khaltiInstance != null) {
        khaltiInstance!.open(context);
      }
    } catch (e) {
      log('Error initiating payment: $e');
      setState(() {
        isLoading = false;
      });
      _showPaymentResult('Error initiating payment', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('lib/images/white-king.png', height: 200, width: 200),
            const SizedBox(height: 120),
            const Text('Rs. 22', style: TextStyle(fontSize: 25)),
            const Text('1 day fee'),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator.adaptive()
                : OutlinedButton(
                    onPressed: _initiatePayment,
                    child: const Text('Pay with Khalti'),
                  ),
            const SizedBox(height: 120),
            if (currentPidx != null) ...[
              Text(
                'Current pidx: $currentPidx',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
            ],
            if (paymentResult != null) ...[
              Column(
                children: [
                  Text('pidx: ${paymentResult!.payload?.pidx}'),
                  Text('Status: ${paymentResult!.payload?.status}'),
                  Text('Amount Paid: ${paymentResult!.payload?.totalAmount}'),
                  Text(
                    'Transaction ID: ${paymentResult!.payload?.transactionId}',
                  ),
                ],
              ),
            ],
            const SizedBox(height: 120),
            const Text(
              'This is a demo application developed by some merchant.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
