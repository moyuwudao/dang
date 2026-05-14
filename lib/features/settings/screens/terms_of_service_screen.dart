import 'package:flutter/material.dart';
import '../../../l10n/generated/app_localizations.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.termsOfService),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
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
              title: '1. Acceptance of Terms',
              content:
                  '''By downloading, installing, or using Changji ("the App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.''',
            ),
            _buildSection(
              context,
              title: '2. Description of Service',
              content:
                  '''Changji is an AI-powered voice notes application designed for one-person companies. The App provides:

• Voice recording and storage
• AI-powered transcription using OpenAI's Whisper API
• OCR text recognition from images
• Local data storage and management

You must provide your own OpenAI API key to use the transcription features.''',
            ),
            _buildSection(
              context,
              title: '3. User Responsibilities',
              content: '''You agree to:

• Provide accurate information when setting up the App
• Maintain the security of your API key
• Use the App in compliance with all applicable laws
• Not use the App for any illegal or unauthorized purpose
• Not attempt to gain unauthorized access to the App or its related systems

You are solely responsible for:
• Your OpenAI API usage and associated costs
• The content you record, transcribe, or store
• Compliance with OpenAI's terms of service''',
            ),
            _buildSection(
              context,
              title: '4. API Key and Third-Party Services',
              content:
                  '''The App requires you to provide your own OpenAI API key. By using this feature:

• You understand that API calls are made directly to OpenAI's servers
• You are responsible for all costs associated with your API usage
• Your API key is stored locally on your device and is never transmitted to our servers
• You agree to comply with OpenAI's terms of service and usage policies''',
            ),
            _buildSection(
              context,
              title: '5. Intellectual Property',
              content:
                  '''The App and its original content, features, and functionality are owned by Changji and are protected by international copyright, trademark, patent, trade secret, and other intellectual property laws.

You retain all rights to the content you create using the App.''',
            ),
            _buildSection(
              context,
              title: '6. Limitation of Liability',
              content:
                  '''To the maximum extent permitted by law, Changji shall not be liable for:

• Any indirect, incidental, special, consequential, or punitive damages
• Loss of profits, data, or goodwill
• Service interruptions or data loss
• Accuracy of AI-generated transcriptions
• Any damages arising from your use of third-party services (including OpenAI)

The App is provided "as is" without warranties of any kind.''',
            ),
            _buildSection(
              context,
              title: '7. Termination',
              content:
                  '''We may terminate or suspend your access to the App immediately, without prior notice or liability, for any reason, including if you breach these Terms.

Upon termination, your right to use the App will immediately cease. All provisions of the Terms which by their nature should survive termination shall survive.''',
            ),
            _buildSection(
              context,
              title: '8. Changes to Terms',
              content:
                  '''We reserve the right to modify or replace these Terms at any time. We will provide notice of any changes by posting the new Terms on this page and updating the "Last updated" date.

Your continued use of the App after any changes constitutes acceptance of the new Terms.''',
            ),
            _buildSection(
              context,
              title: '9. Governing Law',
              content:
                  '''These Terms shall be governed by and construed in accordance with the laws of the jurisdiction in which you reside, without regard to its conflict of law provisions.''',
            ),
            _buildSection(
              context,
              title: '10. Contact Us',
              content:
                  '''If you have any questions about these Terms, please contact us at:

Email: support@changji.app''',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
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
