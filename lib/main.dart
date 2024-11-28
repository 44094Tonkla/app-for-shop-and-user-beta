import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'Exchangerate.dart';
import 'MoneyBox.dart';
import 'FoodMenu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "My App",
      home: MyHomePage(),
      theme: ThemeData(primarySwatch: Colors.purple),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ExchangeRate? _dataFromAPI;
  double balance = 5000;
  List<FoodMenu> selectedItems = [];
  double usdBalance = 0.0;

  @override
  void initState() {
    super.initState();
    getExchangeRate();
  }

  Future<ExchangeRate?> getExchangeRate() async {
    var url = Uri.parse("https://api.exchangerate.host/latest?base=THB");
    try {
      var response = await http.get(url);
      if (response.statusCode == 200) {
        _dataFromAPI = exchangeRateFromJson(response.body);
        setState(() {});
        return _dataFromAPI;
      } else {
        throw Exception('Failed to load exchange rate');
      }
    } catch (e) {
      print("Error: $e");
      return null;
    }
  }

  Future<void> sendFoodSelectionToBackend(String foodName, String price) async {
    var url = Uri.parse("https://your-backend-api.com/food-selection");
    try {
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'food_name': foodName,
          'price': price,
        }),
      );

      if (response.statusCode == 200) {
        print("ส่งคำสั่งสำเร็จ");
      } else {
        print("เกิดข้อผิดพลาดในการส่งคำสั่ง");
      }
    } catch (e) {
      print("Error sending data: $e");
    }
  }

  // เพิ่มฟังก์ชันแปลงเงินและอัปเดตยอดเงิน USD
  void updateAccountBalances(double totalAmount) {
    // ตรวจสอบว่ามีอัตราแลกเปลี่ยนหรือไม่
    if (_dataFromAPI != null && _dataFromAPI?.rates != null) {
      // แปลงจำนวนเงินบาทเป็น USD
      double usdRate =
          _dataFromAPI!.rates['USD'] ?? 0.03; // ใช้ค่าดีฟอลต์หากไม่มีข้อมูล
      double usdAmount = totalAmount * usdRate;

      // อัปเดตยอดเงินใน USD
      setState(() {
        usdBalance += usdAmount;
        balance -= totalAmount;
      });

      // แสดงข้อความแจ้งเตือน
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'ชำระเงินสำเร็จ! คุณได้รับเงิน \$${usdAmount.toStringAsFixed(2)}'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      // กรณีไม่มีอัตราแลกเปลี่ยน ใช้อัตราคงที่
      double usdAmount = totalAmount * 0.05; // ใช้อัตราประมาณ 1 USD = 33 THB

      setState(() {
        usdBalance += usdAmount;
        balance -= totalAmount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'ชำระเงินสำเร็จ! คุณได้รับเงิน \$${usdAmount.toStringAsFixed(2)} (อัตราโดยประมาณ)'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    List<FoodMenu> foodMenuList = [
      FoodMenu("กุ้งเผา", "500", "images/assets/picture1.jpg"),
      FoodMenu("กะเพราหมู", "50", "images/assets/picture2.jpg"),
      FoodMenu("ส้มตำ", "65", "images/assets/picture3.jpg"),
      FoodMenu("ผัดไทย", "70", "images/assets/picture4.jpg"),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text("แอปฝั่งคนซื้อ",
            style: TextStyle(
                color: const Color.fromARGB(255, 3, 3, 3),
                fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.red,
              padding: EdgeInsets.all(8.0),
              child: Text(
                "ยินดีต้อนรับสู่แอปของผมครับ",
                style: TextStyle(color: Colors.black, fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ),
            buildExchangeRateSection(),
            SizedBox(height: 20),
            Text("เมนูอาหาร",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            buildFoodMenuSection(foodMenuList),
            ElevatedButton(
              onPressed: () async {
                final updatedBalance = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyAccountPage(balance: balance),
                  ),
                );
                if (updatedBalance != null) {
                  setState(() {
                    balance = updatedBalance;
                  });
                }
              },
              child: Text("ไปหน้าบัญชีของฉัน"),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedUSDAccountBalance = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyUSDAccountPage(
                        balance: usdBalance, exchangeRate: _dataFromAPI),
                  ),
                );
                if (updatedUSDAccountBalance != null) {
                  setState(() {
                    usdBalance = updatedUSDAccountBalance;
                  });
                }
              },
              child: Text("ไปหน้าบัญชี USD"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(
                      selectedItems: selectedItems,
                      currentBalance: balance,
                      exchangeRate: _dataFromAPI,
                      updateBalance: (newBalance) {
                        setState(() {
                          balance = newBalance;
                        });
                      },
                      updateUSDBalance: (newUSDBalance) {
                        setState(() {
                          usdBalance = newUSDBalance;
                        });
                      },
                      clearCart: (newCart) {
                        setState(() {
                          selectedItems = newCart;
                        });
                      },
                      updateAccountBalances:
                          updateAccountBalances, // เพิ่มฟังก์ชันใหม่
                    ),
                  ),
                );
              },
              child: Text("ไปตะกร้าสินค้า"),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildExchangeRateSection() {
    return FutureBuilder<ExchangeRate?>(
      future: getExchangeRate(),
      builder: (BuildContext context, AsyncSnapshot<ExchangeRate?> snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData && snapshot.data != null) {
            var result = snapshot.data!;
            double amount = 10000;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  MoneyBox(
                    title: "THB",
                    amount: amount,
                    color: Colors.lightBlue,
                    size: 150,
                  ),
                  ...["USD", "EUR", "GBP", "JPY"].map(
                    (currency) => MoneyBox(
                      title: currency,
                      amount: amount * (result.rates[currency] ?? 1),
                      color: Colors.primaries[
                          ["USD", "EUR", "GBP", "JPY"].indexOf(currency)],
                      size: 100,
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
        }
        return Center(child: LinearProgressIndicator());
      },
    );
  }

  Widget buildFoodMenuSection(List<FoodMenu> foodMenuList) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: foodMenuList
            .map((foodItem) =>
                foodMenuItem(foodItem.img, foodItem.name, foodItem.price))
            .toList(),
      ),
    );
  }

  Widget foodMenuItem(String imagePath, String name, String price) {
    return GestureDetector(
      onTap: () {
        double priceValue = 0.0;
        try {
          priceValue = double.parse(price);
        } catch (e) {
          print("Error parsing price: $e");
          return;
        }

        sendFoodSelectionToBackend(name, price);
        setState(() {
          selectedItems.add(FoodMenu(name, price, imagePath));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('คุณได้เลือกอาหาร $name'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.broken_image,
                size: 100,
                color: Colors.grey,
              ),
            ),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: TextStyle(fontSize: 20)),
                Text("ราคา $price", style: TextStyle(fontSize: 16)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyAccountPage extends StatefulWidget {
  final double balance;

  const MyAccountPage({super.key, required this.balance});

  @override
  _MyAccountPageState createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  late double currentBalance;

  @override
  void initState() {
    super.initState();
    currentBalance = widget.balance;
  }

  void resetBalance() {
    setState(() {
      currentBalance = 5000; // Reset to original balance
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ยอดเงินถูกรีเซ็ตแล้ว'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("บัญชีของคุณ"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: resetBalance,
            tooltip: 'รีเซ็ตยอดเงิน',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("ยอดคงเหลือในบัญชี: ฿$currentBalance",
                style: TextStyle(fontSize: 24)),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, currentBalance);
              },
              child: Text("กลับไปที่หน้าหลัก"),
            ),
          ],
        ),
      ),
    );
  }
}

class MyUSDAccountPage extends StatefulWidget {
  final double balance;
  final ExchangeRate? exchangeRate;

  const MyUSDAccountPage({super.key, required this.balance, this.exchangeRate});

  @override
  _MyUSDAccountPageState createState() => _MyUSDAccountPageState();
}

class _MyUSDAccountPageState extends State<MyUSDAccountPage> {
  late double currentUSDAccountBalance;

  @override
  void initState() {
    super.initState();
    currentUSDAccountBalance = widget.balance;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("บัญชี USD ของคุณ"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
                "ยอดคงเหลือในบัญชี USD: \$${currentUSDAccountBalance.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 24)),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, currentUSDAccountBalance);
              },
              child: Text("กลับไปที่หน้าหลัก"),
            ),
          ],
        ),
      ),
    );
  }
}

class CartPage extends StatefulWidget {
  final List<FoodMenu> selectedItems;
  final double currentBalance;
  final ExchangeRate? exchangeRate;
  final Function(double) updateBalance;
  final Function(double) updateUSDBalance;
  final Function(List<FoodMenu>) clearCart;
  final Function(double) updateAccountBalances;

  const CartPage({
    super.key,
    required this.selectedItems,
    required this.currentBalance,
    required this.exchangeRate,
    required this.updateBalance,
    required this.updateUSDBalance,
    required this.clearCart,
    required this.updateAccountBalances,
  });

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late List<FoodMenu> selectedItems;

  @override
  void initState() {
    super.initState();
    selectedItems = List.from(widget.selectedItems);
  }

  void _removeItem(FoodMenu item) {
    setState(() {
      selectedItems.remove(item);
      widget.clearCart(selectedItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    double total = selectedItems.fold(0.0, (sum, item) {
      return sum + double.parse(item.price);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("ตะกร้าสินค้า"),
      ),
      body: Column(
        children: [
          Text("สินค้าที่เลือก:", style: TextStyle(fontSize: 24)),
          Expanded(
            child: selectedItems.isEmpty
                ? Center(
                    child: Text("ตะกร้าสินค้าว่าง",
                        style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    itemCount: selectedItems.length,
                    itemBuilder: (context, index) {
                      final item = selectedItems[index];
                      return ListTile(
                        leading: Image.asset(
                          item.img,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(item.name),
                        subtitle: Text("ราคา ${item.price} บาท"),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeItem(item),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  "ยอดรวม: $total บาท",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: selectedItems.isEmpty
                          ? null
                          : () {
                              setState(() {
                                selectedItems.clear();
                                widget.clearCart([]);
                              });
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        disabledBackgroundColor: Colors.grey,
                      ),
                      child: Text("ล้างตะกร้า"),
                    ),
                    ElevatedButton(
                      onPressed:
                          selectedItems.isEmpty || widget.currentBalance < total
                              ? null
                              : () {
                                  // ตรวจสอบยอดเงินคงเหลือ
                                  if (widget.currentBalance >= total) {
                                    // อัปเดตยอดเงิน
                                    widget.updateBalance(
                                        widget.currentBalance - total);

                                    // ส่งข้อมูลการชำระเงิน
                                    widget.updateAccountBalances(total);

                                    // ล้างตะกร้า
                                    widget.clearCart([]);

                                    // แสดงข้อความแจ้งเตือน
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('ชำระเงินสำเร็จ!'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );

                                    // กลับไปหน้าหลัก
                                    Navigator.pop(context);
                                  } else {
                                    // แสดงข้อความเตือนเมื่อเงินไม่พอ
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('ยอดเงินไม่เพียงพอ'),
                                        backgroundColor: Colors.red,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                      child: Text("ชำระเงิน"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
