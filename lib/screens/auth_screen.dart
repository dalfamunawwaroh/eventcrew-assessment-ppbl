import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../helpers/prefs_helper.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Warna Premium 
  final Color navyDark = const Color(0xFF0F172A); 
  final Color navyPrimary = const Color(0xFF1E3A8A); 
  final Color electricBlue = const Color(0xFF2563EB); 
  final Color mintGreen = const Color(0xFF10B981); 

  // Form Controllers
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController(); 

  // 🔥 STATE UNTUK TOGGLE ICON MATA (SHOW/HIDE PASSWORD)
  bool _isLoginPassVisible = false;
  bool _isRegPassVisible = false;

  final bool _isDarkMode = PrefsHelper.isDarkMode;

  @override
  void dispose() {
    _loginUserCtrl.dispose();
    _loginPassCtrl.dispose();
    _regNameCtrl.dispose();
    _regUserCtrl.dispose();
    _regPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color textColor = _isDarkMode ? Colors.white : navyDark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isDarkMode 
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B), const Color(0xFF0F172A)]
                  : [const Color(0xFFF8FAFC), const Color(0xFFE2E8F0), const Color(0xFFF1F5F9)],
            ),
          ),
          child: Stack(
            children: [
              // ORNAMEN BACKGROUND
              Positioned(
                top: -50, right: -50,
                child: Container(
                  width: 250, height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: mintGreen.withValues(alpha: _isDarkMode ? 0.3 : 0.4),
                  ),
                ),
              ),
              Positioned(
                bottom: -100, left: -60,
                child: Container(
                  width: 300, height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: electricBlue.withValues(alpha: _isDarkMode ? 0.3 : 0.4),
                  ),
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                  child: const SizedBox(),
                ),
              ),

              // KONTEN UTAMA
              Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 450),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
                            boxShadow: [
                              BoxShadow(color: electricBlue.withValues(alpha: 0.2), blurRadius: 30, offset: const Offset(0, 10))
                            ],
                          ),
                          child: ShaderMask(
                            shaderCallback: (bounds) => LinearGradient(
                              colors: [mintGreen, electricBlue],
                            ).createShader(bounds),
                            child: const Icon(Icons.hub_rounded, size: 56, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'EventCrew',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: -1, color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Satu aplikasi untuk semua kebutuhan acara.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: _isDarkMode ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 36),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              height: 58,
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                              ),
                              child: TabBar(
                                indicatorSize: TabBarIndicatorSize.tab,
                                dividerColor: Colors.transparent,
                                indicator: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: LinearGradient(colors: [mintGreen, electricBlue]),
                                  boxShadow: [BoxShadow(color: electricBlue.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))],
                                ),
                                labelColor: Colors.white,
                                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                unselectedLabelColor: _isDarkMode ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
                                tabs: const [
                                  Tab(text: 'Sign In'),
                                  Tab(text: 'Sign Up'),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          height: 440, 
                          child: TabBarView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildLoginForm(textColor),
                              _buildRegisterForm(textColor),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // FORM SIGN IN
  // ==========================================
  Widget _buildLoginForm(Color txtColor) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: txtColor, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Log in untuk mengakses workspace event kamu.', style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600)),
          const SizedBox(height: 28),
          
          _customTextField(controller: _loginUserCtrl, label: 'Username', icon: Icons.person_outline_rounded, obscure: false),
          const SizedBox(height: 16),
          
          // 🔥 KOMPONEN PASSWORD DENGAN IKON MATA TOGGLE (LOGIN)
          _customTextField(
            controller: _loginPassCtrl, 
            label: 'Password', 
            icon: Icons.lock_open_rounded, 
            obscure: !_isLoginPassVisible, // Tergantung state
            suffixIcon: IconButton(
              icon: Icon(
                _isLoginPassVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: _isDarkMode ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isLoginPassVisible = !_isLoginPassVisible;
                });
              },
            ),
          ),
          
          const Spacer(),
          _gradientButton(
            text: 'Sign In',
            onPressed: () async {
              String username = _loginUserCtrl.text.trim();
              String password = _loginPassCtrl.text;

              if (username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua kolom wajib diisi!'), backgroundColor: Colors.redAccent));
                return;
              }

              final prefs = await SharedPreferences.getInstance();
              String? savedName = prefs.getString('simulasi_nama_$username');
              String? savedPass = prefs.getString('simulasi_pass_$username');

              if (!mounted) return;

              if (savedName == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username belum terdaftar! Silakan Sign Up terlebih dahulu.'), backgroundColor: Colors.redAccent));
              } else if (savedPass != password) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password salah! Coba lagi.'), backgroundColor: Colors.redAccent));
              } else {
                await PrefsHelper.setUserName(savedName); 
                await PrefsHelper.setUserRole('Anggota'); 

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selamat datang kembali, $savedName!'), backgroundColor: mintGreen));
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FORM SIGN UP
  // ==========================================
  Widget _buildRegisterForm(Color txtColor) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Account ✨', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: txtColor, letterSpacing: -0.5)),
          const SizedBox(height: 6),
          Text('Bergabung dan buat event pertamamu sekarang.', style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600)),
          const SizedBox(height: 20),
          
          _customTextField(controller: _regNameCtrl, label: 'Nama Lengkap', icon: Icons.badge_outlined, obscure: false),
          const SizedBox(height: 12),
          _customTextField(controller: _regUserCtrl, label: 'Username', icon: Icons.alternate_email_rounded, obscure: false),
          const SizedBox(height: 12),
          
          // 🔥 KOMPONEN PASSWORD DENGAN IKON MATA TOGGLE (REGISTER)
          _customTextField(
            controller: _regPassCtrl, 
            label: 'Buat Password', 
            icon: Icons.lock_outline_rounded, 
            obscure: !_isRegPassVisible, // Tergantung state
            suffixIcon: IconButton(
              icon: Icon(
                _isRegPassVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                color: _isDarkMode ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isRegPassVisible = !_isRegPassVisible;
                });
              },
            ),
          ),
          
          const Spacer(),
          _gradientButton(
            text: 'Sign Up',
            onPressed: () async {
              String name = _regNameCtrl.text.trim();
              String username = _regUserCtrl.text.trim();
              String password = _regPassCtrl.text;

              if (name.isEmpty || username.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mohon lengkapi seluruh data pendaftaran!'), backgroundColor: Colors.redAccent));
                return;
              }
              
              final prefs = await SharedPreferences.getInstance();
              
              if (prefs.containsKey('simulasi_nama_$username')) {
                 if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username sudah terpakai, silakan gunakan username lain!'), backgroundColor: Colors.orange));
                 return;
              }

              await prefs.setString('simulasi_nama_$username', name);
              await prefs.setString('simulasi_pass_$username', password);

              await PrefsHelper.setUserName(name);
              await PrefsHelper.setUserRole('Anggota'); 

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pendaftaran berhasil! Selamat datang, $name!'), backgroundColor: mintGreen));
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
              }
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // REUSABLE COMPONENTS
  // ==========================================
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: child,
        ),
      ),
    );
  }

  // 🔥 FIX: Menambahkan parameter opsi `suffixIcon` ke _customTextField
  Widget _customTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    required bool obscure,
    Widget? suffixIcon, // <--- Parameter baru di sini
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _isDarkMode ? Colors.white : navyDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _isDarkMode ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _isDarkMode ? mintGreen : electricBlue, size: 20),
        suffixIcon: suffixIcon, // <--- Dipasang di sini
        filled: true,
        fillColor: _isDarkMode ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.7),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: electricBlue, width: 2),
        ),
      ),
    );
  }

  Widget _gradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(colors: [electricBlue, mintGreen]),
        boxShadow: [BoxShadow(color: electricBlue.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
      ),
    );
  }
}