import 'package:flutter/material.dart';
import '../helpers/prefs_helper.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  // Palet Warna Premium ala Dribbble (Bebas Error)
  final Color navyDark = const Color(0xFF0F172A); 
  final Color navyPrimary = const Color(0xFF1E3A8A); 
  final Color electricBlue = const Color(0xFF2563EB); 
  final Color mintGreen = const Color(0xFF10B981); 
  final Color softIce = const Color(0xFFEEF2F6); 

  // Form Controllers
  final _loginUserCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();
  final _regNameCtrl = TextEditingController();
  final _regUserCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();
  String _selectedRole = 'Ketuplak';

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
    // Tema Warna Adaptif dengan Kontras Tinggi
    final Color backgroundColor = _isDarkMode ? navyDark : softIce;
    final Color cardColor = _isDarkMode ? const Color(0xFF1E293B) : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final Color inputFillColor = _isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            // 🎨 ORNAMEN BACKGROUND: Efek lingkaran gradasi abstrak ala Pinterest (Glassmorphic Backdrop)
            Positioned(
              top: -80,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (_isDarkMode ? mintGreen : electricBlue).withValues(alpha: 0.25),
                      (_isDarkMode ? mintGreen : electricBlue).withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      navyPrimary.withValues(alpha: _isDarkMode ? 0.2 : 0.15),
                      navyPrimary.withValues(alpha: 0),
                    ],
                  ),
                ),
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
                      // LOGO DENGAN EFEK GRADASI & GLOW
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: (_isDarkMode ? mintGreen : electricBlue).withValues(alpha: 0.15),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: _isDarkMode ? [mintGreen, Colors.tealAccent] : [navyPrimary, electricBlue],
                          ).createShader(bounds),
                          child: const Icon(Icons.blur_on_rounded, size: 56, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'EventCrew',
                        style: TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.w900, // FIX: Mengganti .black menjadi .w900
                          letterSpacing: -0.5,
                          color: textColor
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Manage your events, crew, and budget seamlessly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: _isDarkMode ? Colors.blueGrey.shade300 : Colors.grey.shade600, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 36),

                      // 💎 PREMIUM TAB BAR (Dribbble Glass Style)
                      Container(
                        height: 54,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(color: _isDarkMode ? Colors.blueGrey.shade700 : Colors.white, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isDarkMode ? 0.25 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: LinearGradient(
                              colors: _isDarkMode ? [mintGreen, const Color(0xFF059669)] : [electricBlue, navyPrimary],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isDarkMode ? mintGreen : electricBlue).withValues(alpha: 0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          labelColor: Colors.white,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          unselectedLabelColor: _isDarkMode ? Colors.blueGrey.shade300 : Colors.grey.shade600,
                          tabs: const [
                            Tab(text: 'Sign In'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // CONTAINER TAB BAR VIEW
                      SizedBox(
                        height: 420, 
                        child: TabBarView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildLoginForm(cardColor, textColor, inputFillColor),
                            _buildRegisterForm(cardColor, textColor, inputFillColor),
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
    );
  }

  // ==========================================
  // FORM SIGN IN
  // ==========================================
  Widget _buildLoginForm(Color bgCard, Color txtColor, Color fillIn) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _isDarkMode ? Colors.blueGrey.shade700 : Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.04), 
            blurRadius: 20, 
            offset: const Offset(0, 12)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome Back', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: txtColor, letterSpacing: -0.5)),
          const SizedBox(height: 4),
          Text('Enter your credentials to continue tracking.', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          const SizedBox(height: 24),
          
          _customTextField(controller: _loginUserCtrl, label: 'Username', icon: Icons.person_outline_rounded, fillIn: fillIn, obscure: false),
          const SizedBox(height: 16),
          _customTextField(controller: _loginPassCtrl, label: 'Password', icon: Icons.lock_open_rounded, fillIn: fillIn, obscure: true),
          
          const Spacer(),
          
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: _isDarkMode ? [mintGreen, const Color(0xFF059669)] : [electricBlue, navyPrimary],
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isDarkMode ? mintGreen : electricBlue).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                String username = _loginUserCtrl.text.trim();
                if (username.isEmpty || _loginPassCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all fields!'), backgroundColor: Colors.redAccent));
                  return;
                }
                await PrefsHelper.setUserName(username);
                if (mounted) {
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                }
              },
              child: const Text('Sign In to Workspace', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // FORM SIGN UP
  // ==========================================
  Widget _buildRegisterForm(Color bgCard, Color txtColor, Color fillIn) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: bgCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: _isDarkMode ? Colors.blueGrey.shade700 : Colors.white, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isDarkMode ? 0.3 : 0.04), 
            blurRadius: 20, 
            offset: const Offset(0, 12)
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Create Crew Account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: txtColor, letterSpacing: -0.5)),
          const SizedBox(height: 16),
          
          _customTextField(controller: _regNameCtrl, label: 'Full Name', icon: Icons.badge_outlined, fillIn: fillIn, obscure: false),
          const SizedBox(height: 14),
          _customTextField(controller: _regUserCtrl, label: 'Username', icon: Icons.alternate_email_rounded, fillIn: fillIn, obscure: false),
          const SizedBox(height: 14),
          
          DropdownButtonFormField<String>(
            initialValue: _selectedRole, // FIX: Mengganti 'value' yang deprecated menjadi 'initialValue'
            dropdownColor: bgCard,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey.shade500),
            decoration: InputDecoration(
              labelText: 'Structural Role',
              labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
              prefixIcon: Icon(Icons.assignment_ind_outlined, color: _isDarkMode ? mintGreen : navyPrimary, size: 20),
              filled: true,
              fillColor: fillIn,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            style: TextStyle(color: txtColor, fontWeight: FontWeight.w600, fontSize: 14),
            items: const [
              DropdownMenuItem(value: 'Ketuplak', child: Text('Ketuplak (Leader)')),
              DropdownMenuItem(value: 'Anggota', child: Text('Crew Member')),
            ],
            onChanged: (value) => setState(() => _selectedRole = value!),
          ),
          const Spacer(),
          
          Container(
            width: double.infinity,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF059669)], 
              ),
              boxShadow: [
                BoxShadow(
                  color: mintGreen.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () async {
                String name = _regNameCtrl.text.trim();
                if (name.isEmpty || _regUserCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please complete the form!'), backgroundColor: Colors.redAccent));
                  return;
                }
                await PrefsHelper.setUserName(name);
                await PrefsHelper.setUserRole(_selectedRole);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome aboard, $name!'), backgroundColor: mintGreen));
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                }
              },
              child: const Text('Get Started Free', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // REUSABLE FIELD COMPONENT
  // ==========================================
  Widget _customTextField({
    required TextEditingController controller, 
    required String label, 
    required IconData icon, 
    required Color fillIn, 
    required bool obscure
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: _isDarkMode ? Colors.white : navyDark),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500),
        prefixIcon: Icon(icon, color: _isDarkMode ? mintGreen : navyPrimary, size: 20),
        filled: true,
        fillColor: fillIn,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _isDarkMode ? Colors.transparent : Colors.grey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _isDarkMode ? mintGreen : electricBlue, width: 1.5),
        ),
      ),
    );
  }
}