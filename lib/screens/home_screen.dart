import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'login_screen.dart';
import 'sms_sync_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedPeriod = 'current_month';

  final List<Map<String, String>> _periods = [
    {'value': 'current_week', 'label': 'Current Week'},
    {'value': 'current_month', 'label': 'Current Month'},
    {'value': 'last_month', 'label': 'Last Month'},
    {'value': 'last_3_months', 'label': 'Last 3 Months'},
    {'value': 'last_6_months', 'label': 'Last 6 Months'},
    {'value': 'last_9_months', 'label': 'Last 9 Months'},
    {'value': 'last_year', 'label': 'Last Year'},
    {'value': 'last_2_years', 'label': 'Last 2 Years'},
    {'value': 'last_5_years', 'label': 'Last 5 Years'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final expenseProvider =
        Provider.of<ExpenseProvider>(context, listen: false);
    await expenseProvider.loadExpenseSummary(_selectedPeriod);
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final expenseProvider = Provider.of<ExpenseProvider>(context);
    final currencyFormat = NumberFormat.currency(
      symbol: authProvider.user?.defaultCurrency ?? 'KES',
      decimalDigits: 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SmsSyncScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: expenseProvider.isLoading && expenseProvider.summary == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              child: Text(
                                authProvider.user?.name[0].toUpperCase() ?? 'U',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    authProvider.user?.name ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    authProvider.user?.email ?? '',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Currency: ${authProvider.user?.defaultCurrency}',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Period Filter
                    DropdownButtonFormField<String>(
                      value: _selectedPeriod,
                      decoration: const InputDecoration(
                        labelText: 'Period',
                        border: OutlineInputBorder(),
                      ),
                      items: _periods.map((period) {
                        return DropdownMenuItem(
                          value: period['value'],
                          child: Text(period['label']!),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPeriod = value;
                          });
                          _loadData();
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Summary Card
                    if (expenseProvider.summary != null) ...[
                      Card(
                        color: Theme.of(context).primaryColor,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Expenses',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                currencyFormat.format(
                                  expenseProvider.summary!['summary']
                                      ['total_amount'],
                                ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Transactions',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      Text(
                                        '${expenseProvider.summary!['summary']['transaction_count']}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Average',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                      Text(
                                        currencyFormat.format(
                                          expenseProvider.summary!['summary']
                                              ['average_per_transaction'],
                                        ),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Recent Expenses
                      Text(
                        'Recent Expenses',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),

                      if (expenseProvider.expenses.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No expenses for this period',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: expenseProvider.expenses.length,
                          itemBuilder: (context, index) {
                            final expense = expenseProvider.expenses[index];
                            return ExpenseListItem(
                              expense: expense,
                              currencyFormat: currencyFormat,
                              onDelete: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Expense'),
                                    content: const Text(
                                        'Are you sure you want to delete this expense?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  final success = await expenseProvider
                                      .deleteExpense(expense.id);
                                  if (success && mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Expense deleted')),
                                    );
                                  }
                                }
                              },
                            );
                          },
                        ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class ExpenseListItem extends StatelessWidget {
  final Expense expense;
  final NumberFormat currencyFormat;
  final VoidCallback onDelete;

  const ExpenseListItem({
    Key? key,
    required this.expense,
    required this.currencyFormat,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            expense.source == 'bank'
                ? Icons.account_balance
                : Icons.phone_android,
          ),
        ),
        title: Text(
          currencyFormat.format(expense.convertedAmount),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (expense.isDifferentCurrency())
              Text(
                '${expense.originalCurrency} ${expense.originalAmount.toStringAsFixed(2)} @ ${expense.conversionRate.toStringAsFixed(4)}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            Text(
              DateFormat('MMM dd, yyyy HH:mm').format(expense.transactionDate),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            if (expense.reference != null)
              Text(
                'Ref: ${expense.reference}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: onDelete,
        ),
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Transaction Details'),
              content: SingleChildScrollView(
                child: Text(expense.message),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
