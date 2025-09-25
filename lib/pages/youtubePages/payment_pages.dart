import 'package:flutter/material.dart';

import '../../component/custom_Card.dart';
import '../ePayment/esewa/esewa.dart';
import '../ePayment/khalti/khalti_payment_page.dart';

class PaymentPages extends StatelessWidget {
  const PaymentPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Page'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VideoOptionCard(
            icon: Icons.payment,
            title: 'Khalti Payment',
            subtitle: 'Use khalti for payment',
            color: Colors.purple,
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (context) => KhaltiSDKDemo()));
            },
          ),
          SizedBox(height: 10),

          VideoOptionCard(
            icon: Icons.payment,
            title: 'Esewa Payment',
            subtitle: 'Use Esewa for payment',
            color: Colors.greenAccent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => EsewaPaymentScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
