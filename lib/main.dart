import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dotted_line/dotted_line.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expenses Tracker App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Map<String, dynamic>> _expenses = [];
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedPaymentMethod;
  final List<String> _paymentMethods = ['👩 Visa Mimi', '🧔 Visa Dam', '💰 PayPal', '🧾 Check', '🏦 Bank Transfer'];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  void _loadExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String expensesJson = prefs.getString('expenses') ?? '[]';
    final List<dynamic> jsonDecoded = json.decode(expensesJson);
    setState(() {
      _expenses = jsonDecoded.map((expense) => Map<String, dynamic>.from(expense)).toList();
    });
  }

  void _saveExpenses() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String expensesJson = json.encode(_expenses);
    await prefs.setString('expenses', expensesJson);
  }

  void _confirmDelete(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this expense?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                setState(() {
                  _expenses.removeAt(index);
                });
                _saveExpenses();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showBottomSheet(BuildContext context, {int? index}) {
    bool isEditing = index != null;  // Check if an index is provided for editing
    Map<String, dynamic>? expense = isEditing ? _expenses[index!] : null;  // Safely access the expense if editing

    // Set initial values with null checks
    _priceController.text = isEditing && expense != null ? (expense['price'] ?? '').toString() : '';
    _descriptionController.text = isEditing && expense != null ? (expense['description'] ?? '') : '';
    _selectedPaymentMethod = isEditing && expense != null ? (expense['paymentMethod'] ?? _paymentMethods.first) : _paymentMethods.first;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,  // Make the bottom sheet scrollable
      builder: (BuildContext bc) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(bc).viewInsets.bottom),  // Adjust padding for the keyboard
            child: Wrap(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top:16.0),  // Adjust the padding value to suit your design needs
                  child: ListTile(
                    title: TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Enter price',
                        border: OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                  ),
                ),
                ListTile(
                  title: TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (e.g., shop name)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                ListTile(
                  title: DropdownButtonFormField<String>(
                    value: _selectedPaymentMethod,
                    decoration: InputDecoration(
                      labelText: 'Select payment method',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedPaymentMethod = newValue;
                      });
                    },
                    items: _paymentMethods.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                ListTile(
                  title: ElevatedButton(
                    onPressed: () {
                      if (_priceController.text.isNotEmpty && _selectedPaymentMethod != null) {
                        Map<String, dynamic> newExpense = {
                          'price': _priceController.text,
                          'description': _descriptionController.text,
                          'paymentMethod': _selectedPaymentMethod!,
                          'date': isEditing && expense != null ? (expense['date'] ?? DateTime.now().toIso8601String()) : DateTime.now().toIso8601String()
                        };

                        if (isEditing) {
                          setState(() {
                            _expenses[index!] = newExpense;  // Update existing entry
                          });
                        } else {
                          setState(() {
                            _expenses.insert(0, newExpense);  // Add new entry
                          });
                        }

                        _saveExpenses();
                        Navigator.pop(context);
                      }
                    },
                    child: Text(isEditing ? 'Save Changes' : 'Add Expense'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildListItem(BuildContext context, int index) {
    final expense = _expenses[index];
    final formattedDate = DateFormat('dd/MM').format(DateTime.parse(expense['date']));
    return Column(
      children: [
        Card(
          color: Colors.transparent,  // Remove background color
          elevation: 0,  // Remove shadow
          child: Container(
            padding: EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(expense['paymentMethod'].toString().toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[900])),
                    PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'Edit') {
                          _showBottomSheet(context, index: index);
                        } else if (result == 'Delete') {
                          _confirmDelete(context, index);
                        }
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'Edit',
                          child: Text('Edit'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'Delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
                Center(
                  child: Text(
                    '${expense['price']} €',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(expense['description'].toString().toUpperCase(), style: TextStyle(fontSize: 12, color: Colors.grey[900])),
                    Text(formattedDate, style: TextStyle(fontSize: 14, color: Colors.grey[900])),
                  ],
                ),
              ],
            ),
          ),
        ),
        DottedLine(
          direction: Axis.horizontal,
          lineLength: double.infinity,
          lineThickness: 2.0,
          dashLength: 10.0,
          dashColor: Color.fromARGB(255, 135, 135, 135),
          dashRadius: 5.0,
          dashGapLength: 20.0,
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Expenses Tracker"),
      ),
      body: _expenses.isEmpty
          ? Center(child: Text("No expenses added yet"))
          : ListView.builder(
              itemCount: _expenses.length,
              itemBuilder: (context, index) => _buildListItem(context, index),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBottomSheet(context),
        tooltip: 'Add Expense',
        child: Icon(Icons.add),
      ),
    );
  }
}
