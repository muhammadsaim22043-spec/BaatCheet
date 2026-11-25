// lib/features/auth/presentation/pages/login_page.dart

import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/string_sanitizer.dart';
import '../controllers/auth_notifier.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Grab a fresh instance of our controller straight out of our dependency box
  final AuthNotifier _authNotifier = sl<AuthNotifier>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _useEmailPassword = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    // Do NOT dispose _authNotifier here if it's provided by get_it (sl) and shared
    // However, if it's meant to be local, it's fine. 
    // Usually sl<AuthNotifier>() returns a singleton or factory.
    // If it's a singleton, disposing it here will break it for the rest of the app.
    super.dispose();
  }

  void _submit() {
    final state = _authNotifier.state;

    // Handle Email & Password Flow
    if (_useEmailPassword) {
      if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter email and password')),
        );
        return;
      }
      _authNotifier.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      return;
    }

    // Handle Phone OTP Flow
    if (state is AuthPhoneOtpSent) {
      FocusScope.of(context).unfocus();
      if (_otpController.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter the 6-digit OTP')),
        );
        return;
      }
      _authNotifier.verifyPhoneOtp(
        verificationId: state.verificationId,
        smsCode: _otpController.text.trim(),
        phoneNumber: state.phoneNumber,
        displayName: state.displayName,
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number')),
      );
      return;
    }

    if (!_isLogin && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a display name')),
      );
      return;
    }

    _authNotifier.requestPhoneOtp(
      phoneNumber: _phoneController.text.trim(),
      displayName: _isLogin ? null : _nameController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: _authNotifier,
        builder: (context, child) {
          final state = _authNotifier.state;

          if (state is AuthLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Connecting to Firebase...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    state is AuthPhoneOtpSent
                        ? 'Enter the 6-digit code sent to ${state.phoneNumber}'
                        : _isLogin
                            ? 'Enter your phone number to login.'
                            : 'Verify your phone number to create an account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700], height: 1.4),
                  ),
                  const SizedBox(height: 40),

                  if (state is AuthError) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _authNotifier.resetState(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('RETRY'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        state.message,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (state is AuthPhoneOtpSent) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _authNotifier.resetState(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (state.errorMessage != null) ...[
                      Text(
                        state.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 24, letterSpacing: 16, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        labelText: 'SMS Code',
                        hintText: '000000',
                        border: OutlineInputBorder(),
                        counterText: "",
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else if (_useEmailPassword) ...[
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                        hintText: 'e.g. john@example.com',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ] else ...[
                    if (!_isLogin) ...[
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'e.g. John Doe',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: 'e.g. +923001234567',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(
                      state is AuthPhoneOtpSent
                          ? 'VERIFY OTP'
                          : _useEmailPassword
                              ? 'LOGIN WITH EMAIL'
                              : _isLogin
                                  ? 'SEND OTP'
                                  : 'REGISTER & SEND OTP',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  if (state is! AuthPhoneOtpSent) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _useEmailPassword = !_useEmailPassword;
                        });
                      },
                      child: Text(_useEmailPassword
                          ? "Use Phone Number instead"
                          : "Use Email & Password instead"),
                    ),
                    if (!_useEmailPassword)
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                          });
                        },
                        child: Text(_isLogin
                            ? "Don't have an account? Register"
                            : "Already have an account? Login"),
                      ),
                  ],

                  if (_isLogin && _authNotifier.localAccounts.isNotEmpty && state is! AuthPhoneOtpSent) ...[
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Text('Recent Sessions', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 16),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _authNotifier.localAccounts.length,
                      itemBuilder: (context, index) {
                        final account = _authNotifier.localAccounts[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[200],
                            child: Text(StringSanitizer.initial(account.displayName), style: const TextStyle(color: Colors.black)),
                          ),
                          title: Text(account.displayName),
                          subtitle: Text(account.phoneNumber),
                          onTap: () {
                            _phoneController.text = account.phoneNumber;
                            _authNotifier.requestPhoneOtp(phoneNumber: account.phoneNumber);
                          },
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}