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

class _LoginViewState extends State<LoginView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final FocusNode _userFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  bool _isUserFocused = false;
  bool _isPasswordFocused = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _setupFocusListeners();
    _animationController.forward();
  }

  void _setupFocusListeners() {
    _userFocusNode.addListener(() {
      setState(() => _isUserFocused = _userFocusNode.hasFocus);
    });
    _passwordFocusNode.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
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
      resizeToAvoidBottomInset:
          true, // ✅ Evita que el teclado tape el contenido
      backgroundColor: const Color(0xFFF2F6FC),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 40),
                          _buildLoginForm(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Círculo con efecto de profundidad y gradiente moderno

        // Título principal
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF003CFF), Color(0xFF00A7FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds),
          child: const Text(
            "ASA Rinde Gastos",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white, // se sobreescribe por el shader
              letterSpacing: -0.3,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Subtítulo con estilo elegante
        Text(
          "Ingresa tus credenciales para continuar",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),

        const SizedBox(height: 8),

        // Línea decorativa animada (detalle moderno)
        Container(
          margin: const EdgeInsets.only(top: 10),
          height: 3,
          width: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF0072FF), Color(0xFF00CFFF)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Form(
        key: widget.controller.formKey,
        child: Column(
          children: [
            _buildUserField(),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 30),
            _buildLoginButton(),
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
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: "Dni",
        labelStyle: TextStyle(
          color: _isUserFocused
              ? const Color(0xFF0066FF)
              : Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          Icons.person_outline_rounded,
          color: _isUserFocused
              ? const Color(0xFF0066FF)
              : Colors.grey.shade600,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: widget.controller.validateUser,
      textInputAction: TextInputAction.next,
      onFieldSubmitted: (_) =>
          FocusScope.of(context).requestFocus(_passwordFocusNode),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: widget.controller.passwordController,
      focusNode: _passwordFocusNode,
      obscureText: widget.controller.obscurePassword,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: "Contraseña",
        labelStyle: TextStyle(
          color: _isPasswordFocused
              ? const Color(0xFF0066FF)
              : Colors.grey.shade700,
        ),
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          color: _isPasswordFocused
              ? const Color(0xFF0066FF)
              : Colors.grey.shade600,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            widget.controller.obscurePassword
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _isPasswordFocused
                ? const Color(0xFF0066FF)
                : Colors.grey.shade600,
          ),
          onPressed: () => setState(() {
            widget.controller.togglePasswordVisibility();
          }),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: widget.controller.validatePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _onLoginPressed(),
    );
  }

  Widget _buildLoginButton() {
    final isValid =
        widget.controller.userController.text.isNotEmpty &&
        widget.controller.passwordController.text.isNotEmpty;

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isValid
              ? const Color(0xFF0066FF)
              : Colors.grey.shade400,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: isValid ? 6 : 0,
        ),
        onPressed: (isValid && !widget.controller.isLoading)
            ? _onLoginPressed
            : null,
        child: widget.controller.isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                "Iniciar sesión",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }
}
