import 'package:dismed/utils/context_theme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameFieldController = TextEditingController();
  final _emailFieldController = TextEditingController();
  final _passwordFieldController = TextEditingController();
  final _confirmFieldController = TextEditingController();

  var obsureText = true;

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
                  _LoginTextField(
                    controller: _nameFieldController,
                    hint: "Name",
                    prefixIcon: Icons.account_circle_rounded,
                    keyboardType: TextInputType.name,
                  ),

                  const SizedBox(height: 25),

                  // Email Field
                  _LoginTextField(
                    controller: _emailFieldController,
                    hint: "Email Address",
                    prefixIcon: Icons.mail_rounded,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  const SizedBox(height: 25),

                  // Password
                  _LoginTextField(
                    controller: _passwordFieldController,
                    hint: "Password",
                    prefixIcon: Icons.lock_rounded,
                    suffixIcon: IconButton(
                      onPressed: () => {
                        setState(() {
                          obsureText = !obsureText;
                        }),
                      },
                      icon: Icon(
                        obsureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      ),
                    ),
                    obscureText: obsureText,
                    keyboardType: TextInputType.visiblePassword,
                  ),

                  const SizedBox(height: 25),

                  // Confirm Password
                  _LoginTextField(
                    controller: _confirmFieldController,
                    hint: "Confirm Password",
                    prefixIcon: Icons.lock_rounded,
                    obscureText: obsureText,
                    suffixIcon: IconButton(
                      onPressed: () => setState(() {
                        obsureText = !obsureText;
                      }),
                      icon: Icon(
                        obsureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      ),
                    ),

                    keyboardType: TextInputType.visiblePassword,
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
                      onPressed: () {},
                      child: Text(
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
                      Text(
                        "SignIn",
                        style: GoogleFonts.roboto(
                          decoration: TextDecoration.underline,
                          textStyle: context.textTheme.labelMedium,
                          color: context.colors.tertiary,
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

class _LoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscureText;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? obscuringCharacter;
  const _LoginTextField({
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
