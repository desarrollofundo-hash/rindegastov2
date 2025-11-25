import 'dart:ui';
import 'package:flutter/material.dart';
import '../controllers/login_controller.dart';

class LoginView extends StatefulWidget {
  final LoginController controller;
  final VoidCallback onLogin;
  final VoidCallback onForgotPassword;
  final VoidCallback onRegister;

  const LoginView({
    super.key,
    required this.controller,
    required this.onLogin,
    required this.onForgotPassword,
    required this.onRegister,
  });

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _userFocusNode.addListener(() {
      setState(() {});
    });
    _passwordFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _userFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    _userFocusNode.unfocus();
    _passwordFocusNode.unfocus();
    widget.onLogin();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLogos(),
                const SizedBox(height: 80),
                _buildHeader(),
                const SizedBox(height: 160),
                _buildLoginForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogos() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/img/interandina.jpg', height: 70),
          const SizedBox(width: 32),
          Image.asset('assets/img/santaazul.jpg', height: 50),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          "ASA Rinde Gastos",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A2843),
            letterSpacing: -0.5,
            /*             fontFamily: 'Rubik',
 */
          ),
        ),
        const SizedBox(height: 12),
        Text(
          "Ingresa tus credenciales para continuar",
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(0),
      child: Form(
        key: widget.controller.formKey,
        child: Column(
          children: [
            _buildUserField(),
            const SizedBox(height: 24),
            _buildPasswordField(),
            const SizedBox(height: 32),
            _buildLoginButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildUserField() {
    return TextFormField(
      controller: widget.controller.userController,
      focusNode: _userFocusNode,
      keyboardType: TextInputType.number,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1A2843),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: "DNI",
        hintText: "Ej: 12345678",
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5F7F),
        ),
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6B7FA3)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8F3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8F3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: widget.controller.validateUser,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_passwordFocusNode),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      textCapitalization: TextCapitalization.words,
      textInputAction: TextInputAction.done,
      keyboardType: TextInputType.visiblePassword,
      controller: widget.controller.passwordController,
      focusNode: _passwordFocusNode,
      obscureText: widget.controller.obscurePassword,
      style: const TextStyle(
        fontSize: 16,
        color: Color(0xFF1A2843),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: "Contraseña",
        hintText: "Ingrese su contraseña",
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5F7F),
        ),
        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade400),
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6B7FA3)),
        suffixIcon: IconButton(
          icon: Icon(
            widget.controller.obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: const Color(0xFF6B7FA3),
          ),
          onPressed: () => setState(() {
            widget.controller.togglePasswordVisibility();
          }),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8F3), width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE3E8F3), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: widget.controller.validatePassword,
      onFieldSubmitted: (_) => _onLoginPressed(),
    );
  }

  Widget _buildLoginButton() {
    final isValid =
        widget.controller.userController.text.isNotEmpty &&
        widget.controller.passwordController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid
              ? const Color(0xFF0066CC)
              : const Color(0xFFCCDCF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: isValid ? 4 : 0,
          shadowColor: const Color(0xFF0066CC).withOpacity(0.4),
        ),
        onPressed: (isValid && !widget.controller.isLoading)
            ? _onLoginPressed
            : null,
        child: widget.controller.isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                "Iniciar sesión",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isValid ? Colors.white : Colors.grey.shade500,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
