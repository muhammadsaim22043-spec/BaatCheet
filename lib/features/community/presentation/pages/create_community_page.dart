// lib/features/community/presentation/pages/create_community_page.dart

import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../controllers/community_notifier.dart';

class CreateCommunityPage extends StatefulWidget {
  final String currentUserId;

  const CreateCommunityPage({super.key, required this.currentUserId});

  @override
  State<CreateCommunityPage> createState() => _CreateCommunityPageState();
}

class _CreateCommunityPageState extends State<CreateCommunityPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memberPhoneController = TextEditingController();

  final CommunityNotifier _notifier = sl<CommunityNotifier>();
  final AuthNotifier _authNotifier = sl<AuthNotifier>();

  bool _isPublic = true;
  final List<String> _selectedMemberIds = [];
  final List<String> _selectedMemberNames = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _memberPhoneController.dispose();
    super.dispose();
  }

  Future<void> _addMemberByPhone() async {
    final phone = _memberPhoneController.text.trim();
    if (phone.isEmpty) return;

    final user = await _authNotifier.findUserByPhoneNumber(phone);
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No registered user found with this phone number.')),
        );
      }
      return;
    }

    if (user.id == widget.currentUserId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are automatically included as Admin.')),
        );
      }
      return;
    }

    if (_selectedMemberIds.contains(user.id)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User is already added.')),
        );
      }
      return;
    }

    setState(() {
      _selectedMemberIds.add(user.id);
      _selectedMemberNames.add(user.displayName);
      _memberPhoneController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await _notifier.createCommunity(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      adminId: widget.currentUserId,
      isPublic: _isPublic,
      initialMemberIds: _selectedMemberIds,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Community created successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Community / Group', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Community Name',
                  hintText: 'e.g. Flutter Developers, Campus Buddies',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'What is this community about?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),

              // Privacy Configuration Switch
              Card(
                elevation: 0,
                color: Colors.grey[100],
                child: SwitchListTile(
                  title: Text(
                    _isPublic ? 'Public Community' : 'Private Community',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _isPublic
                        ? 'Anyone can search and join this group freely.'
                        : 'Only the creator can add members to this group.',
                  ),
                  value: _isPublic,
                  onChanged: (val) => setState(() => _isPublic = val),
                  secondary: Icon(
                    _isPublic ? Icons.public : Icons.lock,
                    color: _isPublic ? Colors.blue : Colors.amber[800],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Private member selection section
              if (!_isPublic) ...[
                const Text(
                  'Add Initial Members (Private Group)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _memberPhoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Member Phone Number",
                          hintText: "e.g. +923001234567",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addMemberByPhone,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: List.generate(_selectedMemberNames.length, (i) {
                    return Chip(
                      label: Text(_selectedMemberNames[i]),
                      onDeleted: () {
                        setState(() {
                          _selectedMemberIds.removeAt(i);
                          _selectedMemberNames.removeAt(i);
                        });
                      },
                    );
                  }),
                ),
                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _notifier.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _notifier.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('CREATE COMMUNITY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
