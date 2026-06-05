import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/widgets/custom_loader.dart';
import '../../core/widgets/flour_bag_painter.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _loginFormKey = GlobalKey<FormState>();
  final _registerFormKey = GlobalKey<FormState>();

  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  final _emailFocus = FocusNode();
  final _passFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _regEmailFocus = FocusNode();
  final _regPassFocus = FocusNode();

  bool _isLogin = true;
  bool _obscurePass = true;
  bool _obscureRegPass = true;

  // 0=idle, 1=tracking text, 2=password (cover eyes)
  int _look = 0;
  double _eyeX = 0.0; // -1.0..+1.0

  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  late AnimationController _peekCtrl;
  late Animation<double> _peekAnim;
  late AnimationController _tabCtrl;

  @override
  void initState() {
    super.initState();

    _floatCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))
      ..repeat(reverse: true);
    _floatAnim = CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut);

    _peekCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));
    _peekAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 28),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 22),
    ]).animate(_peekCtrl);

    _tabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

    for (final fn in [_emailFocus, _passFocus, _nameFocus, _regEmailFocus, _regPassFocus]) {
      fn.addListener(_onFocus);
    }
    _emailCtrl.addListener(_onEmailChange);
    _regEmailCtrl.addListener(_onRegEmailChange);
    _nameCtrl.addListener(_onNameChange);
  }

  void _onFocus() {
    final isPassFocused = _passFocus.hasFocus || _regPassFocus.hasFocus;
    final isTextFocused = _emailFocus.hasFocus || _nameFocus.hasFocus || _regEmailFocus.hasFocus;
    final next = isPassFocused ? 2 : isTextFocused ? 1 : 0;
    if (next == _look) return;
    setState(() => _look = next);
    if (next == 2) {
      _peekCtrl.repeat();
    } else {
      _peekCtrl.stop();
      _peekCtrl.reset();
    }
    if (next != 1) setState(() => _eyeX = 0.0);
  }

  void _onEmailChange() => _updateEye(_emailCtrl.text);
  void _onRegEmailChange() => _updateEye(_regEmailCtrl.text);
  void _onNameChange() => _updateEye(_nameCtrl.text);

  void _updateEye(String text) {
    if (_look != 1) return;
    final r = (text.length / 25.0).clamp(0.0, 1.0);
    setState(() {
      _eyeX = (r * 1.2) - 0.6;
    });
  }

  @override
  void dispose() {
    for (final c in [_emailCtrl, _passCtrl, _nameCtrl, _regEmailCtrl, _regPassCtrl]) {
      c.dispose();
    }
    for (final fn in [_emailFocus, _passFocus, _nameFocus, _regEmailFocus, _regPassFocus]) {
      fn.dispose();
    }
    _floatCtrl.dispose();
    _peekCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _switchTab(bool login) {
    if (_isLogin == login) return;
    setState(() {
      _isLogin = login;
      _look = 0;
      _eyeX = 0.0;
    });
    _peekCtrl.stop();
    _peekCtrl.reset();
    if (login) {
      _tabCtrl.reverse();
    } else {
      _tabCtrl.forward();
    }
  }

  void _submit() async {
    final key = _isLogin ? _loginFormKey : _registerFormKey;
    if (!(key.currentState?.validate() ?? false)) return;

    final auth = ref.read(authProvider.notifier);
    String? error;

    if (_isLogin) {
      error = await auth.login(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );
    } else {
      error = await auth.register(
        name: _nameCtrl.text,
        email: _regEmailCtrl.text,
        password: _regPassCtrl.text,
      );
    }

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
    // Router will automatically redirect on successful auth via redirect logic
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locale = ref.watch(localeProvider);
    final lang = locale.languageCode;

    // ── Localized strings ─────────────────────────────────────────────────
    final signIn    = lang == 'ku' ? 'چوونە ژوورەوە' : lang == 'ar' ? 'تسجيل الدخول' : 'Sign In';
    final register  = lang == 'ku' ? 'تۆمارکردن' : lang == 'ar' ? 'إنشاء حساب' : 'Register';
    final loginTitle= lang == 'ku' ? 'بەخێربێیت' : lang == 'ar' ? 'مرحباً بك' : 'Welcome back';
    final loginSub  = lang == 'ku' ? 'زانیاریەکانت بنووسە بۆ چوونە ژوورەوە' : lang == 'ar' ? 'أدخل بياناتك للمتابعة' : 'Sign in to access your account';
    final regTitle  = lang == 'ku' ? 'هەژمار دروست بکە' : lang == 'ar' ? 'إنشاء حساب جديد' : 'Create account';
    final regSub    = lang == 'ku' ? 'بەخێربێیت، زانیارییەکانت تۆمار بکە' : lang == 'ar' ? 'مرحباً، أدخل بياناتك للتسجيل' : 'Register to get started';
    final emailLbl  = lang == 'ku' ? 'ئیمەیڵ' : lang == 'ar' ? 'البريد الإلكتروني' : 'Email';
    final passLbl   = lang == 'ku' ? 'وشەی نهێنی' : lang == 'ar' ? 'كلمة المرور' : 'Password';
    final nameLbl   = lang == 'ku' ? 'ناوی تەواو' : lang == 'ar' ? 'الاسم الكامل' : 'Full name';
    final req       = lang == 'ku' ? 'پێویستە' : lang == 'ar' ? 'مطلوب' : 'Required';

    final theme  = Theme.of(context);
    final bg     = theme.scaffoldBackgroundColor;
    
    final fg     = theme.colorScheme.onSurface;
    final muted  = Colors.grey.shade500;
    final border = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05);

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Elegant Animated Monochrome Waves
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatAnim,
              builder: (context, _) {
                return CustomPaint(
                  painter: _MonochromeWavePainter(
                    baseColor: fg,
                    animValue: _floatAnim.value,
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── Mascot ───────────────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_floatAnim, _peekAnim]),
                  builder: (_, __) {
                    final floatOffset = (_floatAnim.value - 0.5) * 6;
                    return Column(
                      children: [
                        Transform.translate(
                          offset: Offset(0, floatOffset),
                          child: SizedBox(
                            width: 130,
                            height: 150,
                            child: CustomPaint(
                              painter: FlourBagPainter(
                                look: _look,
                                eyeX: _eyeX,
                                peek: _peekAnim.value,
                                isDark: isDark,
                                textDirection: Directionality.of(context),
                              ),
                            ),
                          ),
                        ),
                        // Dynamic Pedestal Shadow
                        Container(
                          width: 80 - (_floatAnim.value * 20),
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0, curve: Curves.easeOutBack),

                const SizedBox(height: 20),

                // ── Title & subtitle ─────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(_isLogin),
                    children: [
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${(_isLogin ? loginTitle : regTitle).split(' ').first} ',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: fg, letterSpacing: -1.0),
                            ),
                            TextSpan(
                              text: (_isLogin ? loginTitle : regTitle).split(' ').skip(1).join(' '),
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w300, color: fg, letterSpacing: -0.5),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin ? loginSub : regSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: muted, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 180.ms),

                const SizedBox(height: 24),

                // ── Glassmorphism Card ───────────────────────────────────
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                  child: Column(
                    children: [
                      // ── Tab bar ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tabWidth = constraints.maxWidth / 2;
                            return Container(
                              height: 44,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Stack(
                                children: [
                                  // Sliding Pill Indicator
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    top: 4,
                                    bottom: 4,
                                    left: _isLogin ? 4 : tabWidth + 2,
                                    width: tabWidth - 6,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.black : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.05),
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Tab Buttons
                                  Row(
                                    children: [
                                      _tab(label: signIn, selected: _isLogin, isDark: isDark, fg: fg, onTap: () => _switchTab(true)),
                                      _tab(label: register, selected: !_isLogin, isDark: isDark, fg: fg, onTap: () => _switchTab(false)),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ),

                      // ── Form ─────────────────────────────────────────
                      AnimatedSize(
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOut,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                          child: _isLogin
                              ? _buildLoginForm(emailLbl, passLbl, req, signIn, fg, border, isDark, isLoading)
                              : _buildRegisterForm(nameLbl, emailLbl, passLbl, req, register, fg, border, isDark, isLoading),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _tab({required String label, required bool selected, required bool isDark, required Color fg, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 250),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? fg : Colors.grey.shade500,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(String emailLbl, String passLbl, String req, String submitLbl,
      Color fg, Color border, bool isDark, bool isLoading) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(ctrl: _emailCtrl, focus: _emailFocus, label: emailLbl, hint: 'you@example.com',
              icon: Icons.email_outlined, isDark: isDark, fg: fg, border: border,
              validator: (v) => (v == null || v.isEmpty) ? req : null),
          const SizedBox(height: 12),
          _field(ctrl: _passCtrl, focus: _passFocus, label: passLbl, hint: '••••••••',
              icon: Icons.lock_outline, isDark: isDark, fg: fg, border: border,
              obscure: _obscurePass,
              suffix: IconButton(
                icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey.shade500, size: 19),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
              validator: (v) => (v == null || v.isEmpty) ? req : null),
          const SizedBox(height: 20),
          _submitBtn(label: submitLbl, isDark: isDark, fg: fg, isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _buildRegisterForm(String nameLbl, String emailLbl, String passLbl, String req, String submitLbl,
      Color fg, Color border, bool isDark, bool isLoading) {
    return Form(
      key: _registerFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(ctrl: _nameCtrl, focus: _nameFocus, label: nameLbl, hint: 'John Doe',
              icon: Icons.person_outline, isDark: isDark, fg: fg, border: border,
              validator: (v) => (v == null || v.isEmpty) ? req : null),
          const SizedBox(height: 12),
          _field(ctrl: _regEmailCtrl, focus: _regEmailFocus, label: emailLbl, hint: 'you@example.com',
              icon: Icons.email_outlined, isDark: isDark, fg: fg, border: border,
              validator: (v) => (v == null || v.isEmpty) ? req : null),
          const SizedBox(height: 12),
          _field(ctrl: _regPassCtrl, focus: _regPassFocus, label: passLbl, hint: '••••••••',
              icon: Icons.lock_outline, isDark: isDark, fg: fg, border: border,
              obscure: _obscureRegPass,
              suffix: IconButton(
                icon: Icon(_obscureRegPass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: Colors.grey.shade500, size: 19),
                onPressed: () => setState(() => _obscureRegPass = !_obscureRegPass),
              ),
              validator: (v) => (v == null || v.isEmpty) ? req : null),
          const SizedBox(height: 20),
          _submitBtn(label: submitLbl, isDark: isDark, fg: fg, isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required FocusNode focus,
    required String label, required String hint, required IconData icon,
    required bool isDark, required Color fg, required Color border,
    bool obscure = false, Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      focusNode: focus,
      obscureText: obscure,
      textDirection: TextDirection.ltr,
      style: TextStyle(color: fg, fontSize: 17, letterSpacing: 0.2),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        hintStyle: TextStyle(color: isDark ? Colors.grey.shade700 : Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: fg, width: 1.8)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade400)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade500, width: 1.8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      validator: validator,
    );
  }

  Widget _submitBtn({required String label, required bool isDark, required Color fg, required bool isLoading}) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: fg,
          foregroundColor: isDark ? Colors.black : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: isLoading ? null : _submit,
        child: isLoading
            ? const CustomLoader(size: 24)
            : Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
    );
  }
}



// ════════════════════════════════════════════════════════════════════════════
//  MONOCHROME WAVE PAINTER
// ════════════════════════════════════════════════════════════════════════════
class _MonochromeWavePainter extends CustomPainter {
  final Color baseColor;
  final double animValue; // 0.0 to 1.0

  _MonochromeWavePainter({required this.baseColor, required this.animValue});

  @override
  void paint(Canvas canvas, Size size) {
    // We create smooth, sweeping curves that gently shift with animValue.
    // animValue goes 0 -> 1 -> 0 continuously over 3 seconds.
    final shift = (animValue - 0.5) * 40; // Shifts up to +/- 20 pixels

    // Wave 1: Large soft background wave
    final path1 = Path();
    path1.lineTo(0, size.height * 0.55 + shift);
    path1.quadraticBezierTo(size.width * 0.25, size.height * 0.40 - shift, size.width * 0.60, size.height * 0.55 + shift * 0.5);
    path1.quadraticBezierTo(size.width * 0.85, size.height * 0.65 - shift * 0.5, size.width, size.height * 0.50 + shift);
    path1.lineTo(size.width, 0);
    path1.close();

    canvas.drawPath(path1, Paint()..color = baseColor.withValues(alpha: 0.02));

    // Wave 2: Medium overlapping wave
    final path2 = Path();
    path2.lineTo(0, size.height * 0.40 - shift);
    path2.quadraticBezierTo(size.width * 0.35, size.height * 0.55 + shift, size.width * 0.70, size.height * 0.40 - shift * 0.5);
    path2.quadraticBezierTo(size.width * 0.90, size.height * 0.35 + shift * 0.5, size.width, size.height * 0.45 - shift);
    path2.lineTo(size.width, 0);
    path2.close();

    canvas.drawPath(path2, Paint()..color = baseColor.withValues(alpha: 0.025));

    // Wave 3: Smallest accent wave
    final path3 = Path();
    path3.lineTo(0, size.height * 0.25 + shift * 0.5);
    path3.quadraticBezierTo(size.width * 0.40, size.height * 0.15 - shift, size.width * 0.80, size.height * 0.30 + shift);
    path3.quadraticBezierTo(size.width * 0.95, size.height * 0.35 - shift * 0.5, size.width, size.height * 0.25);
    path3.lineTo(size.width, 0);
    path3.close();

    canvas.drawPath(path3, Paint()..color = baseColor.withValues(alpha: 0.03));
    
    // Aesthetic structural circles
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.75 + shift), 120, 
      Paint()..color = baseColor.withValues(alpha: 0.015)
             ..style = PaintingStyle.stroke
             ..strokeWidth = 1.5);
             
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.85 - shift), 80, 
      Paint()..color = baseColor.withValues(alpha: 0.015)
             ..style = PaintingStyle.stroke
             ..strokeWidth = 1);

    // Cinematic Dust Particles
    final random = math.Random(42); // Seeded for consistency
    for (int i = 0; i < 20; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final speed = 0.2 + random.nextDouble() * 0.8;
      final r = 1.0 + random.nextDouble() * 2.0;
      
      // Calculate current Y position moving upward over time
      final currentY = startY - (animValue * size.height * speed);
      // Wrap around
      final wrappedY = currentY < 0 ? currentY + size.height : currentY;
      
      // Gentle horizontal sway
      final sway = math.sin((animValue * math.pi * 2) + i) * 10;
      
      canvas.drawCircle(Offset(startX + sway, wrappedY), r, 
        Paint()..color = baseColor.withValues(alpha: 0.03 + random.nextDouble() * 0.05));
    }
  }

  @override
  bool shouldRepaint(_MonochromeWavePainter oldDelegate) => 
      oldDelegate.baseColor != baseColor || oldDelegate.animValue != animValue;
}
