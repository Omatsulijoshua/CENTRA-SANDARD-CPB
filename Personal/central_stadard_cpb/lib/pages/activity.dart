import 'package:central_stadard_cpb/widgets/time_option_button.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: const Text(
          "Activity",
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
        ],
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        width: 340,
                        height: 75,
                        decoration: BoxDecoration(
                          color: (index % 2 == 0)
                              ? const Color.fromARGB(255, 16, 80, 98)
                              : Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              const Text(
                                "Smartpay Cards",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                "**** 1990",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 15,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.8,
                                      ),
                                    ),
                                    Transform.translate(
                                      offset: const Offset(-10, 0),
                                      child: CircleAvatar(
                                        radius: 15,
                                        backgroundColor: Colors.white
                                            .withOpacity(0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ================= LINE CHART CARD ====================
              Container(
                width: double.maxFinite,
                height: 350,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      "Total Spending",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "₦6,345.00",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const TimeOptionsRow(),
                    const SizedBox(height: 16),

                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
                                reservedSize: 22,
                                getTitlesWidget: (value, meta) {
                                  const tiles = [
                                    'S',
                                    'M',
                                    'T',
                                    'W',
                                    'T',
                                    'F',
                                    'S',
                                  ];
                                  final index = value.toInt();

                                  if (index >= 0 && index < tiles.length) {
                                    return Text(
                                      tiles[index],
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    );
                                  }
                                  return const Text("");
                                },
                              ),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 2),
                                FlSpot(1, 1),
                                FlSpot(2, 4),
                                FlSpot(4, 3),
                                FlSpot(6, 6),
                              ],
                              isCurved: true,
                              color: Colors.teal,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.teal.withOpacity(0.25),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ================= TRANSACTION HEADER ====================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Transaction",
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: const [
                      Text(
                        "All",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down, color: Colors.teal),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Column(
                children: List.generate(
                  3,
                  (index) => ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color.fromARGB(255, 239, 243, 245),
                      child: Icon(Icons.payment_rounded, color: Colors.blue),
                    ),
                    title: const Text(
                      "Smart Pay UI Kit",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      "-₦45.99",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
