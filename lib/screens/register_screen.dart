import 'package:dismed/core/auth_provider.dart';
import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameFieldController = TextEditingController();
  final _emailFieldController = TextEditingController();
  final _passwordFieldController = TextEditingController();
  final _confirmFieldController = TextEditingController();

  bool _obsureText = true;
  bool _submitting = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      _emailFieldController.text.trim(),
      _passwordFieldController.text,
      _nameFieldController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _submitting = false;
    });

    if (success) {
      if (auth.isAuthenticated) {
        Navigator.pushReplacementNamed(context, "/splash");
      } else {
        String text = auth.error ?? "Failed to Register";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

        auth.clearError();
      }
    }
  }

  @override
  void dispose() {
    _nameFieldController.dispose();
    _emailFieldController.dispose();
    _passwordFieldController.dispose();
    _confirmFieldController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 50),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 48),
                  Text(
                    "Create Account",
                    style: GoogleFonts.roboto(
                      textStyle: context.textTheme.headlineLarge?.copyWith(
                        color: context.colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Name Field
                  _RegisterTextField(
                    controller: _nameFieldController,
                    hint: "Name",
                    prefixIcon: Icons.account_circle_rounded,
                    keyboardType: TextInputType.name,
                  ),

                  const SizedBox(height: 25),

                  // Email Field
                  _RegisterTextField(
                    controller: _emailFieldController,
                    hint: "Email Address",
                    prefixIcon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,

                    validator: (v) => v == null || !v.contains("@") ? "Enter a valid email" : null,
                  ),

                  const SizedBox(height: 25),

                  // Password
                  _RegisterTextField(
                    controller: _passwordFieldController,
                    hint: "Password",
                    prefixIcon: Icons.lock_rounded,
                    suffixIcon: IconButton(
                      onPressed: () => {
                        setState(() {
                          _obsureText = !_obsureText;
                        }),
                      },
                      icon: Icon(
                        _obsureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      ),
                    ),
                    obscureText: _obsureText,
                    keyboardType: TextInputType.visiblePassword,
                    validator: (v) => v == null || v.length < 6
                        ? "Password must be greater than 6 characters"
                        : null,
                  ),

                  const SizedBox(height: 25),

                  // Confirm Password
                  _RegisterTextField(
                    controller: _confirmFieldController,
                    hint: "Confirm Password",
                    prefixIcon: Icons.lock_rounded,
                    obscureText: _obsureText,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() {
                        _obsureText = !_obsureText;
                      }),
                      icon: Icon(
                        _obsureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      ),
                    ),

                    keyboardType: TextInputType.visiblePassword,
                    validator: (v) => v == null || v != _passwordFieldController.text
                        ? "Passwords do not match"
                        : null,
                  ),

                  const SizedBox(height: 50),
                  // Create Account Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        backgroundColor: context.colors.secondaryContainer,
                        foregroundColor: context.colors.onSurfaceVariant,
                      ),
                      onPressed: _submitting ? null : _handleRegister,
                      child: _submitting
                          ? CircularProgressIndicator()
                          : Text(
                              "Create Account",
                              style: GoogleFonts.roboto(
                                color: context.colors.onSurfaceVariant,
                                textStyle: context.textTheme.labelLarge?.copyWith(fontSize: 24),
                              ),
                            ),
                    ),
                  ),

                  // SignIn Instead?
                  const SizedBox(height: 15),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Already have an account?",
                        style: GoogleFonts.roboto(textStyle: context.textTheme.labelMedium),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: Text(
                          "SignIn",
                          style: GoogleFonts.roboto(
                            decoration: TextDecoration.underline,
                            textStyle: context.textTheme.labelMedium,
                            color: context.colors.tertiary,
                          ),
                        ),
                      ),
                    ],
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

class _RegisterTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? obscuringCharacter;
  const _RegisterTextField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.obscuringCharacter,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: true,
      controller: controller,
      obscureText: obscureText,
      obscuringCharacter: obscuringCharacter ?? '*',
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.roboto(textStyle: context.textTheme.labelLarge),
      decoration: InputDecoration(
        filled: true,
        fillColor: context.colors.surface,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          textStyle: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w300),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: context.colors.onSurface),
        ),

        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
