import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_colors.dart';

class WisdomScreen extends StatefulWidget {
  const WisdomScreen({Key? key}) : super(key: key);

  @override
  State<WisdomScreen> createState() => _WisdomScreenState();
}

class _WisdomScreenState extends State<WisdomScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  List<QAItem> _questions = [];
  List<QAItem> _filteredQuestions = [];
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _questions = _getQuestions();
    _filteredQuestions = _questions;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Start animation after widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Wisdom',
                    style: GoogleFonts.teko(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Questions & Spiritual Guidance',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: _filterQuestions,
                    style: GoogleFonts.lato(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search wisdom...',
                      hintStyle: GoogleFonts.lato(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Questions List
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  // Clamp the opacity value to ensure it's within valid range
                  final opacity = _fadeController.value.clamp(0.0, 1.0);

                  return Opacity(
                    opacity: opacity,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredQuestions.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: QuestionCard(
                            question: _filteredQuestions[index],
                            animationDelay: index * 100,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _filterQuestions(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredQuestions = _questions;
      } else {
        _filteredQuestions = _questions.where((question) {
          return question.question.toLowerCase().contains(query.toLowerCase()) ||
              question.answer.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  List<QAItem> _getQuestions() {
    return [
      QAItem(
        question: 'How can I maintain inner peace in daily life?',
        answer: 'Inner peace is cultivated through consistent practice of mindfulness and acceptance. Start each day with meditation, even if just for 10 minutes. Throughout the day, return to your breath whenever you feel disturbed. Remember that peace is your natural state - you don\'t create it, you simply remove the obstacles that hide it.',
        category: 'Daily Practice',
      ),
      QAItem(
        question: 'What is the difference between the mind and consciousness?',
        answer: 'The mind is like waves on the ocean of consciousness. Consciousness is the unchanging awareness in which all thoughts, emotions, and experiences arise and dissolve. The mind is the instrument through which consciousness experiences the world, but it is not consciousness itself. Through meditation, we learn to identify with consciousness rather than the temporary movements of mind.',
        category: 'Philosophy',
      ),
      QAItem(
        question: 'How do I deal with negative thoughts during meditation?',
        answer: 'Negative thoughts are not your enemy - they are clouds passing through the sky of awareness. When they arise, simply observe them without judgment or resistance. Don\'t try to push them away or engage with their content. Instead, gently return your attention to your chosen focus - breath, mantra, or present moment awareness. With practice, you\'ll develop the skill of witnessing thoughts without being disturbed by them.',
        category: 'Meditation',
      ),
      QAItem(
        question: 'What is the purpose of suffering in spiritual growth?',
        answer: 'Suffering is often the catalyst that awakens us to seek deeper truth. It shows us the limitations of seeking happiness in external things and pushes us toward inner exploration. However, suffering itself is not the goal - awakening is. Once you understand that suffering comes from attachment and identification with the temporary, you can use this understanding to transcend suffering and discover the peace that is your true nature.',
        category: 'Philosophy',
      ),
      QAItem(
        question: 'How can I develop unconditional love?',
        answer: 'Unconditional love begins with self-acceptance. You cannot give what you don\'t have. Start by observing your judgments - of yourself and others - and questioning their validity. Practice seeing beyond the surface personality to the divine essence in everyone. Remember that love is not an emotion but your very nature. When you remove the barriers of fear, judgment, and expectation, love flows naturally.',
        category: 'Love & Compassion',
      ),
      QAItem(
        question: 'Is it normal to feel resistance to spiritual practice?',
        answer: 'Yes, resistance is completely normal and actually indicates that transformation is beginning. The ego-mind resists change because it fears dissolution. This resistance often manifests as doubt, laziness, or finding excuses to avoid practice. Acknowledge the resistance with compassion, but don\'t let it stop you. Start with small, consistent steps. Even five minutes of sincere practice is better than an hour of forced effort.',
        category: 'Daily Practice',
      ),
      QAItem(
        question: 'How do I know if I\'m making progress in meditation?',
        answer: 'True progress in meditation is often subtle and gradual. Look for these signs: increased equanimity in daily situations, less reactivity to external circumstances, moments of inner stillness, improved emotional regulation, and a growing sense of peace that doesn\'t depend on external conditions. Remember, seeking dramatic experiences can become another form of attachment. The deepest progress often feels like simply becoming more natural and authentic.',
        category: 'Meditation',
      ),
      QAItem(
        question: 'What is the role of a spiritual teacher or guru?',
        answer: 'A true teacher is like a mirror, reflecting back your own divine nature. They don\'t give you something you don\'t already have - they help you recognize what you\'ve temporarily forgotten. A genuine teacher points you toward your own inner wisdom rather than creating dependency. They exemplify the possibility of awakening and provide guidance, but the actual journey must be walked by you. Trust your inner discernment when choosing a teacher.',
        category: 'Spiritual Guidance',
      ),
      QAItem(
        question: 'How can I maintain spiritual practice while living in the world?',
        answer: 'Spirituality is not about escaping the world but bringing consciousness to every moment within it. Transform daily activities into spiritual practice: eat mindfully, work with presence, listen deeply to others, and find the sacred in the ordinary. Your job, relationships, and responsibilities can all become vehicles for awakening when approached with awareness and love. The world becomes your temple when you see it with awakened eyes.',
        category: 'Daily Practice',
      ),
      QAItem(
        question: 'What is the significance of silence in spiritual practice?',
        answer: 'Silence is the womb of wisdom. In outer silence, you can hear the subtle voice of inner guidance. In inner silence - the space between thoughts - you discover your true nature. Silence is not emptiness but fullness - the fullness of pure being. Regular periods of silence, whether in formal meditation or simply sitting quietly in nature, allow the mind to settle and reveal the peace that is always present beneath the mental noise.',
        category: 'Meditation',
      ),
    ];
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

class QAItem {
  final String question;
  final String answer;
  final String category;

  QAItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class QuestionCard extends StatefulWidget {
  final QAItem question;
  final int animationDelay;

  const QuestionCard({
    Key? key,
    required this.question,
    this.animationDelay = 0,
  }) : super(key: key);

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _expansionController;
  late AnimationController _entranceController;
  late Animation<double> _expandAnimation;
  late Animation<double> _entranceAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _expansionController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expansionController,
      curve: Curves.easeInOut,
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(_entranceAnimation);

    // Start entrance animation with delay and proper bounds checking
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) {
        _entranceController.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceAnimation,
      builder: (context, child) {
        // Ensure opacity is always within valid range
        final opacity = _entranceAnimation.value.clamp(0.0, 1.0);
        final slideOffset = _slideAnimation.value.clamp(0.0, 50.0);

        return Transform.translate(
          offset: Offset(0, slideOffset),
          child: Opacity(
            opacity: opacity,
            child: GestureDetector(
              onTap: _toggleExpansion,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isExpanded
                        ? AppColors.primaryAccent.withOpacity(0.3)
                        : Colors.transparent,
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Question Section
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryAccent.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    widget.question.category,
                                    style: GoogleFonts.lato(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primaryAccent,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Question Text
                                Text(
                                  widget.question.question,
                                  style: GoogleFonts.rajdhani(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Expand Icon
                          AnimatedRotation(
                            turns: _isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryAccent.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down,
                                color: AppColors.primaryAccent,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Answer Section (Expandable)
                    AnimatedBuilder(
                      animation: _expandAnimation,
                      builder: (context, child) {
                        // Clamp the height factor to ensure it's within valid range
                        final heightFactor = _expandAnimation.value.clamp(0.0, 1.0);

                        return ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: heightFactor,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primaryBackground.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.secondaryAccent.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Icon(
                                            Icons.lightbulb,
                                            color: AppColors.secondaryAccent,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Guidance',
                                          style: GoogleFonts.lato(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.secondaryAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      widget.question.answer,
                                      style: GoogleFonts.lato(
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _toggleExpansion() {
    if (!mounted) return;

    HapticFeedback.lightImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expansionController.forward();
    } else {
      _expansionController.reverse();
    }
  }

  @override
  void dispose() {
    _expansionController.dispose();
    _entranceController.dispose();
    super.dispose();
  }
}