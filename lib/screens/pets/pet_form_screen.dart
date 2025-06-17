// lib/screens/pets/pet_form_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../models/pet.dart';
import '../../services/pet_service.dart';
import '../../services/auth_service.dart';

class PetFormScreen extends StatefulWidget {
  final Pet? pet; // Null for new pet, existing pet for editing

  const PetFormScreen({super.key, this.pet});

  @override
  State<PetFormScreen> createState() => PetFormScreenState(); // Changed from private to public type
}

class PetFormScreenState extends State<PetFormScreen> {
  // Removed underscore to make public
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();

  Gender _selectedGender = Gender.unknown;
  DateTime? _selectedBirthday;
  Category _selectedCategory = Category.other;
  WeightUnit _selectedUnit = WeightUnit.g;
  File? _imageFile;
  String? _currentImageUrl;
  bool _isLoading = false;

  bool get _isEditing => widget.pet != null;

  @override
  void initState() {
    super.initState();
    // Initialize form with existing pet data if editing
    if (_isEditing) {
      _nameController.text = widget.pet!.name;
      _breedController.text = widget.pet!.breed;
      _selectedGender = widget.pet!.gender;
      _selectedBirthday = widget.pet!.birthday;
      _selectedCategory = widget.pet!.category;
      _selectedUnit = widget.pet!.unit;
      _currentImageUrl = widget.pet!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    super.dispose();
  }

  // Pick image from gallery
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Save pet to Firestore
  Future<void> _savePet() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final petService = PetService(userId: authService.currentUser!.uid);

        // Create pet object from form data
        final pet = Pet(
          id: _isEditing ? widget.pet!.id : null,
          name: _nameController.text.trim(),
          gender: _selectedGender,
          birthday: _selectedBirthday,
          category: _selectedCategory,
          breed: _breedController.text.trim(),
          unit: _selectedUnit,
          imageUrl: _currentImageUrl,
          createdAt: _isEditing ? widget.pet!.createdAt : DateTime.now(),
        );

        bool success;
        if (_isEditing) {
          success = await petService.updatePet(pet, imageFile: _imageFile);
        } else {
          final petId = await petService.addPet(pet, imageFile: _imageFile);
          success = petId != null;
        }

        // Add mounted check to ensure widget is still in the tree
        if (!mounted) return;

        if (success) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'ペット情報を更新しました' : 'ペットを登録しました')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('エラーが発生しました。もう一度お試しください。')));
        }
      } catch (e) {
        // Add mounted check to ensure widget is still in the tree
        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('エラー: $e')));
      } finally {
        // Add mounted check to ensure widget is still in the tree
        if (!mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'ペット情報の編集' : '新規ペット登録'),
        backgroundColor: Colors.green,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet Image
                      Center(
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: _buildImageSection(),
                        ),
                      ),
                      SizedBox(height: 24.0),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'ペット名',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.pets),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'ペット名を入力してください';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),

                      // Gender Selection
                      Text('性別', style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<Gender>(
                              title: Text('オス'),
                              value: Gender.male,
                              groupValue: _selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<Gender>(
                              title: Text('メス'),
                              value: Gender.female,
                              groupValue: _selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<Gender>(
                              title: Text('不明'),
                              value: Gender.unknown,
                              groupValue: _selectedGender,
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.0),

                      // Birthday Selection
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(Icons.calendar_today),
                              label: Text(
                                _selectedBirthday == null
                                    ? '誕生日を選択 (任意)'
                                    : DateFormat(
                                      'yyyy/MM/dd',
                                    ).format(_selectedBirthday!),
                              ),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          SizedBox(width: 8.0),
                          if (_selectedBirthday != null)
                            IconButton(
                              icon: Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _selectedBirthday = null;
                                });
                              },
                            ),
                        ],
                      ),
                      SizedBox(height: 16.0),

                      // Category Dropdown
                      Text('分類', style: TextStyle(fontSize: 16)),
                      DropdownButtonFormField<Category>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        items:
                            Category.values.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(Pet.getCategoryText(category)),
                              );
                            }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                        },
                      ),
                      SizedBox(height: 16.0),

                      // Breed Field
                      TextFormField(
                        controller: _breedController,
                        decoration: InputDecoration(
                          labelText: '種類',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '種類を入力してください';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16.0),

                      // Weight Unit Selection
                      Text('体重単位', style: TextStyle(fontSize: 16)),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<WeightUnit>(
                              title: Text('g'),
                              value: WeightUnit.g,
                              groupValue: _selectedUnit,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<WeightUnit>(
                              title: Text('kg'),
                              value: WeightUnit.kg,
                              groupValue: _selectedUnit,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value!;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<WeightUnit>(
                              title: Text('lbs'),
                              value: WeightUnit.lbs,
                              groupValue: _selectedUnit,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24.0),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savePet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: EdgeInsets.symmetric(vertical: 16.0),
                          ),
                          child: Text(
                            _isEditing ? '更新する' : '登録する',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Image selector widget
  Widget _buildImageSection() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Center(
            child:
                _imageFile != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _imageFile!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    )
                    : _currentImageUrl != null
                    ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        _currentImageUrl!,
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value:
                                  loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.pets, size: 60, color: Colors.grey);
                        },
                      ),
                    )
                    : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate,
                          size: 60,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '写真を追加',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
          ),
          if (_imageFile != null || _currentImageUrl != null)
            Positioned(
              right: 0,
              top: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _imageFile = null;
                    if (_isEditing) {
                      _currentImageUrl = null;
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      // locale: const Locale('ja', 'JP'), // ロケールのエラーが発生する場合はコメントアウト
    );

    // Add mounted check
    if (!mounted) return;

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
      });
    }
  }
}
