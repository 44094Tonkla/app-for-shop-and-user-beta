import 'dart:convert';

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
        json["rates"].map((key, value) => MapEntry(key, value.toDouble())),
      ),
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
