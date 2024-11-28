import 'package:flutter/material.dart';
import 'FoodMenu.dart';

class CartPage extends StatefulWidget {
  final List<FoodMenu> selectedItems;
  final double currentBalance;
  final Function(double) updateBalance;
  final Function(List<FoodMenu>) clearCart;

  const CartPage({
    super.key,
    required this.selectedItems,
    required this.currentBalance,
    required this.updateBalance,
    required this.clearCart,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  Widget build(BuildContext context) {
    double totalPrice = widget.selectedItems
        .fold(0, (sum, item) => sum + double.parse(item.price));

    return Scaffold(
      appBar: AppBar(
        title: const Text("ตะกร้าสินค้า"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.selectedItems.length,
              itemBuilder: (context, index) {
                final item = widget.selectedItems[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text("ราคา: ฿${item.price}"),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "ยอดรวม: ฿$totalPrice",
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (widget.currentBalance >= totalPrice) {
                      widget.updateBalance(widget.currentBalance - totalPrice);
                      widget.clearCart([]);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("ยอดเงินไม่พอสำหรับการซื้อ"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text("ยืนยันการซื้อ"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
