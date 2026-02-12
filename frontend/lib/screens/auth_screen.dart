import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/todo_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      bool success;
      if (_isLogin) {
        success = await authProvider.login(
          _emailController.text.trim(), 
          _passwordController.text.trim()
        );
      } else {
        success = await authProvider.register(
          _usernameController.text.trim(), 
          _emailController.text.trim(), 
          _passwordController.text.trim()
        );
      }
      if (success && mounted) {
        Provider.of<TodoProvider>(context, listen: false).fetchTodos();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1), 
                      shape: BoxShape.circle
                    ),
                    child: Icon(
                      _isLogin ? Icons.login : Icons.person_add, 
                      size: 64, 
                      color: Theme.of(context).primaryColor
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _isLogin ? 'Welcome Back!' : 'Create Account', 
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold
                    )
                  ),
                  const SizedBox(height: 32),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!_isLogin) 
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username', 
                              prefixIcon: const Icon(Icons.person), 
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)
                              )
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter a username';
                              if (value.length < 3) return 'Username must be at least 3 characters';
                              return null;
                            },
                          ),
                        if (!_isLogin) const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email', 
                            prefixIcon: const Icon(Icons.email), 
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)
                            )
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter your email';
                            if (!value.contains('@')) return 'Please enter a valid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password', 
                            prefixIcon: const Icon(Icons.lock), 
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)
                            )
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Please enter a password';
                            if (!_isLogin && value.length < 6) return 'Password must be at least 6 characters';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (authProvider.error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50, 
                        borderRadius: BorderRadius.circular(8)
                      ),
                      child: Text(
                        authProvider.error!, 
                        style: TextStyle(color: Colors.red.shade800),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16), 
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      )
                    ),
                    child: authProvider.isLoading 
                      ? const CircularProgressIndicator(color: Colors.white) 
                      : Text(
                          _isLogin ? 'Sign In' : 'Sign Up', 
                          style: const TextStyle(fontSize: 16)
                        ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(
                      _isLogin 
                        ? 'Don\'t have an account? Sign Up' 
                        : 'Already have an account? Sign In'
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
