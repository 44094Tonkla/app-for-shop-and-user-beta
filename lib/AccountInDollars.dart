import 'package:flutter/material.dart';
import 'Exchangerate.dart';

class AccountInDollars extends StatefulWidget {
  final double balanceBaht;
  final ExchangeRate exchangeRate;

  const AccountInDollars({
    super.key,
    required this.balanceBaht,
    required this.exchangeRate,
  });

  @override
  _AccountInDollarsState createState() => _AccountInDollarsState();
}

class _AccountInDollarsState extends State<AccountInDollars> {
  @override
  Widget build(BuildContext context) {
    double exchangeRateToUSD = widget.exchangeRate.rates['USD'] ?? 0.0;
    double balanceInUSD = widget.balanceBaht * exchangeRateToUSD;

    return Scaffold(
      appBar: AppBar(
        title: Text("บัญชีในสกุลเงินดอลลาร์ (USD)"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "ยอดเงินในบัญชีของคุณ (USD):",
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            Text(
              "\$${balanceInUSD.toStringAsFixed(2)}",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("ย้อนกลับ"),
            ),
          ],
        ),
      ),
    );
  }
}
