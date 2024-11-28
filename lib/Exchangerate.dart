import 'dart:convert';
import 'package:http/http.dart' as http;

/// ฟังก์ชันสำหรับแปลง JSON เป็น `ExchangeRate`
ExchangeRate exchangeRateFromJson(String str) =>
    ExchangeRate.fromJson(json.decode(str));

/// ฟังก์ชันสำหรับแปลง `ExchangeRate` เป็น JSON
String exchangeRateToJson(ExchangeRate data) => json.encode(data.toJson());

/// คลาสสำหรับจัดการข้อมูลอัตราแลกเปลี่ยนเงินตรา
class ExchangeRate {
  final Map<String, double> rates; // อัตราแลกเปลี่ยน
  final String base; // สกุลเงินหลัก
  final DateTime date; // วันที่ของข้อมูล

  /// Constructor
  ExchangeRate({
    required this.rates,
    required this.base,
    required this.date,
  });

  /// Factory Method สำหรับสร้างจาก JSON
  factory ExchangeRate.fromJson(Map<String, dynamic> json) {
    return ExchangeRate(
      rates: Map<String, double>.from(
          json["rates"].map((key, value) => MapEntry(key, value.toDouble()))),
      base: json["base"],
      date: DateTime.parse(json["date"]),
    );
  }

  /// ฟังก์ชันสำหรับแปลงข้อมูลกลับเป็น JSON
  Map<String, dynamic> toJson() => {
        "rates": rates,
        "base": base,
        "date": date.toIso8601String(), // ใช้ ISO 8601 เพื่อความปลอดภัย
      };
}

class ExchangeRateService {
  bool _isLoading = false; // ตัวแปรเช็คสถานะการโหลด

  /// ฟังก์ชันสำหรับดึงข้อมูลอัตราแลกเปลี่ยนจาก API
  Future<ExchangeRate?> fetchExchangeRate() async {
    if (_isLoading) {
      // หากกำลังโหลดอยู่แล้ว ให้ return null หรือทำอะไรบางอย่าง
      return null;
    }

    _isLoading = true; // ตั้งค่าสถานะการโหลดเป็น true

    var url = Uri.parse("https://api.exchangerate.host/latest?base=THB");
    try {
      // เรียก API และตั้งเวลารอ 10 วินาที
      var response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        // หากได้รับการตอบกลับที่สำเร็จ, แปลงข้อมูลเป็น ExchangeRate
        return exchangeRateFromJson(response.body);
      } else {
        throw Exception("เกิดข้อผิดพลาดในการโหลดข้อมูล");
      }
    } catch (e) {
      // จัดการข้อผิดพลาดกรณีไม่มีการเชื่อมต่อหรือมีข้อผิดพลาดอื่นๆ
      print("Error fetching exchange rate: $e");
      return null;
    } finally {
      _isLoading = false; // เปลี่ยนสถานะการโหลดเป็น false เมื่อเสร็จสิ้น
    }
  }
}
