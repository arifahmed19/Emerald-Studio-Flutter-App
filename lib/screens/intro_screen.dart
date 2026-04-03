import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';
import 'home_screen.dart';
import 'auth_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class IntroScreen extends StatefulWidget {
  final bool isFromAbout;
  const IntroScreen({super.key, this.isFromAbout = false});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Perfect Passport Photos',
      'description': 'Instantly create biometric passport photos matching international standards. No more rejections at the embassy.',
      'icon': Icons.face_retouching_natural,
      'color': const Color(0xFFB0E4CC),
    },
    {
      'title': 'Auto Background',
      'description': 'Our advanced tool automatically removes any background and replaces it with pure white.',
      'icon': Icons.layers_clear,
      'color': const Color(0xFF81D4FA),
    },
    {
      'title': 'Ready to Print',
      'description': 'Export high-quality 4x6 matrix templates directly to your local printer or save as PDF.',
      'icon': Icons.print,
      'color': const Color(0xFFE1BEE7),
    },
  ];

  void _completeIntro() async {
    if (widget.isFromAbout) {
      Navigator.of(context).pop();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenIntro', true);
    
    if (!mounted) return;
    
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Dynamic Background pattern/glow
          AnimatedPositioned(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            top: _currentPage == 1 ? -50 : -100,
            right: _currentPage == 2 ? 100 : -100,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeInOut,
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _pages[_currentPage]['color'].withOpacity(0.05),
                boxShadow: [
                  BoxShadow(
                    color: _pages[_currentPage]['color'].withOpacity(0.1), 
                    blurRadius: 100, 
                    spreadRadius: 50
                  )
                ]
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _completeIntro,
                    child: Text(
                      widget.isFromAbout ? 'Close' : 'Skip',
                      style: GoogleFonts.outfit(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _pages[index]['color'].withOpacity(0.1),
                                border: Border.all(
                                  color: _pages[index]['color'].withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _pages[index]['icon'],
                                size: 100,
                                color: _pages[index]['color'],
                              ),
                            ),
                            const SizedBox(height: 60),
                            Text(
                              _pages[index]['title'],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _pages[index]['description'],
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _pages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? _pages[_currentPage]['color']
                                  : Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (_currentPage == _pages.length - 1) {
                            _completeIntro();
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: _pages[_currentPage]['color'],
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _pages[_currentPage]['color'].withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage == _pages.length - 1 
                                    ? (widget.isFromAbout ? 'Done' : 'Get Started') 
                                    : 'Next',
                                style: GoogleFonts.outfit(
                                  color: AppTheme.backgroundColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (_currentPage != _pages.length - 1) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, color: AppTheme.backgroundColor, size: 20),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
