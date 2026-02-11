import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import '../domain/ingredient.dart';
import '../domain/recipe.dart';

/// Full-screen modal bottom sheet for editing a recipe.
/// Returns the updated [Recipe] on save, or `null` if dismissed.
class EditRecipeSheet extends StatefulWidget {
  const EditRecipeSheet({super.key, required this.recipe});

  final Recipe recipe;

  static Future<Recipe?> show(BuildContext context, Recipe recipe) {
    return showModalBottomSheet<Recipe>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => EditRecipeSheet(recipe: recipe),
    );
  }

  @override
  State<EditRecipeSheet> createState() => _EditRecipeSheetState();
}

class _EditRecipeSheetState extends State<EditRecipeSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _servingsCtrl;
  late final TextEditingController _prepCtrl;
  late final TextEditingController _cookCtrl;

  late List<_IngredientEdit> _ingredients;
  late List<TextEditingController> _instructionCtrls;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameCtrl = TextEditingController(text: r.name);
    _descCtrl = TextEditingController(text: r.description);
    _servingsCtrl = TextEditingController(text: r.servings?.toString() ?? '');
    _prepCtrl = TextEditingController(
      text: r.prepTimeMinutes?.toString() ?? '',
    );
    _cookCtrl = TextEditingController(
      text: r.cookTimeMinutes?.toString() ?? '',
    );

    _ingredients = r.ingredients
        .map(
          (i) => _IngredientEdit(
            name: TextEditingController(text: i.name),
            quantity: TextEditingController(text: i.quantity),
            unit: TextEditingController(text: i.unit ?? ''),
            inPantry: i.inPantry,
          ),
        )
        .toList();

    _instructionCtrls = r.instructions
        .map((s) => TextEditingController(text: s))
        .toList();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _servingsCtrl.dispose();
    _prepCtrl.dispose();
    _cookCtrl.dispose();
    for (final i in _ingredients) {
      i.name.dispose();
      i.quantity.dispose();
      i.unit.dispose();
    }
    for (final c in _instructionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  Recipe _buildRecipe() {
    return widget.recipe.copyWith(
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      servings: int.tryParse(_servingsCtrl.text.trim()),
      prepTimeMinutes: int.tryParse(_prepCtrl.text.trim()),
      cookTimeMinutes: int.tryParse(_cookCtrl.text.trim()),
      ingredients: _ingredients
          .map(
            (e) => Ingredient(
              name: e.name.text.trim(),
              quantity: e.quantity.text.trim(),
              unit: e.unit.text.trim().isEmpty ? null : e.unit.text.trim(),
              inPantry: e.inPantry,
            ),
          )
          .where((i) => i.name.isNotEmpty)
          .toList(),
      instructions: _instructionCtrls
          .map((c) => c.text.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
    );
  }

  void _save() {
    final recipe = _buildRecipe();
    if (recipe.name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recipe name is required')));
      return;
    }
    Navigator.of(context).pop(recipe);
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add(
        _IngredientEdit(
          name: TextEditingController(),
          quantity: TextEditingController(),
          unit: TextEditingController(),
        ),
      );
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      final removed = _ingredients.removeAt(index);
      removed.name.dispose();
      removed.quantity.dispose();
      removed.unit.dispose();
    });
  }

  void _addInstruction() {
    setState(() {
      _instructionCtrls.add(TextEditingController());
    });
  }

  void _removeInstruction(int index) {
    setState(() {
      _instructionCtrls.removeAt(index).dispose();
    });
  }

  static const double _sheetRadius = 20;
  static const double _blurSigma = 12;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(_sheetRadius),
        topRight: Radius.circular(_sheetRadius),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.92),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(_sheetRadius),
              topRight: Radius.circular(_sheetRadius),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  children: [
                    _buildBasicInfo(),
                    const SizedBox(height: 24),
                    _buildMeta(),
                    const SizedBox(height: 28),
                    _buildIngredientsSection(),
                    const SizedBox(height: 28),
                    _buildInstructionsSection(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // Drag handle
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Row(
            children: [
              FakeGlass(
                shape: LiquidRoundedSuperellipse(borderRadius: 999),
                settings: const LiquidGlassSettings(
                  blur: 10,
                  glassColor: Color(0x18000000),
                ),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/x.svg',
                      width: 18,
                      height: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Edit Recipe',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FakeGlass(
                shape: LiquidRoundedSuperellipse(borderRadius: 999),
                settings: const LiquidGlassSettings(
                  blur: 10,
                  glassColor: Color(0x18000000),
                ),
                child: SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: _saving ? null : _save,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildLabel('Name'),
        const SizedBox(height: 6),
        _buildTextField(_nameCtrl, hint: 'Recipe name'),
        const SizedBox(height: 16),
        _buildLabel('Description'),
        const SizedBox(height: 6),
        _buildTextField(_descCtrl, hint: 'A short description', maxLines: 3),
      ],
    );
  }

  Widget _buildMeta() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Servings'),
              const SizedBox(height: 6),
              _buildNumberField(_servingsCtrl, hint: '4'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Prep (min)'),
              const SizedBox(height: 6),
              _buildNumberField(_prepCtrl, hint: '15'),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('Cook (min)'),
              const SizedBox(height: 6),
              _buildNumberField(_cookCtrl, hint: '30'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIngredientsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel('Ingredients'),
            const Spacer(),
            GestureDetector(
              onTap: _addIngredient,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/plus.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_ingredients.length, (i) {
          final ing = _ingredients[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Quantity + unit
                SizedBox(
                  width: 56,
                  child: _buildTextField(
                    ing.quantity,
                    hint: 'Qty',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 48,
                  child: _buildTextField(ing.unit, hint: 'Unit', fontSize: 13),
                ),
                const SizedBox(width: 6),
                // Name
                Expanded(
                  child: _buildTextField(
                    ing.name,
                    hint: 'Ingredient',
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _removeIngredient(i),
                  child: Icon(
                    Icons.remove_circle_outline,
                    size: 18,
                    color: Colors.red.shade400,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildLabel('Instructions'),
            const Spacer(),
            GestureDetector(
              onTap: _addInstruction,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/icons/plus.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.primary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...List.generate(_instructionCtrls.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${i + 1}.',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTextField(
                    _instructionCtrls[i],
                    hint: 'Step ${i + 1}',
                    maxLines: 3,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: GestureDetector(
                    onTap: () => _removeInstruction(i),
                    child: Icon(
                      Icons.remove_circle_outline,
                      size: 18,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey.shade700,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, {
    String hint = '',
    int maxLines = 1,
    double fontSize = 15,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: 1,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w400,
          fontSize: fontSize,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller, {
    String hint = '',
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

class _IngredientEdit {
  _IngredientEdit({
    required this.name,
    required this.quantity,
    required this.unit,
    this.inPantry = false,
  });

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;
  final bool inPantry;
}
