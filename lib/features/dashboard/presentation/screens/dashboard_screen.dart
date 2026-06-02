import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:brand_dashboard/features/dashboard/presentation/providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(dashboardProvider),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (summary) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCards(summary: summary),
              const SizedBox(height: 24),
              if (summary.revenueByProduct.isNotEmpty) ...[
                const _SectionTitle(title: 'Ventas por Producto'),
                const SizedBox(height: 16),
                _RevenueBarChart(revenueByProduct: summary.revenueByProduct),
                const SizedBox(height: 24),
              ],
              if (summary.totalSales > 0) ...[
                const _SectionTitle(title: 'Estado de Pagos'),
                const SizedBox(height: 16),
                _PaymentDonutChart(distribution: summary.paymentDistribution),
                const SizedBox(height: 24),
              ],
              if (summary.topSupplyCosts.isNotEmpty) ...[
                const _SectionTitle(title: 'Top Costos de Insumos'),
                const SizedBox(height: 16),
                _SupplyCostChart(items: summary.topSupplyCosts),
                const SizedBox(height: 24),
              ],
              if (summary.totalSales == 0 && summary.topSupplyCosts.isEmpty)
                const _EmptyState(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  final DashboardSummary summary;
  const _SummaryCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _MetricCard(
          icon: Icons.attach_money,
          label: 'Ingresos',
          value: '\$${summary.totalRevenue.toStringAsFixed(0)}',
          color: Colors.green,
        )),
        const SizedBox(width: 12),
        Expanded(child: _MetricCard(
          icon: Icons.shopping_bag_outlined,
          label: 'Ventas',
          value: '${summary.totalSales}',
          color: Colors.blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _MetricCard(
          icon: Icons.pending_outlined,
          label: 'Pendientes',
          value: '${summary.pendingPayments}',
          color: Colors.orange,
        )),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: color,
            )),
            Text(label, style: const TextStyle(
              color: Colors.grey, fontSize: 11,
            )),
          ],
        ),
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  final Map<String, double> revenueByProduct;
  const _RevenueBarChart({required this.revenueByProduct});

  @override
  Widget build(BuildContext context) {
    final entries = revenueByProduct.entries.toList();
    final maxValue = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(BarChartData(
            maxY: maxValue * 1.2,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= entries.length) return const SizedBox();
                    final name = entries[index].key;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        name.length > 8 ? '${name.substring(0, 8)}...' : name,
                        style: const TextStyle(
                          fontSize: 10, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ),
            barGroups: entries.asMap().entries.map((entry) {
              return BarChartGroupData(
                x: entry.key,
                barRods: [BarChartRodData(
                  toY: entry.value.value,
                  color: Colors.blue,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6)),
                )],
              );
            }).toList(),
          )),
        ),
      ),
    );
  }
}

class _PaymentDonutChart extends StatelessWidget {
  final Map<String, int> distribution;
  const _PaymentDonutChart({required this.distribution});

  @override
  Widget build(BuildContext context) {
    final paid = distribution['paid'] ?? 0;
    final partial = distribution['partial'] ?? 0;
    final pending = distribution['pending'] ?? 0;
    final total = paid + partial + pending;
    if (total == 0) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: [
                  if (paid > 0) PieChartSectionData(
                    value: paid.toDouble(), color: Colors.green,
                    title: '$paid', radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.white),
                  ),
                  if (partial > 0) PieChartSectionData(
                    value: partial.toDouble(), color: Colors.orange,
                    title: '$partial', radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.white),
                  ),
                  if (pending > 0) PieChartSectionData(
                    value: pending.toDouble(), color: Colors.red,
                    title: '$pending', radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold,
                      color: Colors.white),
                  ),
                ],
              )),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Legend(color: Colors.green, label: 'Pagado ($paid)'),
                const SizedBox(height: 8),
                _Legend(color: Colors.orange, label: 'Abono ($partial)'),
                const SizedBox(height: 8),
                _Legend(color: Colors.red, label: 'Pendiente ($pending)'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

class _SupplyCostChart extends StatelessWidget {
  final List<dynamic> items;
  const _SupplyCostChart({required this.items});

  @override
  Widget build(BuildContext context) {
    final maxCost = items
        .map((i) => i.unitCost as double)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: items.map<Widget>((item) {
            final percentage = item.unitCost / maxCost;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.name,
                        style: const TextStyle(fontSize: 12)),
                      Text('\$${item.unitCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.withOpacity(0.2),
                    color: Colors.blue,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Sin datos todavía',
            style: TextStyle(color: Colors.grey)),
          SizedBox(height: 8),
          Text('Agrega insumos y registra ventas\npara ver tus métricas',
            style: TextStyle(color: Colors.grey, fontSize: 12),
            textAlign: TextAlign.center),
        ],
      ),
    );
  }
}