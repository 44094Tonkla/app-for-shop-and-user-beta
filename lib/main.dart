import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // สำหรับการจัดการกับ JSON
import 'Exchangerate.dart';
import 'MoneyBox.dart';
import 'FoodMenu.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  ExchangeRate? _dataFromAPI;
  double balance = 5000; // เงินคงเหลือเริ่มต้น
  List<FoodMenu> selectedItems = [];

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
        return _dataFromAPI;
      } else {
        throw Exception('Failed to load exchange rate');
      }
    } catch (e) {
      print("Error: $e");
      return null;
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
        title: Text("แปลงสกุลเงินและเมนูอาหาร",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartPage(
                      selectedItems: selectedItems,
                      currentBalance: balance,
                      updateBalance: (newBalance) {
                        setState(() {
                          balance = newBalance;
                        });
                      },
                      clearCart: (newCart) {
                        setState(() {
                          selectedItems = newCart;
                        });
                      },
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
        return LinearProgressIndicator();
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

        if (priceValue > balance) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ยอดเงินไม่พอสำหรับการซื้อ $name'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }

        sendFoodSelectionToBackend(name, price);
        setState(() {
          balance -= priceValue;
          selectedItems
              .add(FoodMenu(name, price, imagePath)); // เพิ่มอาหารที่เลือก
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
}

class MyAccountPage extends StatefulWidget {
  final double balance;

  MyAccountPage({required this.balance});

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
      currentBalance = 5000; // รีเซ็ตยอดเงิน
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("รีเซ็ตยอดเงินสำเร็จ"),
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context, currentBalance); // ส่งค่ากลับไปยังหน้าแรก
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("บัญชีของฉัน"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "ยอดเงินของคุณคือ: ฿$currentBalance",
              style: TextStyle(
                fontSize: 40, // ปรับขนาดตัวเลขให้ใหญ่ขึ้น
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: resetBalance,
              child: Text("รีเซ็ตยอดเงิน"),
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
  final Function(double) updateBalance;
  final Function(List<FoodMenu>) clearCart;

  CartPage({
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
        title: Text("ตะกร้าสินค้า"),
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
                Text("ยอดรวม: ฿$totalPrice", style: TextStyle(fontSize: 24)),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    if (widget.currentBalance >= totalPrice) {
                      widget.updateBalance(widget.currentBalance - totalPrice);
                      widget.clearCart([]);
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("ยอดเงินไม่พอสำหรับการซื้อ"),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text("ยืนยันการซื้อ"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
