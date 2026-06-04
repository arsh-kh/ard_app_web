import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/providers/locale_provider.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/widgets/custom_loader.dart';

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
    final card   = theme.colorScheme.surface;
    final fg     = theme.colorScheme.onSurface;
    final muted  = Colors.grey.shade500;
    final border = isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Ambient glowing wave effect at the top
          Positioned(
            top: -100,
            left: -50,
            right: -50,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.15),
                    theme.colorScheme.primary.withOpacity(0.0),
                  ],
                  radius: 0.8,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 4.seconds),
          ),
          Positioned(
            top: -150,
            right: -100,
            child: Container(
              height: 350,
              width: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purpleAccent.withOpacity(0.12),
                    Colors.purpleAccent.withOpacity(0.0),
                  ],
                  radius: 0.8,
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 5.seconds)
             .moveX(begin: 0, end: -30, duration: 6.seconds),
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
                  builder: (_, __) => Transform.translate(
                    offset: Offset(0, (_floatAnim.value - 0.5) * 6),
                    child: SizedBox(
                      width: 130,
                      height: 150,
                      child: CustomPaint(
                        painter: _BagPainter(
                          look: _look,
                          eyeX: _eyeX,
                          peek: _peekAnim.value,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.15, end: 0, curve: Curves.easeOutBack),

                const SizedBox(height: 20),

                // ── Title & subtitle ─────────────────────────────────────
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Column(
                    key: ValueKey(_isLogin),
                    children: [
                      Text(
                        _isLogin ? loginTitle : regTitle,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: fg, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isLogin ? loginSub : regSub,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: muted),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 180.ms),

                const SizedBox(height: 24),

                // ── Card ─────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ── Tab bar ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                        child: Container(
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              _tab(label: signIn, selected: _isLogin, isDark: isDark, fg: fg, onTap: () => _switchTab(true)),
                              _tab(label: register, selected: !_isLogin, isDark: isDark, fg: fg, onTap: () => _switchTab(false)),
                            ],
                          ),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: selected ? (isDark ? Colors.white : Colors.black) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: selected ? (isDark ? Colors.black : Colors.white) : Colors.grey.shade500,
            ),
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
        fillColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
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
//  FLOUR BAG PAINTER
// ════════════════════════════════════════════════════════════════════════════
class _BagPainter extends CustomPainter {
  final int look;    // 0=idle, 1=tracking, 2=cover
  final double eyeX; // -0.8..+0.8
  final double peek; // 0=covered, 1=peeking
  final bool isDark;

  const _BagPainter({
    required this.look,
    required this.eyeX,
    required this.peek,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2 + 10;

    final bagColor = Colors.white;
    final shadeColor = const Color(0xFFDEDEDE);
    final knotColor = const Color(0xFF777777);
    final inkColor = Colors.black87;

    // ── Drop shadow ───────────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 62), width: 65, height: 9),
      Paint()
        ..color = isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
    );

    // ── Bag body ──────────────────────────────────────────────────────────
    final body = Path()
      ..moveTo(cx - 34, cy + 58)
      ..quadraticBezierTo(cx, cy + 66, cx + 34, cy + 58)
      ..quadraticBezierTo(cx + 47, cy + 24, cx + 38, cy - 6)
      ..quadraticBezierTo(cx + 32, cy - 30, cx + 17, cy - 36)
      ..lineTo(cx - 17, cy - 36)
      ..quadraticBezierTo(cx - 32, cy - 30, cx - 38, cy - 6)
      ..quadraticBezierTo(cx - 47, cy + 24, cx - 34, cy + 58)
      ..close();

    canvas.drawPath(body, Paint()..color = bagColor);
    canvas.drawPath(body, Paint()
      ..shader = LinearGradient(
        colors: [Colors.transparent, shadeColor.withOpacity(0.38)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(cx, cy - 36, 48, 102)));
    canvas.drawPath(body, Paint()
      ..color = inkColor.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3);

    // Seams
    final s = Paint()..color = shadeColor..strokeWidth = 0.9..style = PaintingStyle.stroke;
    for (final dy in [6.0, 20.0, 36.0]) {
      canvas.drawLine(Offset(cx - 26, cy + dy), Offset(cx + 26, cy + dy), s);
    }

    // Neck gather
    final fold = Paint()..color = knotColor.withOpacity(0.28)..strokeWidth = 1.6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    for (int i = -2; i <= 2; i++) {
      canvas.drawLine(Offset(cx + i * 3.5, cy - 33), Offset(cx + i * 2.0, cy - 44), fold);
    }

    // Knot
    canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy - 48), width: 15, height: 10), Paint()..color = knotColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 11, cy - 51), width: 10, height: 7), Paint()..color = knotColor);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 11, cy - 51), width: 10, height: 7), Paint()..color = knotColor);
    final t = Paint()..color = knotColor..strokeWidth = 2.5..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(cx - 6, cy - 43), Offset(cx - 11, cy - 36), t);
    canvas.drawLine(Offset(cx + 6, cy - 43), Offset(cx + 11, cy - 36), t);

    // (No belly text)

    // ═══ FACE ════════════════════════════════════════════════════════════
    if (look == 2) {
      _drawCovering(canvas, cx, cy, bagColor, shadeColor, knotColor, inkColor);
    } else {
      final ex = eyeX * 5.0;
      final ey = look == 1 ? 3.5 : 0.0;

      // Brows: two small round dots above eyes (not lines) — neutral look
      _drawBrowDot(canvas, cx - 14, cy - 27, inkColor);
      _drawBrowDot(canvas, cx + 14, cy - 27, inkColor);

      // Eyes
      _drawEye(canvas, cx - 14, cy - 10, ex, ey, bagColor, inkColor);
      _drawEye(canvas, cx + 14, cy - 10, ex, ey, bagColor, inkColor);

      // Blush
      canvas.drawOval(Rect.fromCenter(center: Offset(cx - 27, cy + 1), width: 12, height: 7),
          Paint()..color = inkColor.withOpacity(0.05));
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + 27, cy + 1), width: 12, height: 7),
          Paint()..color = inkColor.withOpacity(0.05));

      // Smile
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx, cy + 7), width: 20, height: 10),
        0, math.pi, false,
        Paint()..color = inkColor.withOpacity(0.25)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round,
      );
    }
  }

  // Covering: two hands from sides come in to cover eyes; on peek they drop revealing eyes above
  void _drawCovering(Canvas canvas, double cx, double cy,
      Color bag, Color shade, Color knot, Color ink) {
    // eyeY = cy - 10
    // hands at full cover: top of hands at ~cy-22, covering eyes
    // when peeking (peek=1): hands drop 22px → top of hands at cy
    //   → eyes (at cy-10) are fully visible ABOVE the hands
    final drop = peek * 22.0;
    final handTopY = cy - 22 + drop; // top edge of hand bar
    final handCenterY = handTopY + 14; // center of hand bar (28px tall)

    // Eyes become visible above the hands as they drop
    if (drop > 5) {
      final eyeReveal = ((drop - 5) / 17.0).clamp(0.0, 1.0);
      final eyeH = 3.0 + eyeReveal * 11.0;
      _drawNarrowEye(canvas, cx - 14, cy - 10, eyeH, bag, ink);
      _drawNarrowEye(canvas, cx + 14, cy - 10, eyeH, bag, ink);
    } else {
      // Fully shut eyes — but brows still drawn above
      final sp = Paint()
        ..color = ink.withOpacity(0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.3
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(Rect.fromCenter(center: Offset(cx - 14, cy - 12), width: 16, height: 8), 0, math.pi, false, sp);
      canvas.drawArc(Rect.fromCenter(center: Offset(cx + 14, cy - 12), width: 16, height: 8), 0, math.pi, false, sp);
    }

    // ── Two rounded hand-pads covering eyes ───────────────────────────────
    // Left hand: comes from the left side of the bag
    _drawHandPad(canvas, cx - 14, handCenterY, bag, shade);
    // Right hand: comes from the right side of the bag
    _drawHandPad(canvas, cx + 14, handCenterY, bag, shade);

    // ── Draw brows (always on top of everything) ────────────
    _drawBrowDot(canvas, cx - 14, cy - 27, ink);
    _drawBrowDot(canvas, cx + 14, cy - 27, ink);

    // Blush (stronger when peeking)
    final blush = 0.04 + peek * 0.14;
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - 28, cy + 4), width: 15, height: 9),
        Paint()..color = ink.withOpacity(blush));
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + 28, cy + 4), width: 15, height: 9),
        Paint()..color = ink.withOpacity(blush));

    // Mouth: nervous flat line → sneaky smirk when peeking
    final mp = Paint()
      ..color = ink.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    if (peek > 0.5) {
      canvas.drawArc(
        Rect.fromCenter(center: Offset(cx + 4, cy + 10), width: 15, height: 7),
        0.1, math.pi * 0.75, false, mp,
      );
    } else {
      canvas.drawLine(Offset(cx - 7, cy + 10), Offset(cx + 7, cy + 10), mp);
    }
  }

  // A single hand-pad: rounded rectangle + 4 finger bumps on top
  void _drawHandPad(Canvas canvas, double cx, double cy, Color bag, Color shade) {
    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 1.5, cy + 2.5), width: 32, height: 26),
        const Radius.circular(13),
      ),
      Paint()..color = shade.withOpacity(0.28)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
    // Palm
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 32, height: 26),
        const Radius.circular(13),
      ),
      Paint()..color = bag,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy), width: 32, height: 26),
        const Radius.circular(13),
      ),
      Paint()..color = shade.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 1.0,
    );
    // 4 finger bumps
    for (int i = 0; i < 4; i++) {
      final fx = cx - 10.5 + i * 7.0;
      final fy = cy - 14.5;
      canvas.drawCircle(Offset(fx + 1, fy + 1), 5.2, Paint()..color = shade.withOpacity(0.2));
      canvas.drawCircle(Offset(fx, fy), 5.2, Paint()..color = bag);
      canvas.drawCircle(Offset(fx, fy), 5.2,
          Paint()..color = shade.withOpacity(0.35)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }
  }

  // Normal open eye with pupil that tracks position
  void _drawEye(Canvas canvas, double x, double y, double ex, double ey, Color white, Color dark) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 21, height: 16), Paint()..color = white);
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 21, height: 16),
        Paint()..color = dark.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 1.1);
    final px = (x + ex).clamp(x - 5.0, x + 5.0);
    final py = (y + ey).clamp(y - 3.0, y + 3.0);
    canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = dark);
    // Highlight top-center of pupil (not shifted right)
    canvas.drawCircle(Offset(px, py - 2.2), 1.7, Paint()..color = white.withOpacity(0.82));
  }

  // Narrow slit eye for peeking (height grows as peek progresses)
  void _drawNarrowEye(Canvas canvas, double x, double y, double h, Color white, Color dark) {
    if (h < 1.0) return;
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 21, height: h), Paint()..color = white);
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: 21, height: h),
        Paint()..color = dark.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 1.0);
    final pr = (h * 0.45).clamp(1.5, 6.0);
    // Pupil looks slightly downward (toward the hands/password)
    canvas.drawCircle(Offset(x, y + h * 0.12), pr, Paint()..color = dark);
    canvas.drawCircle(Offset(x, y + h * 0.12 - pr * 0.35), (pr * 0.3).clamp(0.5, 2.0),
        Paint()..color = white.withOpacity(0.8));
  }

  // Two small dot brows (no lines, no angles — completely neutral)
  void _drawBrowDot(Canvas canvas, double x, double y, Color color) {
    final paint = Paint()..color = color.withOpacity(0.28);
    // Two small oval dots per brow
    canvas.drawOval(Rect.fromCenter(center: Offset(x - 4, y), width: 5, height: 3.5), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x + 4, y), width: 5, height: 3.5), paint);
  }

  @override
  bool shouldRepaint(_BagPainter o) =>
      o.look != look || o.eyeX != eyeX || o.peek != peek || o.isDark != isDark;
}
