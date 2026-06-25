import 'dart:math';
import 'package:flutter/material.dart';

enum CalculatorType {
  standard,
  diagonal,
  circleArea,
  circumference,
  roundPipeVolume,
  rectPipeVolume,
  beamDeflection,
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

  // --- Beam Deflection State ---
  final TextEditingController _beamSpanController = TextEditingController(text: '3500');
  final TextEditingController _beamLoadController = TextEditingController(text: '400');
  
  final TextEditingController _beamDim1Controller = TextEditingController(text: '28');
  final TextEditingController _beamDim2Controller = TextEditingController();
  final TextEditingController _beamDim3Controller = TextEditingController();
  final TextEditingController _beamDim4Controller = TextEditingController();

  final TextEditingController _beamCustomEController = TextEditingController(text: '206000');
  final TextEditingController _beamCustomRyController = TextEditingController(text: '240');
  final TextEditingController _beamCustomDensityController = TextEditingController(text: '7850');
  bool _beamIncludeSelfWeight = true;

  String _beamProfile = 'Круг'; // Круг, Прямоугольник, Круглая труба, Профильная труба, Двутавр, Швеллер, Уголок, Пластина, Тавр
  String _beamMaterial = 'Сталь'; // Сталь, Дерево, Алюминий, Железобетон, Медь, Стекло, Свой материал
  String _beamScheme = 'Шарнир-Шарнир'; // Шарнир-Шарнир, Консоль, Заделка-Заделка, Заделка-Шарнир
  String _beamLoadType = 'Распределенная'; // Распределенная, Сосредоточенная

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
    _beamSpanController.dispose();
    _beamLoadController.dispose();
    _beamDim1Controller.dispose();
    _beamDim2Controller.dispose();
    _beamDim3Controller.dispose();
    _beamDim4Controller.dispose();
    _beamCustomEController.dispose();
    _beamCustomRyController.dispose();
    _beamCustomDensityController.dispose();
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
                DropdownMenuItem(
                  value: CalculatorType.beamDeflection,
                  child: Text('Прогиб и прочность балки'),
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
      case CalculatorType.beamDeflection:
        return _buildBeamDeflectionCalculator();
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

  // --- Beam Deflection UI & Helpers ---
  Widget _buildBeamDeflectionCalculator() {
    final result = _solveBeamDeflection();
    final hasError = result.containsKey('error');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Расчет прогиба и прочности балки',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 16),
        
        _buildDropdownRow(
          label: 'Тип балки',
          value: _beamProfile,
          items: ['Круг', 'Прямоугольник', 'Круглая труба', 'Профильная труба', 'Двутавр', 'Швеллер', 'Уголок', 'Пластина', 'Тавр'],
          onChanged: (val) {
            setState(() {
              _beamProfile = val!;
              if (_beamProfile == 'Круг') {
                _beamDim1Controller.text = '28';
              } else if (_beamProfile == 'Прямоугольник') {
                _beamDim1Controller.text = '100';
                _beamDim2Controller.text = '150';
              } else if (_beamProfile == 'Круглая труба') {
                _beamDim1Controller.text = '57';
                _beamDim2Controller.text = '3.5';
              } else if (_beamProfile == 'Профильная труба') {
                _beamDim1Controller.text = '40';
                _beamDim2Controller.text = '20';
                _beamDim3Controller.text = '2';
              } else if (_beamProfile == 'Уголок') {
                _beamDim1Controller.text = '50';
                _beamDim2Controller.text = '50';
                _beamDim3Controller.text = '5';
              } else if (_beamProfile == 'Пластина') {
                _beamDim1Controller.text = '100';
                _beamDim2Controller.text = '8';
              } else if (_beamProfile == 'Тавр') {
                _beamDim1Controller.text = '80';
                _beamDim2Controller.text = '80';
                _beamDim3Controller.text = '6';
                _beamDim4Controller.text = '8';
              } else {
                _beamDim1Controller.text = '140';
                _beamDim2Controller.text = '73';
                _beamDim3Controller.text = '4.7';
                _beamDim4Controller.text = '6.9';
              }
            });
          },
        ),
        const SizedBox(height: 12),
        
        _buildDropdownRow(
          label: 'Материал',
          value: _beamMaterial,
          items: ['Сталь', 'Дерево', 'Алюминий', 'Железобетон', 'Медь', 'Стекло', 'Свой материал'],
          onChanged: (val) => setState(() => _beamMaterial = val!),
        ),
        if (_beamMaterial == 'Свой материал') ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamCustomEController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Модуль упругости E (МПа)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamCustomRyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Сопротивление Ry (МПа)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _beamCustomDensityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Плотность (кг/м³)',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 12),
        
        _buildDropdownRow(
          label: 'Схема закрепления',
          value: _beamScheme,
          items: ['Шарнир-Шарнир', 'Консоль', 'Заделка-Заделка', 'Заделка-Шарнир'],
          onChanged: (val) => setState(() => _beamScheme = val!),
        ),
        const SizedBox(height: 12),
        
        _buildDropdownRow(
          label: 'Вид нагрузки',
          value: _beamLoadType,
          items: ['Распределенная', 'Сосредоточенная'],
          onChanged: (val) => setState(() => _beamLoadType = val!),
        ),
        const SizedBox(height: 16),
        
        const Divider(color: Colors.white24),
        const SizedBox(height: 8),
        const Text(
          'Геометрические размеры и нагрузка',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
        ),
        const SizedBox(height: 12),
        
        ..._buildBeamProfileInputs(),
        
        const SizedBox(height: 12),
        TextField(
          controller: _beamSpanController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Пролет балки L (мм)',
            hintText: 'например, 3500',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _beamLoadController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: _beamLoadType == 'Распределенная' ? 'Нагрузка q (кг/м)' : 'Нагрузка F (кг)',
            hintText: _beamLoadType == 'Распределенная' ? 'например, 400' : 'например, 500',
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Checkbox(
              value: _beamIncludeSelfWeight,
              activeColor: const Color(0xFFFF4081),
              onChanged: (val) {
                setState(() {
                  _beamIncludeSelfWeight = val ?? false;
                });
              },
            ),
            const Text(
              'Учитывать собственный вес балки',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        if (!hasError) ...[
          const Text(
            'Схема деформации балки',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
            ),
            child: CustomPaint(
              painter: BeamPainter(
                scheme: _beamScheme,
                loadType: _beamLoadType,
                deflectionPercent: (result['fMax'] as double) / (result['fAllowable'] as double),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],

        if (hasError)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Text(
              result['error'] ?? 'Неизвестная ошибка',
              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          )
        else
          _buildBeamResults(result),
      ],
    );
  }

  Widget _buildDropdownRow({required String label, required String value, required List<String> items, required void Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  List<Widget> _buildBeamProfileInputs() {
    switch (_beamProfile) {
      case 'Круг':
        return [
          TextField(
            controller: _beamDim1Controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Диаметр d (мм)',
              hintText: 'например, 28',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ];
      case 'Прямоугольник':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Ширина b (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Высота h (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ];
      case 'Круглая труба':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Внешний диаметр D (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Стенка t (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ];
      case 'Профильная труба':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Ширина А (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Высота B (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _beamDim3Controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Толщина стенки t (мм)',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ];
      case 'Двутавр':
      case 'Швеллер':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Высота h (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Ширина полки b (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim3Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Стенка tw (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim4Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Полка tf (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ];
      case 'Уголок':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Высота H (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Ширина B (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _beamDim3Controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Толщина t (мм)',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ];
      case 'Пластина':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Ширина B (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Толщина t (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ];
      case 'Тавр':
        return [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim1Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Высота H (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim2Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Ширина полки B (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _beamDim3Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Стенка tw (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _beamDim4Controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Полка tf (мм)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildBeamResults(Map<String, dynamic> res) {
    final double fMax = res['fMax'];
    final double fAllow = res['fAllowable'];
    final double limitDenominator = res['limitDenominator'] ?? 200.0;
    final double sigmaMax = res['sigmaMax'];
    final double ry = res['ry'];
    
    final bool strengthOk = res['strengthOk'];
    final bool deflectionOk = res['deflectionOk'];
    
    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: deflectionOk ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: deflectionOk ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    deflectionOk ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                    color: deflectionOk ? Colors.green : Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    deflectionOk ? 'Жесткость: В ПРЕДЕЛАХ НОРМЫ' : 'Жесткость: ПРЕВЫШЕН ПРОГИБ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: deflectionOk ? Colors.green : Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Максимальный прогиб: ${fMax.toStringAsFixed(2)} мм\nПредельный прогиб (L/${limitDenominator.toStringAsFixed(0)}): ${fAllow.toStringAsFixed(2)} мм',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: strengthOk ? Colors.green.withOpacity(0.1) : Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: strengthOk ? Colors.green.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    strengthOk ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                    color: strengthOk ? Colors.green : Colors.redAccent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    strengthOk ? 'Прочность: ОБЕСПЕЧЕНА' : 'Прочность: НЕ ОБЕСПЕЧЕНА',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: strengthOk ? Colors.green : Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Максимальное напряжение: ${sigmaMax.toStringAsFixed(1)} МПа\nРасчетное сопротивление Ry: ${ry.toStringAsFixed(0)} МПа',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        
        _buildResultCard(
          title: 'Геометрия и характеристики сечения',
          outputs: [
            'Момент инерции Ix: ${res['ix'].toStringAsFixed(0)} мм⁴',
            'Момент сопротивления Wx: ${res['wx'].toStringAsFixed(0)} мм³',
            'Площадь сечения: ${res['area'].toStringAsFixed(1)} мм²',
            'Вес 1 п.м. балки: ${res['qSelf'].toStringAsFixed(2)} кг/м',
            'Общий вес балки: ${res['totalBeamWeight'].toStringAsFixed(1)} кг',
            'Макс. изгибающий момент: ${(res['mMax'] / 1000000.0).toStringAsFixed(3)} кН·м',
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _solveBeamDeflection() {
    const double pi = 3.14;
    final L = double.tryParse(_beamSpanController.text.replaceAll(',', '.')) ?? 0.0;
    final loadVal = double.tryParse(_beamLoadController.text.replaceAll(',', '.')) ?? 0.0;
    
    final dim1 = double.tryParse(_beamDim1Controller.text.replaceAll(',', '.')) ?? 0.0;
    final dim2 = double.tryParse(_beamDim2Controller.text.replaceAll(',', '.')) ?? 0.0;
    final dim3 = double.tryParse(_beamDim3Controller.text.replaceAll(',', '.')) ?? 0.0;
    final dim4 = double.tryParse(_beamDim4Controller.text.replaceAll(',', '.')) ?? 0.0;
    
    if (L <= 0 || loadVal <= 0) return {'error': 'Задайте пролет и нагрузку'};
    
    double ix = 0.0;
    double wx = 0.0;
    double area = 0.0;
    
    switch (_beamProfile) {
      case 'Круг':
        if (dim1 <= 0) return {'error': 'Задайте диаметр d'};
        area = (pi * pow(dim1, 2)) / 4.0;
        ix = (pi * pow(dim1, 4)) / 64.0;
        wx = (pi * pow(dim1, 3)) / 32.0;
        break;
      case 'Прямоугольник':
        if (dim1 <= 0 || dim2 <= 0) return {'error': 'Задайте b и h'};
        area = dim1 * dim2;
        ix = (dim1 * pow(dim2, 3)) / 12.0;
        wx = (dim1 * pow(dim2, 2)) / 6.0;
        break;
      case 'Круглая труба':
        if (dim1 <= 0 || dim2 <= 0) return {'error': 'Задайте диаметр D и стенку t'};
        if (dim2 * 2 >= dim1) return {'error': 'Толщина стенки слишком велика'};
        final dInner = dim1 - 2.0 * dim2;
        area = (pi * (pow(dim1, 2) - pow(dInner, 2))) / 4.0;
        ix = (pi * (pow(dim1, 4) - pow(dInner, 4))) / 64.0;
        wx = (pi * (pow(dim1, 4) - pow(dInner, 4))) / (32.0 * dim1);
        break;
      case 'Профильная труба':
        if (dim1 <= 0 || dim2 <= 0 || dim3 <= 0) return {'error': 'Задайте А, B и стенку t'};
        if (dim3 * 2 >= dim1 || dim3 * 2 >= dim2) return {'error': 'Толщина стенки слишком велика'};
        final bInner = dim1 - 2.0 * dim3;
        final hInner = dim2 - 2.0 * dim3;
        area = (dim1 * dim2) - (bInner * hInner);
        ix = (dim1 * pow(dim2, 3) - bInner * pow(hInner, 3)) / 12.0;
        wx = (dim1 * pow(dim2, 3) - bInner * pow(hInner, 3)) / (6.0 * dim2);
        break;
      case 'Двутавр':
      case 'Швеллер':
        if (dim1 <= 0 || dim2 <= 0 || dim3 <= 0 || dim4 <= 0) return {'error': 'Задайте h, b, tw, tf'};
        if (dim3 >= dim2 || dim4 * 2 >= dim1) return {'error': 'Толщина стенки/полки слишком велика'};
        final hInner = dim1 - 2.0 * dim4;
        final bInner = dim2 - dim3;
        area = 2.0 * dim2 * dim4 + dim3 * hInner;
        ix = (dim2 * pow(dim1, 3) - bInner * pow(hInner, 3)) / 12.0;
        wx = ix / (dim1 / 2.0);
        break;
      case 'Уголок':
        if (dim1 <= 0 || dim2 <= 0 || dim3 <= 0) return {'error': 'Задайте H, B, t'};
        if (dim3 >= dim1 || dim3 >= dim2) return {'error': 'Толщина стенки слишком велика'};
        area = dim2 * dim3 + (dim1 - dim3) * dim3;
        final yCentroid = (dim2 * dim3 * (dim3 / 2.0) + (dim1 - dim3) * dim3 * (dim3 + (dim1 - dim3) / 2.0)) / area;
        final ixFlange = (dim2 * pow(dim3, 3)) / 12.0 + (dim2 * dim3) * pow(yCentroid - dim3 / 2.0, 2);
        final ixWeb = (dim3 * pow(dim1 - dim3, 3)) / 12.0 + (dim3 * (dim1 - dim3)) * pow(yCentroid - (dim1 + dim3) / 2.0, 2);
        ix = ixFlange + ixWeb;
        wx = ix / max(yCentroid, dim1 - yCentroid);
        break;
      case 'Пластина':
        if (dim1 <= 0 || dim2 <= 0) return {'error': 'Задайте B и t'};
        area = dim1 * dim2;
        ix = (dim1 * pow(dim2, 3)) / 12.0;
        wx = (dim1 * pow(dim2, 2)) / 6.0;
        break;
      case 'Тавр':
        if (dim1 <= 0 || dim2 <= 0 || dim3 <= 0 || dim4 <= 0) return {'error': 'Задайте H, B, tw, tf'};
        if (dim3 >= dim2 || dim4 >= dim1) return {'error': 'Некорректная толщина стенки/полки'};
        area = dim2 * dim4 + dim3 * (dim1 - dim4);
        final hStem = dim1 - dim4;
        final yCentroid = (dim3 * hStem * (hStem / 2.0) + dim2 * dim4 * (dim1 - dim4 / 2.0)) / area;
        final ixStem = (dim3 * pow(hStem, 3)) / 12.0 + (dim3 * hStem) * pow(yCentroid - hStem / 2.0, 2);
        final ixFlange = (dim2 * pow(dim4, 3)) / 12.0 + (dim2 * dim4) * pow(yCentroid - (dim1 - dim4 / 2.0), 2);
        ix = ixStem + ixFlange;
        wx = ix / max(yCentroid, dim1 - yCentroid);
        break;
    }
    
    if (ix <= 0 || wx <= 0) return {'error': 'Некорректные геометрические параметры'};
    
    double E = 200000.0;
    double ry = 240.0;
    double density = 7850.0;
    
    switch (_beamMaterial) {
      case 'Сталь':
        E = 200000.0;
        ry = 240.0;
        density = 7850.0;
        break;
      case 'Дерево':
        E = 10000.0;
        ry = 15.0;
        density = 500.0;
        break;
      case 'Алюминий':
        E = 70000.0;
        ry = 90.0;
        density = 2700.0;
        break;
      case 'Железобетон':
        E = 30000.0;
        ry = 30.0;
        density = 2500.0;
        break;
      case 'Медь':
        E = 110000.0;
        ry = 100.0;
        density = 8900.0;
        break;
      case 'Стекло':
        E = 70000.0;
        ry = 50.0;
        density = 2500.0;
        break;
      case 'Свой материал':
        E = double.tryParse(_beamCustomEController.text.replaceAll(',', '.')) ?? 200000.0;
        ry = double.tryParse(_beamCustomRyController.text.replaceAll(',', '.')) ?? 240.0;
        density = double.tryParse(_beamCustomDensityController.text.replaceAll(',', '.')) ?? 7850.0;
        if (E <= 0 || ry <= 0 || density < 0) return {'error': 'Задайте корректные параметры своего материала'};
        break;
    }
    
    final isDistributed = _beamLoadType == 'Распределенная';
    final double rawSelfKgM = _beamIncludeSelfWeight ? (area * 1e-6 * density) : 0.0;
    final double qSelfKgM = double.parse(rawSelfKgM.toStringAsFixed(1));
    final double qSelfNmm = (qSelfKgM * 10.0) / 1000.0;
    
    double mMax = 0.0;
    double fMax = 0.0;
    
    if (isDistributed) {
      final double qNmm = ((loadVal + qSelfKgM) * 10.0) / 1000.0;
      switch (_beamScheme) {
        case 'Шарнир-Шарнир':
          mMax = (qNmm * pow(L, 2)) / 8.0;
          fMax = (5.0 * qNmm * pow(L, 4)) / (384.0 * E * ix);
          break;
        case 'Консоль':
          mMax = (qNmm * pow(L, 2)) / 2.0;
          fMax = (qNmm * pow(L, 4)) / (8.0 * E * ix);
          break;
        case 'Заделка-Заделка':
          mMax = (qNmm * pow(L, 2)) / 12.0;
          fMax = (qNmm * pow(L, 4)) / (384.0 * E * ix);
          break;
        case 'Заделка-Шарнир':
          mMax = (qNmm * pow(L, 2)) / 8.0;
          fMax = (qNmm * pow(L, 4)) / (184.6 * E * ix);
          break;
      }
    } else {
      final double fN = loadVal * 10.0;
      switch (_beamScheme) {
        case 'Шарнир-Шарнир':
          mMax = (fN * L) / 4.0 + (qSelfNmm * pow(L, 2)) / 8.0;
          fMax = (fN * pow(L, 3)) / (48.0 * E * ix) + (5.0 * qSelfNmm * pow(L, 4)) / (384.0 * E * ix);
          break;
        case 'Консоль':
          mMax = fN * L + (qSelfNmm * pow(L, 2)) / 2.0;
          fMax = (fN * pow(L, 3)) / (3.0 * E * ix) + (qSelfNmm * pow(L, 4)) / (8.0 * E * ix);
          break;
        case 'Заделка-Заделка':
          mMax = (fN * L) / 8.0 + (qSelfNmm * pow(L, 2)) / 12.0;
          fMax = (fN * pow(L, 3)) / (192.0 * E * ix) + (qSelfNmm * pow(L, 4)) / (384.0 * E * ix);
          break;
        case 'Заделка-Шарнир':
          mMax = (3.0 * fN * L) / 16.0 + (qSelfNmm * pow(L, 2)) / 8.0;
          fMax = (fN * pow(L, 3)) / (109.7 * E * ix) + (qSelfNmm * pow(L, 4)) / (184.6 * E * ix);
          break;
      }
    }
    
    final sigmaMax = mMax / wx;
    
    double limitDenominator;
    if (L <= 3000.0) {
      limitDenominator = 150.0;
    } else if (L <= 6000.0) {
      limitDenominator = 150.0 + (L - 3000.0) * (200.0 - 150.0) / (6000.0 - 3000.0);
    } else if (L <= 12000.0) {
      limitDenominator = 200.0 + (L - 6000.0) * (250.0 - 200.0) / (12000.0 - 6000.0);
    } else if (L <= 24000.0) {
      limitDenominator = 250.0 + (L - 12000.0) * (300.0 - 250.0) / (24000.0 - 12000.0);
    } else {
      limitDenominator = 300.0;
    }
    final fAllowable = L / limitDenominator;
    
    return {
      'ix': ix,
      'wx': wx,
      'area': area,
      'qSelf': qSelfKgM,
      'totalBeamWeight': qSelfKgM * (L / 1000.0),
      'mMax': mMax,
      'fMax': fMax,
      'sigmaMax': sigmaMax,
      'fAllowable': fAllowable,
      'limitDenominator': limitDenominator,
      'ry': ry,
      'strengthOk': sigmaMax <= ry,
      'deflectionOk': fMax <= fAllowable,
    };
  }
}

class BeamPainter extends CustomPainter {
  final String scheme;
  final String loadType;
  final double deflectionPercent;

  BeamPainter({
    required this.scheme,
    required this.loadType,
    required this.deflectionPercent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintBeam = Paint()
      ..color = const Color(0xFFFF4081)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintSupport = Paint()
      ..color = Colors.grey
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final paintLoad = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final arrowPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    const padding = 40.0;
    
    final yCenter = h * 0.45;
    const leftX = padding;
    final rightX = w - padding;
    final beamLength = rightX - leftX;

    if (scheme == 'Шарнир-Шарнир') {
      final pathLeft = Path()
        ..moveTo(leftX, yCenter)
        ..lineTo(leftX - 10, yCenter + 15)
        ..lineTo(leftX + 10, yCenter + 15)
        ..close();
      canvas.drawPath(pathLeft, paintSupport);
      
      final pathRight = Path()
        ..moveTo(rightX, yCenter)
        ..lineTo(rightX - 10, yCenter + 15)
        ..lineTo(rightX + 10, yCenter + 15)
        ..close();
      canvas.drawPath(pathRight, paintSupport);
    } else if (scheme == 'Консоль') {
      canvas.drawLine(Offset(leftX - 5, yCenter - 25), Offset(leftX - 5, yCenter + 25), paintSupport..strokeWidth = 8);
      paintSupport.strokeWidth = 2;
      for (var y = -20; y <= 20; y += 8) {
        canvas.drawLine(Offset(leftX - 10, yCenter + y - 4), Offset(leftX - 5, yCenter + y + 4), paintSupport);
      }
    } else if (scheme == 'Заделка-Заделка') {
      canvas.drawLine(Offset(leftX - 5, yCenter - 25), Offset(leftX - 5, yCenter + 25), paintSupport..strokeWidth = 8);
      for (var y = -20; y <= 20; y += 8) {
        canvas.drawLine(Offset(leftX - 10, yCenter + y - 4), Offset(leftX - 5, yCenter + y + 4), paintSupport);
      }
      canvas.drawLine(Offset(rightX + 5, yCenter - 25), Offset(rightX + 5, yCenter + 25), paintSupport..strokeWidth = 8);
      for (var y = -20; y <= 20; y += 8) {
        canvas.drawLine(Offset(rightX + 5, yCenter + y - 4), Offset(rightX + 10, yCenter + y + 4), paintSupport);
      }
    } else if (scheme == 'Заделка-Шарнир') {
      canvas.drawLine(Offset(leftX - 5, yCenter - 25), Offset(leftX - 5, yCenter + 25), paintSupport..strokeWidth = 8);
      for (var y = -20; y <= 20; y += 8) {
        canvas.drawLine(Offset(leftX - 10, yCenter + y - 4), Offset(leftX - 5, yCenter + y + 4), paintSupport);
      }
      final pathRight = Path()
        ..moveTo(rightX, yCenter)
        ..lineTo(rightX - 10, yCenter + 15)
        ..lineTo(rightX + 10, yCenter + 15)
        ..close();
      canvas.drawPath(pathRight, paintSupport..strokeWidth = 3);
    }

    final maxDeflectionOffset = 25.0 * deflectionPercent.clamp(0.0, 1.5);
    final beamPath = Path();

    if (scheme == 'Консоль') {
      beamPath.moveTo(leftX, yCenter);
      beamPath.cubicTo(
        leftX + beamLength * 0.5, yCenter,
        leftX + beamLength * 0.8, yCenter + maxDeflectionOffset * 0.8,
        rightX, yCenter + maxDeflectionOffset,
      );
    } else {
      final midX = leftX + beamLength * 0.5;
      final maxDefX = scheme == 'Заделка-Шарнир' ? leftX + beamLength * 0.58 : midX;
      beamPath.moveTo(leftX, yCenter);
      beamPath.quadraticBezierTo(maxDefX, yCenter + maxDeflectionOffset * 2.0, rightX, yCenter);
    }
    canvas.drawPath(beamPath, paintBeam);

    if (loadType == 'Сосредоточенная') {
      final forceX = scheme == 'Консоль' ? rightX : (leftX + beamLength * 0.5);
      final arrowYTarget = scheme == 'Консоль' ? (yCenter + maxDeflectionOffset - 3) : (yCenter + maxDeflectionOffset * 0.8 - 3);
      final arrowYStart = arrowYTarget - 30;

      canvas.drawLine(Offset(forceX, arrowYStart), Offset(forceX, arrowYTarget), paintLoad..strokeWidth = 3);
      final arrowPath = Path()
        ..moveTo(forceX, arrowYTarget)
        ..lineTo(forceX - 6, arrowYTarget - 10)
        ..lineTo(forceX + 6, arrowYTarget - 10)
        ..close();
      canvas.drawPath(arrowPath, arrowPaint);
    } else {
      const arrowCount = 7;
      final spacing = beamLength / (arrowCount - 1);
      final linePath = Path();

      for (var i = 0; i < arrowCount; i++) {
        final curX = leftX + i * spacing;
        double localDeflection = 0.0;
        
        if (scheme == 'Консоль') {
          final t = i / (arrowCount - 1);
          localDeflection = maxDeflectionOffset * (3 * t * t - t * t * t) / 2.0;
        } else {
          final angle = pi * (i / (arrowCount - 1));
          localDeflection = maxDeflectionOffset * sin(angle);
        }
        
        final arrowYTarget = yCenter + localDeflection - 3;
        final arrowYStart = arrowYTarget - 15;
        
        canvas.drawLine(Offset(curX, arrowYStart), Offset(curX, arrowYTarget), paintLoad..strokeWidth = 1.5);
        final arrowPath = Path()
          ..moveTo(curX, arrowYTarget)
          ..lineTo(curX - 4, arrowYTarget - 6)
          ..lineTo(curX + 4, arrowYTarget - 6)
          ..close();
        canvas.drawPath(arrowPath, arrowPaint);

        if (i == 0) {
          linePath.moveTo(curX, arrowYStart);
        } else {
          linePath.lineTo(curX, arrowYStart);
        }
      }
      canvas.drawPath(linePath, paintLoad..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant BeamPainter oldDelegate) {
    return oldDelegate.scheme != scheme ||
        oldDelegate.loadType != loadType ||
        oldDelegate.deflectionPercent != deflectionPercent;
  }
}
