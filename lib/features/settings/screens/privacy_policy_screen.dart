import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.privacyPolicy),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Last updated: May 1, 2026',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              context,
              title: '1. Information We Collect',
              content: '''Changji is designed with privacy in mind. We collect minimal data:

• Voice recordings: Stored locally on your device
• Text content: Stored locally on your device
• API Key: Your OpenAI API key is stored locally and never transmitted to our servers
• Usage data: No analytics or usage data is collected''',
            ),
            _buildSection(
              context,
              title: '2. How We Use Your Information',
              content: '''Your data is used solely for:

• Transcribing voice recordings using your own OpenAI API key
• Storing notes and recordings locally on your device
• Providing the core functionality of the app

We do not:
• Collect or store your data on our servers
• Share your data with third parties
• Use your data for advertising purposes''',
            ),
            _buildSection(
              context,
              title: '3. Data Storage',
              content: '''All your data is stored locally on your device using SQLite database. This includes:

• Voice recordings
• Transcribed text
• OCR results
• App settings

Your data never leaves your device unless you explicitly share it.''',
            ),
            _buildSection(
              context,
              title: '4. Third-Party Services',
              content: '''Changji uses the following third-party services:

• OpenAI API: Used for voice transcription. Your API key is required, and all API calls are made directly from your device to OpenAI servers.
• Google ML Kit: Used for OCR text recognition. Processing is done on-device.

We are not responsible for the privacy practices of these third-party services.''',
            ),
            _buildSection(
              context,
              title: '5. Data Security',
              content: '''We implement appropriate security measures to protect your data:

• Local storage encryption
• Secure API key storage
• No network transmission of your data (except to OpenAI API)

However, no method of transmission or storage is 100% secure.''',
            ),
            _buildSection(
              context,
              title: '6. Your Rights',
              content: '''You have the right to:

• Access your data (all data is stored locally on your device)
• Delete your data (use the "Clear All Data" option in Settings)
• Export your data (feature coming soon)
• Control your API key (update or remove at any time)''',
            ),
            _buildSection(
              context,
              title: '7. Changes to This Policy',
              content: '''We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.''',
            ),
            _buildSection(
              context,
              title: '8. Contact Us',
              content: '''If you have any questions about this Privacy Policy, please contact us at:

Email: support@changji.app''',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                ),
          ),
        ],
      ),
    );
  }
}
