import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback? onRegisterSuccess;
  
  const RegisterScreen({
    super.key,
    this.onRegisterSuccess,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await AuthService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        surname: _surnameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (response.user != null) {
        // Kayıt başarılı olduğunda, kullanıcının otomatik giriş yapıp yapmadığını kontrol et
        // Eğer email confirmation gerekliyse, otomatik giriş yapmayabilir
        if (!AuthService.isAuthenticated) {
          // Otomatik giriş yapılmamışsa, email ve şifre ile giriş yap
          try {
            await AuthService.signInWithEmail(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
          } catch (e) {
            // Giriş yapılamazsa, kullanıcıya bilgi ver
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Kayıt başarılı! Lütfen email adresinizi doğrulayın ve giriş yapın.'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
            // Giriş yapılamadığı için callback'i çağırma, sadece geri dön
            if (mounted) {
              Navigator.pop(context, false);
            }
            return;
          }
        }
        
        // Kullanıcı giriş yapmış durumda
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kayıt başarılı! Hoş geldiniz.'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          
          if (widget.onRegisterSuccess != null) {
            widget.onRegisterSuccess!();
          } else {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('User already registered')
                  ? 'Bu email adresi zaten kayıtlı'
                  : 'Kayıt olurken bir hata oluştu',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/other_page.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: AppTheme.darkText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    'Kayıt Ol',
                    style: AppTheme.headingLarge.copyWith(
                      color: AppTheme.darkText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yeni hesap oluşturun',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.grayText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Name input
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Ad',
                      hintText: 'Adınızı giriniz',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.tealBlue),
                      filled: true,
                      fillColor: AppTheme.inputFieldGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.tealBlue, width: 2),
                      ),
                    ),
                    style: AppTheme.bodyMedium,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ad gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Surname input
                  TextFormField(
                    controller: _surnameController,
                    decoration: InputDecoration(
                      labelText: 'Soyad',
                      hintText: 'Soyadınızı giriniz',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.tealBlue),
                      filled: true,
                      fillColor: AppTheme.inputFieldGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.tealBlue, width: 2),
                      ),
                    ),
                    style: AppTheme.bodyMedium,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Soyad gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Email input
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'ornek@email.com',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.tealBlue),
                      filled: true,
                      fillColor: AppTheme.inputFieldGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.tealBlue, width: 2),
                      ),
                    ),
                    style: AppTheme.bodyMedium,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email adresi gerekli';
                      }
                      if (!value.contains('@')) {
                        return 'Geçerli bir email adresi giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Phone input
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Telefon',
                      hintText: '05XX XXX XX XX',
                      prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.tealBlue),
                      filled: true,
                      fillColor: AppTheme.inputFieldGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.tealBlue, width: 2),
                      ),
                    ),
                    style: AppTheme.bodyMedium,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefon numarası gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Password input
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre',
                      hintText: 'En az 6 karakter',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.tealBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.iconGray,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppTheme.inputFieldGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.tealBlue, width: 2),
                      ),
                    ),
                    style: AppTheme.bodyMedium,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalıdır';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Confirm password input
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Şifre Tekrar',
                      hintText: 'Şifrenizi tekrar giriniz',
                      prefixIcon: Icon(Icons.lock_outline, color: AppTheme.tealBlue),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppTheme.iconGray,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: AppTheme.inputFieldGray,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dividerLight),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.tealBlue, width: 2),
                      ),
                    ),
                    style: AppTheme.bodyMedium,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre tekrarı gerekli';
                      }
                      if (value != _passwordController.text) {
                        return 'Şifreler eşleşmiyor';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  // Register button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.tealBlue,
                      foregroundColor: AppTheme.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Kayıt Ol',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.white,
                              fontWeight: FontWeight.w600,
                            ),
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

