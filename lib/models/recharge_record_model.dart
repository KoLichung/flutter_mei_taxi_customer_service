class RechargeRecordModel {
  final int id;
  final int user;
  final String driverName;
  final String driverPhone;
  final int? carTeam;
  final String? carTeamName;
  final double increaseMoney;
  final double userLeftMoney;
  final double sumMoney;
  final DateTime date;
  final int? recordUser;
  final String? recordUserName;

  RechargeRecordModel({
    required this.id,
    required this.user,
    required this.driverName,
    required this.driverPhone,
    this.carTeam,
    this.carTeamName,
    required this.increaseMoney,
    required this.userLeftMoney,
    required this.sumMoney,
    required this.date,
    this.recordUser,
    this.recordUserName,
  });

  factory RechargeRecordModel.fromJson(Map<String, dynamic> json) {
    // 解析時間並加 8 小時（UTC+8）
    final utcTime = DateTime.parse(json['date'] as String);
    final localTime = utcTime.add(const Duration(hours: 8));

    return RechargeRecordModel(
      id: json['id'] as int,
      user: json['user'] as int,
      driverName: json['driver_name'] as String,
      driverPhone: json['driver_phone'] as String,
      carTeam: json['carTeam'] as int?,
      carTeamName: json['car_team_name'] as String?,
      increaseMoney: (json['increase_money'] as num).toDouble(),
      userLeftMoney: (json['user_left_money'] as num).toDouble(),
      sumMoney: (json['sum_money'] as num).toDouble(),
      date: localTime,
      recordUser: json['record_user'] as int?,
      recordUserName: json['record_user_name'] as String?,
    );
  }
}

