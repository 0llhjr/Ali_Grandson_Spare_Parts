// ============================================================
// banner_carousel.dart — Auto-Scrolling Promotional Banner
// ============================================================
// Displays a horizontally swipeable carousel of promotional
// banner images at the top of the user dashboard.
//
// Key behaviours:
//   • Automatically advances to the next banner every 5 seconds
//     using a repeating Timer.
//   • The user can also swipe left/right manually.
//   • Small dot indicators below the images show which banner
//     is currently visible. The active dot stretches wider.
//   • The Timer is cancelled in dispose() to prevent memory leaks.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:alis_grandson_app/src/core/theme/app_colors.dart';

/// A self-contained, auto-playing image carousel widget.
class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  // PageController drives the horizontal page-swipe animation.
  final PageController _pageController = PageController();

  // Index of the currently visible banner (0-based).
  int _currentPage = 0;

  // The timer that automatically advances the carousel.
  late Timer _timer;

  // Paths to the banner images bundled with the app.
  final List<String> _banners = [
    'lib/assets/Banner_Imgs/banner1.png',
    'lib/assets/Banner_Imgs/banner2.png',
    'lib/assets/Banner_Imgs/banner3.png',
  ];

  @override
  void initState() {
    super.initState();

    // Set up a repeating timer that fires every 5 seconds.
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      // Move to the next banner, or loop back to the first.
      if (_currentPage < _banners.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      // Animate the page view to the new index with a smooth cubic curve.
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    // Always cancel the timer when the widget is removed to avoid memory leaks.
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Banner images (16:7.5 aspect ratio) ──────────────
        AspectRatio(
          aspectRatio: 16 / 7.5,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            // When the user swipes manually, update the dot indicator.
            onPageChanged: (int index) =>
                setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(_banners[index], fit: BoxFit.cover),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        // ── Dot indicators ────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => _buildIndicator(index),
          ),
        ),
      ],
    );
  }

  /// Builds a single animated dot indicator.
  /// The active dot is wider (24 px) and maroon-coloured;
  /// inactive dots are narrow (8 px) and grey.
  Widget _buildIndicator(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 4,
      width: isActive ? 24 : 8, // Active dot stretches to show position
      decoration: BoxDecoration(
        color: isActive ? kPrimaryColor : kGreyMedium,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
