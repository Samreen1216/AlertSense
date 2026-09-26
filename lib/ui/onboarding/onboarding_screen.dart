import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isMicGranted = false;
  bool _isNotificationGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final micStatus = await Permission.microphone.status;
    final notifStatus = await Permission.notification.status;
    if (mounted) {
      setState(() {
        _isMicGranted = micStatus.isGranted;
        _isNotificationGranted = notifStatus.isGranted;
      });
    }
  }

  Future<void> _requestMicPermission() async {
    final status = await Permission.microphone.request();
    if (mounted) {
      setState(() {
        _isMicGranted = status.isGranted;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() {
        _isNotificationGranted = status.isGranted;
      });
    }
  }

  Future<void> _onNextPage() async {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // If microphone is not yet granted, request it so core sound detection works
      if (!_isMicGranted) {
        await _requestMicPermission();
      }
      if (mounted) {
        context.go('/home');
      }
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
              if (index == 2) {
                _checkPermissions();
              }
            },
            children: [
              const _OnboardingPage(
                icon: Icons.hearing,
                title: 'Sounds You Can See',
                description:
                    'AlertSense continuously listens for important sounds in your environment and converts them into visual notifications you can easily see.',
                gradientColors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
              ),
              const _OnboardingPage(
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
                gradientColors: const [Color(0xFF3949AB), Color(0xFF283593)],
                isFinalPage: true,
                isMicGranted: _isMicGranted,
                isNotificationGranted: _isNotificationGranted,
                onRequestMic: _requestMicPermission,
                onRequestNotification: _requestNotificationPermission,
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
                            : Colors.white.withValues(alpha: 0.5),
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
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
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
  final bool isMicGranted;
  final bool isNotificationGranted;
  final VoidCallback? onRequestMic;
  final VoidCallback? onRequestNotification;

  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradientColors,
    this.isFinalPage = false,
    this.isMicGranted = false,
    this.isNotificationGranted = false,
    this.onRequestMic,
    this.onRequestNotification,
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
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 110,
            color: Colors.white,
          ),
          const SizedBox(height: 36),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.4,
            ),
          ),
          if (isFinalPage) ...[
            const SizedBox(height: 32),
            _buildPermissionRow(
              icon: Icons.mic_rounded,
              title: 'Microphone',
              description: 'Required to detect sounds & alerts',
              isGranted: isMicGranted,
              onTap: onRequestMic,
            ),
            const SizedBox(height: 12),
            _buildPermissionRow(
              icon: Icons.notifications_active_rounded,
              title: 'Notifications',
              description: 'Required for emergency alerts',
              isGranted: isNotificationGranted,
              onTap: onRequestNotification,
            ),
          ],
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isGranted
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isGranted
                  ? const Color(0xFF00FF41).withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.2),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isGranted
                      ? const Color(0xFF00FF41).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isGranted ? const Color(0xFF00FF41) : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              if (isGranted)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Granted',
                      style: TextStyle(
                        color: Color(0xFF00FF41),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF00FF41),
                      size: 20,
                    ),
                  ],
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Grant',
                    style: TextStyle(
                      color: Color(0xFF283593),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
