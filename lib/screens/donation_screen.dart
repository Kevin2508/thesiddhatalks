import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_colors.dart';

class DonationScreen extends StatelessWidget {
  const DonationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Support Our Mission',
          style: GoogleFonts.rajdhani(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primaryAccent.withOpacity(0.1),
                    AppColors.primaryAccent.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.primaryAccent.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.favorite,
                    color: AppColors.primaryAccent,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Help Us Spread Wisdom',
                    style: GoogleFonts.rajdhani(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your generous donations help us continue our mission of sharing spiritual wisdom and creating valuable content for seekers worldwide.',
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Mission Section
            Text(
              'Our Mission',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildMissionItem(
                    Icons.video_library,
                    'Create Quality Content',
                    'Producing high-quality spiritual videos and educational content',
                  ),
                  const SizedBox(height: 16),
                  _buildMissionItem(
                    Icons.school,
                    'Share Ancient Wisdom',
                    'Making timeless spiritual teachings accessible to everyone',
                  ),
                  const SizedBox(height: 16),
                  _buildMissionItem(
                    Icons.group,
                    'Build Community',
                    'Creating a supportive community of spiritual seekers',
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Donation Methods
            Text(
              'Ways to Donate',
              style: GoogleFonts.rajdhani(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Domestic Bank Transfer
            _buildDonationMethod(
              'Domestic Donations',
              'Bank transfer within India',
              Icons.account_balance,
              Colors.green[700]!,
              () => _showDomesticBankDetails(context),
            ),
            
            const SizedBox(height: 12),
            
            // International Donations
            _buildDonationMethod(
              'International Donations',
              'Wire transfer from international banks',
              Icons.public,
              Colors.blue[700]!,
              () => _showInternationalBankDetails(context),
            ),
            
            const SizedBox(height: 32),
            
            // Contact Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primaryAccent.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    color: AppColors.primaryAccent,
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Need Help?',
                    style: GoogleFonts.rajdhani(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'For any questions about donations or our mission, feel free to contact us.',
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _contactSupport(context),
                    icon: const Icon(Icons.phone, size: 18),
                    label: Text(
                      'Contact: +91 78288 44872',
                      style: GoogleFonts.lato(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.primaryAccent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.lato(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDonationMethod(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.lato(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.lato(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showDomesticBankDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Domestic Donations',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Transfer Details (India)',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryAccent,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              _buildBankDetail('Bank Name', 'Punjab National Bank'),
              _buildBankDetail('Branch', 'Nagpur Road, Jabalpur'),
              _buildBankDetail('Branch Address', 'Nagpur Road, Jabalpur, Madhya Pradesh, India'),
              _buildBankDetail('Account Holder Name', 'Ashok Kumar Dumbe'),
              _buildBankDetail('Account Number', '0038000100125275'),
              _buildBankDetail('IFSC Code', 'PUNB0070800'),
              _buildBankDetail('MICR Code', '482024006'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.lato(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showInternationalBankDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'International Donations',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              
              Text(
                'Beneficiary Details:',
                style: GoogleFonts.lato(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryAccent,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _buildBankDetail('Bank Name', 'Punjab National Bank'),
              _buildBankDetail('Branch', 'Nagpur Road, Jabalpur'),
              _buildBankDetail('Branch Address', 'Nagpur Road, Jabalpur, Madhya Pradesh, India'),
              _buildBankDetail('Account Holder Name', 'Ashok Kumar Dumbe'),
              _buildBankDetail('Account Number', '0038000100125275'),
              _buildBankDetail('SWIFT Code', 'PUNBINBBJPB'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.lato(color: AppColors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBankDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: GoogleFonts.lato(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.lato(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _contactSupport(BuildContext context) async {
    const phoneNumber = 'tel:+917828844872';
    try {
      await launchUrl(Uri.parse(phoneNumber));
    } catch (e) {
      // Fallback to show the number in a dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.cardBackground,
            title: Text(
              'Contact Information',
              style: GoogleFonts.rajdhani(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'For any clarifications, please contact:',
                  style: GoogleFonts.lato(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '+91 78288 44872',
                  style: GoogleFonts.lato(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: GoogleFonts.lato(color: AppColors.primaryAccent),
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}
