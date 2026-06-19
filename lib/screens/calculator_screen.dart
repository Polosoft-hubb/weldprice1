import 'dart:math';
import 'package:flutter/material.dart';

enum CalculatorType {
  standard,
  diagonal,
  circleArea,
  circumference,
  roundPipeVolume,
  rectPipeVolume,
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  CalculatorType _selectedType = CalculatorType.standard;

  // --- Standard Calculator State ---
  String _stdDisplay = '0';
  String _stdHistory = '';
  double? _firstOperand;
  String? _operator;
  bool _shouldResetDisplay = false;

  void _stdPressDigit(String digit) {
    setState(() {
      if (_stdDisplay == '0' || _shouldResetDisplay) {
        _stdDisplay = digit;
        _shouldResetDisplay = false;
      } else {
        _stdDisplay += digit;
      }
    });
  }

  void _stdPressDecimal() {
    setState(() {
      if (_shouldResetDisplay) {
        _stdDisplay = '0.';
        _shouldResetDisplay = false;
        return;
      }
      if (!_stdDisplay.contains('.')) {
        _stdDisplay += '.';
      }
    });
  }

  void _stdPressClear() {
    setState(() {
      _stdDisplay = '0';
      _stdHistory = '';
      _firstOperand = null;
      _operator = null;
      _shouldResetDisplay = false;
    });
  }

  void _stdPressBackspace() {
    setState(() {
      if (_shouldResetDisplay) {
        _stdDisplay = '0';
        _shouldResetDisplay = false;
        return;
      }
      if (_stdDisplay.length > 1) {
        _stdDisplay = _stdDisplay.substring(0, _stdDisplay.length - 1);
        if (_stdDisplay == '-') {
          _stdDisplay = '0';
        }
      } else {
        _stdDisplay = '0';
      }
    });
  }

  void _stdPressNegate() {
    setState(() {
      if (_stdDisplay == '0') return;
      if (_stdDisplay.startsWith('-')) {
        _stdDisplay = _stdDisplay.substring(1);
      } else {
        _stdDisplay = '-$_stdDisplay';
      }
    });
  }

  void _stdPressPercent() {
    setState(() {
      final double? val = double.tryParse(_stdDisplay);
      if (val != null) {
        final result = val / 100.0;
        if (result == result.toInt()) {
          _stdDisplay = result.toInt().toString();
        } else {
          _stdDisplay = result.toStringAsFixed(8).replaceAll(RegExp(r'\.?0+$'), '');
        }
      }
    });
  }

  void _stdPressOperator(String op) {
    setState(() {
      final double? value = double.tryParse(_stdDisplay);
      if (value != null) {
        if (_firstOperand != null && _operator != null && !_shouldResetDisplay) {
          _stdPressEqual();
          _firstOperand = double.tryParse(_stdDisplay);
        } else {
          _firstOperand = value;
        }
        _operator = op;
        _stdHistory = '$_stdDisplay $op';
        _shouldResetDisplay = true;
      }
    });
  }

  void _stdPressEqual() {
    if (_operator == null || _firstOperand == null) return;
    setState(() {
      final double? secondOperand = double.tryParse(_stdDisplay);
      if (secondOperand != null) {
        double result = 0.0;
        switch (_operator) {
          case '+':
            result = _firstOperand! + secondOperand;
            break;
          case '-':
            result = _firstOperand! - secondOperand;
            break;
          case '*':
            result = _firstOperand! * secondOperand;
            break;
          case '/':
            result = secondOperand != 0 ? _firstOperand! / secondOperand : 0.0;
            break;
        }
        
        _stdHistory = '$_firstOperand $_operator $secondOperand =';
        
        if (result == result.toInt()) {
          _stdDisplay = result.toInt().toString();
        } else {
          _stdDisplay = result.toStringAsFixed(6).replaceAll(RegExp(r'\.?0+$'), '');
        }
        _firstOperand = null;
        _operator = null;
        _shouldResetDisplay = true;
      }
    });
  }

  // --- Rectangle Diagonal State ---
  final TextEditingController _diagSideAController = TextEditingController();
  final TextEditingController _diagSideBController = TextEditingController();
  double _diagResultMm = 0.0;

  void _calcDiagonal() {
    final a = double.tryParse(_diagSideAController.text.replaceAll(',', '.')) ?? 0.0;
    final b = double.tryParse(_diagSideBController.text.replaceAll(',', '.')) ?? 0.0;
    setState(() {
      _diagResultMm = sqrt(a * a + b * b);
    });
  }

  // --- Circle Area State ---
  final TextEditingController _circleInputController = TextEditingController();
  bool _circleUseDiameter = true; // true = Diameter, false = Radius
  double _circleAreaMm2 = 0.0;

  void _calcCircleArea() {
    final val = double.tryParse(_circleInputController.text.replaceAll(',', '.')) ?? 0.0;
    final r = _circleUseDiameter ? val / 2.0 : val;
    setState(() {
      _circleAreaMm2 = pi * r * r;
    });
  }

  // --- Circumference State ---
  final TextEditingController _circumInputController = TextEditingController();
  bool _circumUseDiameter = true;
  double _circumLengthMm = 0.0;

  void _calcCircumference() {
    final val = double.tryParse(_circumInputController.text.replaceAll(',', '.')) ?? 0.0;
    final r = _circumUseDiameter ? val / 2.0 : val;
    setState(() {
      _circumLengthMm = 2.0 * pi * r;
    });
  }

  // --- Round Pipe Volume State ---
  final TextEditingController _rpDiameterController = TextEditingController();
  final TextEditingController _rpWallController = TextEditingController();
  final TextEditingController _rpLengthController = TextEditingController();
  double _rpCapacityM3 = 0.0;

  void _calcRoundPipe() {
    final dMm = double.tryParse(_rpDiameterController.text.replaceAll(',', '.')) ?? 0.0;
    final tMm = double.tryParse(_rpWallController.text.replaceAll(',', '.')) ?? 0.0;
    final lM = double.tryParse(_rpLengthController.text.replaceAll(',', '.')) ?? 0.0;

    final d = dMm / 1000.0;
    final t = tMm / 1000.0;
    final l = lM;

    final rIn = (d - 2.0 * t) / 2.0;
    final areaIn = rIn > 0 ? pi * rIn * rIn : 0.0;

    setState(() {
      _rpCapacityM3 = areaIn * l;
    });
  }

  // --- Rectangular Pipe Volume State ---
  final TextEditingController _recWidthController = TextEditingController();
  final TextEditingController _recHeightController = TextEditingController();
  final TextEditingController _recWallController = TextEditingController();
  final TextEditingController _recLengthController = TextEditingController();
  double _recCapacityM3 = 0.0;

  void _calcRectPipe() {
    final wMm = double.tryParse(_recWidthController.text.replaceAll(',', '.')) ?? 0.0;
    final hMm = double.tryParse(_recHeightController.text.replaceAll(',', '.')) ?? 0.0;
    final tMm = double.tryParse(_recWallController.text.replaceAll(',', '.')) ?? 0.0;
    final lM = double.tryParse(_recLengthController.text.replaceAll(',', '.')) ?? 0.0;

    final w = wMm / 1000.0;
    final h = hMm / 1000.0;
    final t = tMm / 1000.0;
    final l = lM;

    final wIn = w - 2.0 * t;
    final hIn = h - 2.0 * t;
    final areaIn = (wIn > 0 && hIn > 0) ? wIn * hIn : 0.0;

    setState(() {
      _recCapacityM3 = areaIn * l;
    });
  }

  @override
  void dispose() {
    _diagSideAController.dispose();
    _diagSideBController.dispose();
    _circleInputController.dispose();
    _circumInputController.dispose();
    _rpDiameterController.dispose();
    _rpWallController.dispose();
    _rpLengthController.dispose();
    _recWidthController.dispose();
    _recHeightController.dispose();
    _recWallController.dispose();
    _recLengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
      ),
      body: Column(
        children: [
          // Selector dropdown at the top
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            color: const Color(0xFF161616),
            child: DropdownButtonFormField<CalculatorType>(
              value: _selectedType,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: const [
                DropdownMenuItem(
                  value: CalculatorType.standard,
                  child: Text('Обычный калькулятор'),
                ),
                DropdownMenuItem(
                  value: CalculatorType.diagonal,
                  child: Text('Диагональ прямоугольника'),
                ),
                DropdownMenuItem(
                  value: CalculatorType.circleArea,
                  child: Text('Площадь круга'),
                ),
                DropdownMenuItem(
                  value: CalculatorType.circumference,
                  child: Text('Длина окружности'),
                ),
                DropdownMenuItem(
                  value: CalculatorType.roundPipeVolume,
                  child: Text('Объем круглой трубы'),
                ),
                DropdownMenuItem(
                  value: CalculatorType.rectPipeVolume,
                  child: Text('Объем профильной трубы'),
                ),
              ],
              onChanged: (type) {
                if (type != null) {
                  setState(() {
                    _selectedType = type;
                  });
                }
              },
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _buildSelectedCalculator(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCalculator() {
    switch (_selectedType) {
      case CalculatorType.standard:
        return _buildStandardCalculator();
      case CalculatorType.diagonal:
        return _buildDiagonalCalculator();
      case CalculatorType.circleArea:
        return _buildCircleAreaCalculator();
      case CalculatorType.circumference:
        return _buildCircumferenceCalculator();
      case CalculatorType.roundPipeVolume:
        return _buildRoundPipeCalculator();
      case CalculatorType.rectPipeVolume:
        return _buildRectPipeCalculator();
    }
  }

  // 1. Standard Calculator Layout
  Widget _buildStandardCalculator() {
    Widget calcButton(dynamic label, {Color? color, Color? textColor, VoidCallback? onPressed}) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            height: 70,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? const Color(0xFF2C2C2C),
                foregroundColor: textColor ?? Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: EdgeInsets.zero,
              ),
              child: label is Widget
                  ? label
                  : Text(label.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Display with active operation visible
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _stdHistory,
                  style: const TextStyle(fontSize: 18, color: Colors.grey, fontFamily: 'monospace'),
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: Text(
                  _stdDisplay,
                  style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Grid
        Column(
          children: [
            Row(
              children: [
                calcButton('C', color: Colors.redAccent, textColor: Colors.white, onPressed: _stdPressClear),
                calcButton(const Icon(Icons.backspace_outlined, size: 22), color: const Color(0xFF3C3C3C), textColor: Colors.white, onPressed: _stdPressBackspace),
                calcButton('%', color: const Color(0xFF3C3C3C), textColor: Colors.white, onPressed: _stdPressPercent),
                calcButton('/', color: const Color(0xFFFF4081).withOpacity(0.15), textColor: const Color(0xFFFF4081), onPressed: () => _stdPressOperator('/')),
              ],
            ),
            Row(
              children: [
                calcButton('7', onPressed: () => _stdPressDigit('7')),
                calcButton('8', onPressed: () => _stdPressDigit('8')),
                calcButton('9', onPressed: () => _stdPressDigit('9')),
                calcButton('*', color: const Color(0xFFFF4081).withOpacity(0.15), textColor: const Color(0xFFFF4081), onPressed: () => _stdPressOperator('*')),
              ],
            ),
            Row(
              children: [
                calcButton('4', onPressed: () => _stdPressDigit('4')),
                calcButton('5', onPressed: () => _stdPressDigit('5')),
                calcButton('6', onPressed: () => _stdPressDigit('6')),
                calcButton('-', color: const Color(0xFFFF4081).withOpacity(0.15), textColor: const Color(0xFFFF4081), onPressed: () => _stdPressOperator('-')),
              ],
            ),
            Row(
              children: [
                calcButton('1', onPressed: () => _stdPressDigit('1')),
                calcButton('2', onPressed: () => _stdPressDigit('2')),
                calcButton('3', onPressed: () => _stdPressDigit('3')),
                calcButton('+', color: const Color(0xFFFF4081).withOpacity(0.15), textColor: const Color(0xFFFF4081), onPressed: () => _stdPressOperator('+')),
              ],
            ),
            Row(
              children: [
                calcButton('+/-', color: const Color(0xFF3C3C3C), textColor: Colors.white, onPressed: _stdPressNegate),
                calcButton('0', onPressed: () => _stdPressDigit('0')),
                calcButton('.', onPressed: _stdPressDecimal),
                calcButton('=', color: const Color(0xFFFF4081), textColor: Colors.black, onPressed: _stdPressEqual),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 2. Diagonal Calculator Layout
  Widget _buildDiagonalCalculator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расчет диагонали прямоугольника',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _diagSideAController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Длина (мм)',
            hintText: 'например, 3000',
          ),
          onChanged: (_) => _calcDiagonal(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _diagSideBController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Ширина (мм)',
            hintText: 'например, 4000',
          ),
          onChanged: (_) => _calcDiagonal(),
        ),
        const SizedBox(height: 24),
        _buildResultCard(
          title: 'Диагональ прямоугольника',
          outputs: [
            '${_diagResultMm.toStringAsFixed(1)} мм',
            '${(_diagResultMm / 1000.0).toStringAsFixed(3)} м',
          ],
        ),
      ],
    );
  }

  // 3. Circle Area Calculator Layout
  Widget _buildCircleAreaCalculator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расчет площади круга',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Диаметр')),
                selected: _circleUseDiameter,
                onSelected: (val) {
                  setState(() {
                    _circleUseDiameter = val;
                  });
                  _calcCircleArea();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Радиус')),
                selected: !_circleUseDiameter,
                onSelected: (val) {
                  setState(() {
                    _circleUseDiameter = !val;
                  });
                  _calcCircleArea();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _circleInputController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _circleUseDiameter ? 'Диаметр (мм)' : 'Радиус (мм)',
            hintText: 'например, 100',
          ),
          onChanged: (_) => _calcCircleArea(),
        ),
        const SizedBox(height: 24),
        _buildResultCard(
          title: 'Площадь круга',
          outputs: [
            '${_circleAreaMm2.toStringAsFixed(1)} мм²',
            '${(_circleAreaMm2 / 1000000.0).toStringAsFixed(5)} м²',
          ],
        ),
      ],
    );
  }

  // 4. Circumference Calculator Layout
  Widget _buildCircumferenceCalculator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расчет длины окружности',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Диаметр')),
                selected: _circumUseDiameter,
                onSelected: (val) {
                  setState(() {
                    _circumUseDiameter = val;
                  });
                  _calcCircumference();
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ChoiceChip(
                label: const Center(child: Text('Радиус')),
                selected: !_circumUseDiameter,
                onSelected: (val) {
                  setState(() {
                    _circumUseDiameter = !val;
                  });
                  _calcCircumference();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _circumInputController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _circumUseDiameter ? 'Диаметр (мм)' : 'Радиус (мм)',
            hintText: 'например, 100',
          ),
          onChanged: (_) => _calcCircumference(),
        ),
        const SizedBox(height: 24),
        _buildResultCard(
          title: 'Длина окружности',
          outputs: [
            '${_circumLengthMm.toStringAsFixed(1)} мм',
            '${(_circumLengthMm / 1000.0).toStringAsFixed(3)} м',
          ],
        ),
      ],
    );
  }

  // 5. Round Pipe Volume Layout
  Widget _buildRoundPipeCalculator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расчет объема круглой трубы',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _rpDiameterController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Наружный диаметр D (мм)',
            hintText: 'например, 57',
          ),
          onChanged: (_) => _calcRoundPipe(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rpWallController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Толщина стенки t (мм)',
            hintText: 'например, 3',
          ),
          onChanged: (_) => _calcRoundPipe(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _rpLengthController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Длина трубы L (м)',
            hintText: 'например, 6',
          ),
          onChanged: (_) => _calcRoundPipe(),
        ),
        const SizedBox(height: 24),
        _buildResultCard(
          title: 'Результаты расчета трубы',
          outputs: [
            'Внутренний объем: ${_rpCapacityM3.toStringAsFixed(5)} м³',
            'Объем в литрах: ${(_rpCapacityM3 * 1000.0).toStringAsFixed(2)} л',
          ],
        ),
      ],
    );
  }

  // 6. Rectangular Pipe Volume Layout
  Widget _buildRectPipeCalculator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расчет объема профильной трубы',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _recWidthController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Ширина А (мм)',
                  hintText: 'например, 80',
                ),
                onChanged: (_) => _calcRectPipe(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _recHeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Высота B (мм)',
                  hintText: 'например, 60',
                ),
                onChanged: (_) => _calcRectPipe(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _recWallController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Толщина стенки t (мм)',
            hintText: 'например, 4',
          ),
          onChanged: (_) => _calcRectPipe(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _recLengthController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Длина трубы L (м)',
            hintText: 'например, 6',
          ),
          onChanged: (_) => _calcRectPipe(),
        ),
        const SizedBox(height: 24),
        _buildResultCard(
          title: 'Результаты расчета трубы',
          outputs: [
            'Внутренний объем: ${_recCapacityM3.toStringAsFixed(5)} м³',
            'Объем в литрах: ${(_recCapacityM3 * 1000.0).toStringAsFixed(2)} л',
          ],
        ),
      ],
    );
  }

  // Result card helper
  Widget _buildResultCard({required String title, required List<String> outputs}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFC2185B), Color(0xFFFF4081)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4081).withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          ...outputs.map((text) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          )),
        ],
      ),
    );
  }
}
