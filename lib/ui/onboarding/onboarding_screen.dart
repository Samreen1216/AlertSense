import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            children: const [
              _OnboardingPage(
                icon: Icons.hearing,
                title: 'Sounds You Can See',
                description:
                    'AlertSense continuously listens for important sounds in your environment and converts them into visual notifications you can easily see.',
                gradientColors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              ),
              _OnboardingPage(
                icon: Icons.vibration,
                title: 'Alerts You Can Feel',
                description:
                    'Customizable vibration patterns ensure you never miss a critical alert, even when your phone is in your pocket.',
                gradientColors: [Color(0xFF00897B), Color(0xFF00695C)],
              ),
              _OnboardingPage(
                icon: Icons.security,
                title: 'Let\'s Set Up',
                description:
                    'To get started, we need permission to use your microphone to detect sounds and send notifications.',
                gradientColors: [Color(0xFF3949AB), Color(0xFF283593)],
                isFinalPage: true,
              ),
            ],
          ),
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: () => context.go('/home'),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 10,
                      width: _currentPage == index ? 24 : 10,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                if (_currentPage == 2)
                  ElevatedButton(
                    onPressed: _onNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF283593),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: _onNextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

class _OnboardingPage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradientColors;
  final bool isFinalPage;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
    this.isFinalPage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 128,
            color: Colors.white,
          ),
          const SizedBox(height: 48),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          if (isFinalPage) ...[
            const SizedBox(height: 40),
            _buildPermissionRow(Icons.mic, 'Microphone'),
            const SizedBox(height: 16),
            _buildPermissionRow(Icons.notifications, 'Notifications'),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPermissionRow(IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.greenAccent),
        ],
      ),
    );
  }
}
