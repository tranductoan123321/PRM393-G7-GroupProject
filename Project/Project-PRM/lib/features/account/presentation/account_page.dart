import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../data/account_repository.dart';
import '../models/account_user.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({required this.repository, super.key});

  final AccountRepository repository;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  AccountUser? _user;
  String? _error;
  bool _isLoading = true;
  bool _isSigningIn = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadAccount();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadAccount() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (await widget.repository.hasSession()) {
        _user = await widget.repository.fetchCurrentUser();
      } else {
        _user = null;
      }
    } on DioException catch (error) {
      _error = error.response?.statusCode == 401
          ? 'Your session has expired. Please sign in again.'
          : error.message ?? 'Could not connect to the account service.';
      if (!await widget.repository.hasSession()) _user = null;
    } on FormatException catch (error) {
      _error = error.message;
      if (!await widget.repository.hasSession()) _user = null;
    } catch (error) {
      _error = 'Could not load account details: $error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isSigningIn = true;
      _error = null;
    });
    try {
      await widget.repository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      _passwordController.clear();
      await _loadAccount();
    } on DioException catch (error) {
      setState(() {
        _error = error.response?.statusCode == 401
            ? 'Incorrect email or password.'
            : error.message ?? 'Could not connect to the account service.';
      });
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  Future<void> _signOut() async {
    await widget.repository.signOut();
    if (!mounted) return;
    setState(() {
      _user = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My account')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? _buildSignIn()
          : _buildProfile(_user!),
    );
  }

  Widget _buildSignIn() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.account_circle_outlined, size: 72),
                const SizedBox(height: 16),
                Text(
                  'Sign in to view your account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.username],
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty || !email.contains('@')) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: () => setState(
                        () => _obscurePassword = !_obscurePassword,
                      ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => (value?.isEmpty ?? true)
                      ? 'Enter your password.'
                      : null,
                  onFieldSubmitted: (_) => _signIn(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _isSigningIn ? null : _signIn,
                  child: _isSigningIn
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfile(AccountUser user) {
    final imagePath = user.profileImagePath;
    final imageUrl = imagePath == null
        ? null
        : 'https://efashion-backend.onrender.com/api/u/profile/${Uri.encodeComponent(imagePath)}';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundImage: imageUrl == null ? null : CachedNetworkImageProvider(imageUrl),
            child: imageUrl == null
                ? const Icon(Icons.person_outline, size: 48)
                : null,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          user.fullName.isEmpty ? 'Your account' : user.fullName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        _ProfileField(label: 'Email', value: user.email, icon: Icons.email_outlined),
        _ProfileField(
          label: 'Phone number',
          value: user.phoneNumber.isEmpty ? 'Not provided' : user.phoneNumber,
          icon: Icons.phone_outlined,
        ),
        _ProfileField(
          label: 'Account ID',
          value: user.id.isEmpty ? 'Not available' : user.id,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _signOut,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
      ),
    );
  }
}
