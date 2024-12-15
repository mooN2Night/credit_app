import 'package:flutter/material.dart';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const CreditCalculatorHomePage(title: 'Credit Calculator'),
    );
  }
}

class CreditCalculatorHomePage extends StatefulWidget {
  const CreditCalculatorHomePage({super.key, required this.title});

  final String title;

  @override
  State<CreditCalculatorHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<CreditCalculatorHomePage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _loanAmountController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _loanTermController;

  String _paymentType = 'Аннуитетный';
  final List<String> _paymentTypeList = ['Аннуитетный', 'Дифференцированный'];
  double? _monthlyPayment;
  double? _totalPayment;
  double? _overpayment;

  @override
  void initState() {
    super.initState();
    _loanAmountController = TextEditingController();
    _interestRateController = TextEditingController();
    _loanTermController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                TextFormField(
                  controller: _loanAmountController,
                  decoration: const InputDecoration(labelText: 'Сумма кредита'),
                  keyboardType: TextInputType.number,
                  validator: _loanAmountValidator,
                ),
                TextFormField(
                  controller: _interestRateController,
                  decoration: const InputDecoration(
                    labelText: 'Процентная ставка (годовая)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _interestRateValidator,
                ),
                TextFormField(
                  controller: _loanTermController,
                  decoration: const InputDecoration(
                    labelText: 'Срок кредита (в месяцах)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: _loanTermValidator,
                ),
                DropdownButtonFormField(
                  value: _paymentType,
                  decoration: const InputDecoration(labelText: 'Тип платежа'),
                  items: _paymentTypeList
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _paymentType = value!;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (_monthlyPayment != null && _totalPayment != null && _overpayment != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ежемесячный платеж: ${_monthlyPayment!.toStringAsFixed(2)} ₽'),
                      Text('Общая сумма выплат: ${_totalPayment!.toStringAsFixed(2)} ₽'),
                      Text('Переплата: ${_overpayment!.toStringAsFixed(2)} ₽'),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _calculate,
        child: const Icon(Icons.calculate_outlined),
      ),
    );
  }

  void _calculate() {
    if (_formKey.currentState!.validate()) {
      final double loanAmount = double.parse(_loanAmountController.text);
      final double annualInterestRate =
          double.parse(_interestRateController.text) / 100;
      final int loanTermMonths = int.parse(_loanTermController.text);
      final bool isAnnuity = _paymentType == 'Аннуитетный';

      /// Аннуитетный: Х = С * К, где X — аннуитетный платеж, С — сумма кредита,
      /// К — коэффициент аннуитета. Коэффициент аннуитета считается так:
      /// К = (М * (1 + М) ^ S) / ((1 + М) ^ S — 1), где М — месячная процентная
      /// ставка по кредиту, S — срок кредита в месяцах.
      if (isAnnuity) {
        /// месячная процентная ставка
        final double monthlyInterestRate = annualInterestRate / 12;

        /// коэффициент аннуитета
        final double annuityFactor = (monthlyInterestRate *
                pow(1 + monthlyInterestRate, loanTermMonths)) /
            (pow(1 + monthlyInterestRate, loanTermMonths) - 1);

        _monthlyPayment = loanAmount * annuityFactor;

        /// Дифференцированный формула: DP = s/n + OD * i, OD = s - s/n * m где:
        /// DP – дифференцированный платеж; s – первоначальная сумма кредита;
        /// n - количество процентных периодов во всем сроке кредита;
        /// OD - остаток долга по кредиту на дату расчета DP;
        /// i - месячная процентная ставка; m - номер текущего месяца
      } else {
        /// основная часть платежа - s/n
        _monthlyPayment = loanAmount / loanTermMonths;

        _totalPayment = 0;
        for (int i = 0; i < loanTermMonths; i++) {
          ///  - OD
          _totalPayment = (_totalPayment ?? 0) +
              /// общий платеж за месяц
              _monthlyPayment! +
              /// проценты на остаток задолженности за каждый месяц - OD
              (loanAmount - _monthlyPayment! * i) * (annualInterestRate / 12);
        }

        /// переплата
        _overpayment = _totalPayment! - loanAmount;
      }

      if (_monthlyPayment != null) {
        _totalPayment = _totalPayment ?? _monthlyPayment! * loanTermMonths;
        _overpayment = _totalPayment! - loanAmount;
      }

      setState(() {});
    }
  }

  String? _loanTermValidator(value) {
    if (value == null ||
        value.isEmpty ||
        int.tryParse(value) == null ||
        int.parse(value) <= 0) {
      return 'Введите корректный срок';
    }
    return null;
  }

  String? _interestRateValidator(value) {
    if (value == null ||
        value.isEmpty ||
        double.tryParse(value) == null ||
        double.parse(value) <= 0) {
      return 'Введите корректную ставку';
    }
    return null;
  }

  String? _loanAmountValidator(value) {
    if (value == null ||
        value.isEmpty ||
        double.tryParse(value) == null ||
        double.parse(value) <= 0) {
      return 'Введите корректную сумму';
    }
    return null;
  }
}
