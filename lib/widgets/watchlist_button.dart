import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../models/video_models.dart';
import '../services/watchlist_service.dart';
import '../services/auth_service.dart';

class WatchlistButton extends StatefulWidget {
  final Video video;
  final double size;
  final Color? color;
  final VoidCallback? onToggle;

  const WatchlistButton({
    Key? key,
    required this.video,
    this.size = 24,
    this.color,
    this.onToggle,
  }) : super(key: key);

  @override
  State<WatchlistButton> createState() => _WatchlistButtonState();
}

class _WatchlistButtonState extends State<WatchlistButton>
    with SingleTickerProviderStateMixin {
  bool _isInWatchlist = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _checkWatchlistStatus();
  }

  Future<void> _checkWatchlistStatus() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    
    final isInWatchlist = await WatchlistService.isInWatchlist(user.uid, widget.video);
    if (mounted) {
      setState(() {
        _isInWatchlist = isInWatchlist;
      });
    }
  }

  Future<void> _toggleWatchlist() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Animation
    _animationController.forward().then((_) {
      _animationController.reverse();
    });

    bool success = false;
    final user = AuthService().currentUser;
    if (user == null) return;
    
    if (_isInWatchlist) {
      success = await WatchlistService.removeFromWatchlist(user.uid, widget.video);
      if (success && mounted) {
        setState(() {
          _isInWatchlist = false;
        });
        _showSnackBar('Removed from watchlist', Icons.bookmark_border);
      }
    } else {
      success = await WatchlistService.addToWatchlist(widget.video);
      if (success && mounted) {
        setState(() {
          _isInWatchlist = true;
        });
        _showSnackBar('Added to watchlist', Icons.bookmark);
      }
    }

    if (!success && mounted) {
      _showSnackBar('Failed to update watchlist', Icons.error_outline);
    }

    setState(() {
      _isLoading = false;
    });

    // Call callback if provided
    widget.onToggle?.call();
  }

  void _showSnackBar(String message, IconData icon) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: AppColors.primaryAccent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isLoading ? null : _toggleWatchlist,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: _isLoading
                    ? SizedBox(
                        width: widget.size,
                        height: widget.size,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            widget.color ?? AppColors.primaryAccent,
                          ),
                        ),
                      )
                    : Icon(
                        _isInWatchlist ? Icons.bookmark : Icons.bookmark_border,
                        size: widget.size,
                        color: _isInWatchlist
                            ? AppColors.primaryAccent
                            : (widget.color ?? AppColors.textSecondary),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
