import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:uangnya/model/transaction.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Transaction> _transactions = [];
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  bool _isExpense = true;
  DateTime _selectedDate = DateTime.now();
  int _selectedMonthIndex = 0; // Track selected month index

  @override
  void initState() {
    _isExpense = true;
    super.initState();
    _loadTransactions();
  }

  Future<void> _saveTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = jsonEncode(_transactions.map((t) => t.toJson()).toList());
    await prefs.setString('transactions', transactionsJson);
  }

  Future<void> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final transactionsJson = prefs.getString('transactions');
    
    if (transactionsJson != null) {
      final List<dynamic> decodedList = jsonDecode(transactionsJson);
      setState(() {
        _transactions.clear();
        _transactions.addAll(
          decodedList.map((item) => Transaction.fromJson(item)).toList()
        );
      });
    }
  }

  void _addNewTransaction() {
    if (titleController.text.isEmpty || amountController.text.isEmpty || double.parse(amountController.text) <= 0) {
      return;
    }

    final newTransaction = Transaction(
      id: DateTime.now().toString(),
      title: titleController.text,
      amount: double.parse(amountController.text),
      date: _selectedDate,
      isExpense: _isExpense,
    );

    setState(() {
      _transactions.add(newTransaction);
      _transactions.sort((a, b) => b.date.compareTo(a.date));
    });

    _saveTransactions();
    titleController.clear();
    amountController.clear();
    Navigator.of(context).pop();
  }

  void _deleteTransaction(String id) {
    setState(() {
      _transactions.removeWhere((tx) => tx.id == id);
    });
    _saveTransactions();
  }

  void _clearAllTransactions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Semua Transaksi'),
        content: Text('Anda yakin ingin menghapus semua transaksi? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
            ),
            child: Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _transactions.clear();
      });
      _saveTransactions();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Semua transaksi telah dihapus'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  void _startAddNewTransaction(BuildContext ctx) {
    bool localIsExpense = _isExpense;
    
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return GestureDetector(
              onTap: () {},
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  left: 20,
                  right: 20,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Tambah Transaksi Baru',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Judul',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.title, color: Colors.green),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                      controller: titleController,
                    ),
                    SizedBox(height: 15),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Jumlah',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.attach_money, color: Colors.green),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.green, width: 2),
                        ),
                      ),
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                    SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: SwitchListTile(
                        activeTrackColor: Colors.red.withOpacity(0.6),
                        activeColor: Colors.red,
                        inactiveTrackColor: Colors.green.withOpacity(0.6),
                        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                        thumbColor: WidgetStateProperty.resolveWith(
                          (Set<WidgetState> states) => localIsExpense ? Colors.red : Colors.green,
                        ),
                        trackColor: WidgetStateProperty.resolveWith(
                          (Set<WidgetState> states) => localIsExpense 
                              ? Colors.red.withOpacity(0.3) 
                              : Colors.green.withOpacity(0.3),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              localIsExpense ? Icons.arrow_downward : Icons.arrow_upward,
                              color: localIsExpense ? Colors.red : Colors.green,
                            ),
                            SizedBox(width: 10),
                            Text(
                              localIsExpense ? 'Pengeluaran' : 'Pemasukan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: localIsExpense ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                        value: localIsExpense,
                        onChanged: (val) {
                          setModalState(() {
                            localIsExpense = val;
                          });
                          setState(() {
                            _isExpense = val;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 15),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              DateFormat('dd MMMM yyyy').format(_selectedDate),
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          TextButton(
                            onPressed: _presentDatePicker,
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Pilih Tanggal',
                              style: TextStyle(
                                fontWeight: FontWeight.bold, 
                                color: Colors.green
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: localIsExpense ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          _isExpense = localIsExpense;
                          _addNewTransaction();
                        },
                        child: Text(
                          'Tambah Transaksi',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

  double get _totalBalance {
    return _transactions.fold(0.0, (sum, tx) {
      if (tx.isExpense) {
        return sum - tx.amount;
      } else {
        return sum + tx.amount;
      }
    });
  }

  double get _totalIncome {
    return _transactions.where((tx) => !tx.isExpense).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get _totalExpense {
    return _transactions.where((tx) => tx.isExpense).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Get unique months from transactions as a sorted list
  List<DateTime> get _uniqueMonths {
    final Set<String> monthSet = {};
    final List<DateTime> months = [];
    
    for (var tx in _transactions) {
      final monthKey = DateFormat('yyyy-MM').format(tx.date);
      if (!monthSet.contains(monthKey)) {
        monthSet.add(monthKey);
        // Create DateTime for first day of month
        months.add(DateTime(tx.date.year, tx.date.month, 1));
      }
    }
    
    // Sort months in descending order (newest first)
    months.sort((a, b) => b.compareTo(a));
    
    // If no transactions, add current month
    if (months.isEmpty) {
      final now = DateTime.now();
      months.add(DateTime(now.year, now.month, 1));
    }
    
    return months;
  }

  // Get transactions for a specific month
  List<Transaction> _getTransactionsForMonth(DateTime month) {
    return _transactions.where((tx) => 
      tx.date.year == month.year && tx.date.month == month.month
    ).toList();
  }

  // Calculate monthly balance
  double _getMonthlyBalance(DateTime month) {
    final monthlyTransactions = _getTransactionsForMonth(month);
    return monthlyTransactions.fold(0.0, (sum, tx) {
      if (tx.isExpense) {
        return sum - tx.amount;
      } else {
        return sum + tx.amount;
      }
    });
  }

  // Calculate monthly income
  double _getMonthlyIncome(DateTime month) {
    final monthlyTransactions = _getTransactionsForMonth(month);
    return monthlyTransactions.where((tx) => !tx.isExpense).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  // Calculate monthly expense
  double _getMonthlyExpense(DateTime month) {
    final monthlyTransactions = _getTransactionsForMonth(month);
    return monthlyTransactions.where((tx) => tx.isExpense).fold(0.0, (sum, tx) => sum + tx.amount);
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final List<DateTime> months = _uniqueMonths;
    final pageController = PageController(initialPage: _selectedMonthIndex);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.account_balance_wallet, color: Colors.green),
            ),
            SizedBox(width: 10),
            Text(
              'Uangnya', 
              style: TextStyle(
                color: Colors.green, 
                fontWeight: FontWeight.bold, 
                fontSize: 22
              ),
            ),
          ],
        ),
        actions: [
          _transactions.isNotEmpty 
            ? Tooltip(
                message: 'Hapus Semua Transaksi',
                child: IconButton(
                  icon: Icon(Icons.delete_sweep, color: Colors.red),
                  onPressed: _clearAllTransactions,
                ),
              )
            : SizedBox(),
        ],
      ),
      body: Column(
        children: [
          // Month Selector
          if (months.length > 1)
            Container(
              height: 60,
              margin: EdgeInsets.only(top: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: months.length,
                padding: EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (ctx, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedMonthIndex = index;
                        });
                        pageController.animateToPage(
                          index,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedMonthIndex == index 
                            ? Colors.green 
                            : Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: _selectedMonthIndex == index 
                            ? [BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 5,
                                offset: Offset(0, 2),
                              )] 
                            : null,
                        ),
                        child: Center(
                          child: Text(
                            DateFormat('MMMM yyyy').format(months[index]),
                            style: TextStyle(
                              color: _selectedMonthIndex == index ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          
          // Balance Card
          Padding(
            padding: EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade500, Colors.green.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          months.length > 1 && _selectedMonthIndex < months.length
                              ? 'Saldo ${DateFormat('MMMM yyyy').format(months[_selectedMonthIndex])}'
                              : 'Saldo Total',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        Icon(Icons.account_balance, color: Colors.white.withOpacity(0.9)),
                      ],
                    ),
                    SizedBox(height: 15),
                    Text(
                      months.length > 1 && _selectedMonthIndex < months.length
                          ? _formatCurrency(_getMonthlyBalance(months[_selectedMonthIndex]))
                          : _formatCurrency(_totalBalance),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Income Card
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_upward, color: Colors.white, size: 18),
                                    SizedBox(width: 5),
                                    Text(
                                      'Pemasukan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  months.length > 1 && _selectedMonthIndex < months.length
                                      ? _formatCurrency(_getMonthlyIncome(months[_selectedMonthIndex]))
                                      : _formatCurrency(_totalIncome),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        // Expense Card
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward, color: Colors.white, size: 18),
                                    SizedBox(width: 5),
                                    Text(
                                      'Pengeluaran',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text(
                                  months.length > 1 && _selectedMonthIndex < months.length
                                      ? _formatCurrency(_getMonthlyExpense(months[_selectedMonthIndex]))
                                      : _formatCurrency(_totalExpense),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Transactions Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaksi Terbaru',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                months.length > 1 && _selectedMonthIndex < months.length
                    ? Text(
                        DateFormat('MMMM yyyy').format(months[_selectedMonthIndex]),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Text(
                        'Semua Waktu',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
              ],
            ),
          ),
          
          // Transactions PageView
          Expanded(
            child: PageView.builder(
              controller: pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedMonthIndex = index;
                });
              },
              itemCount: months.length,
              itemBuilder: (ctx, monthIndex) {
                final monthlyTransactions = _getTransactionsForMonth(months[monthIndex]);
                
                return monthlyTransactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 70,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 20),
                            Text(
                              'Belum ada transaksi',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'di bulan ${DateFormat('MMMM yyyy').format(months[monthIndex])}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton.icon(
                              onPressed: () => _startAddNewTransaction(context),
                              icon: Icon(Icons.add),
                              label: Text('Tambah Transaksi Baru'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: monthlyTransactions.length,
                        itemBuilder: (ctx, index) {
                          final tx = monthlyTransactions[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 10),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(4),
                              child: ListTile(
                                leading: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: tx.isExpense 
                                        ? Colors.red.withOpacity(0.2) 
                                        : Colors.green.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      tx.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                                      color: tx.isExpense ? Colors.red : Colors.green,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  tx.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  DateFormat('dd MMMM yyyy').format(tx.date),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                trailing: Container(
                                  width: 100,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${tx.isExpense ? "-" : "+"} ${_formatCurrency(tx.amount)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: tx.isExpense ? Colors.red : Colors.green,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, size: 20),
                                        color: Colors.grey[400],
                                        onPressed: () => _deleteTransaction(tx.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 60,
        width: 60,
        child: FloatingActionButton(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          elevation: 5,
          child: Icon(Icons.add, size: 30),
          onPressed: () => _startAddNewTransaction(context),
        ),
      ),
    );
  }
}