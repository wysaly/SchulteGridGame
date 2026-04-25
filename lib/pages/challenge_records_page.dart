import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:schultegridgame/pages/db_connect_user.dart';

class ChallengeRecordsPage extends StatefulWidget {
  final int challengeType;

  const ChallengeRecordsPage({super.key, required this.challengeType});

  @override
  State<ChallengeRecordsPage> createState() => _ChallengeRecordsPageState();
}

class _ChallengeRecordsPageState extends State<ChallengeRecordsPage> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await DBService.getChallengeRecords(
      challengeType: widget.challengeType,
    );
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  // 折线图数据：按时间升序（旧→新）
  List<Map<String, dynamic>> get _chartRecords => _records.reversed.toList();

  String _formatDate(dynamic timestamp) {
    final date = DateTime.parse(timestamp.toString());
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(dynamic timestamp) {
    final date = DateTime.parse(timestamp.toString());
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildChart() {
    final data = _chartRecords;
    if (data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(child: Text('暂无挑战记录', style: TextStyle(fontSize: 16))),
      );
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < data.length; i++) {
      final t = double.tryParse(data[i]['time'].toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), t));
    }

    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final yPadding = ((maxY - minY) * 0.2).clamp(1.0, double.infinity);

    // X轴标签间隔：最多显示6个，自动跳过
    final labelInterval =
        (data.length / 6).ceil().clamp(1, data.length).toDouble();

    return SizedBox(
      height: 220,
      child: Padding(
        padding: const EdgeInsets.only(right: 16, left: 4, top: 8, bottom: 4),
        child: LineChart(
          LineChartData(
            minY: (minY - yPadding).clamp(0, double.infinity),
            maxY: maxY + yPadding,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine:
                  (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.2),
                    strokeWidth: 1,
                  ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border(
                bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
                left: BorderSide(color: Colors.grey.withValues(alpha: 0.4)),
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: labelInterval,
                  reservedSize: 28,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _formatDate(data[idx]['timestamp']),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}s',
                      style: const TextStyle(fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: const Color.fromARGB(255, 68, 70, 163),
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter:
                      (spot, percent, bar, index) => FlDotCirclePainter(
                        radius: 4,
                        color: const Color.fromARGB(255, 46, 31, 187),
                        strokeWidth: 1.5,
                        strokeColor: Colors.white,
                      ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color.fromARGB(
                    255,
                    235,
                    3,
                    3,
                  ).withValues(alpha: 0.1),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems:
                    (spots) =>
                        spots
                            .map(
                              (s) => LineTooltipItem(
                                '${s.y.toStringAsFixed(1)}s\n${_formatDate(data[s.x.toInt()]['timestamp'])}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            )
                            .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.challengeType == 0 ? '数字方格挑战记录' : '古诗方格挑战记录';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Text(
                      '完成时间趋势',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                  _buildChart(),
                  const Divider(height: 1),
                  Expanded(
                    child:
                        _records.isEmpty
                            ? const Center(
                              child: Text(
                                '暂无挑战记录',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                            : ListView.builder(
                              itemCount: _records.length,
                              itemBuilder: (context, index) {
                                final record = _records[index];
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(
                                      0xFF3EE5C1,
                                    ).withValues(alpha: 0.2),
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Color(0xFF3EE5C1),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    '${record['time']} 秒',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatDateTime(record['timestamp']),
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
    );
  }
}
