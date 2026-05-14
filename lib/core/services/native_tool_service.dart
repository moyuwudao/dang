import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:add_2_calendar/add_2_calendar.dart';

class NativeToolService {
  static Future<void> sendEmail({
    required String subject,
    required String body,
    List<String>? recipients,
  }) async {
    final uri = Uri(
      scheme: 'mailto',
      path: recipients?.join(','),
      query:
          'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> shareText(String text, {String? subject}) async {
    await Share.share(text, subject: subject);
  }

  static Future<void> copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
  }

  static Future<void> addToCalendar({
    required String title,
    required DateTime startTime,
    DateTime? endTime,
    String? description,
    bool isAllDay = false,
  }) async {
    final event = Event(
      title: title,
      description: description,
      startDate: startTime,
      endDate: endTime ?? startTime.add(const Duration(hours: 1)),
      allDay: isAllDay,
    );
    await Add2Calendar.addEvent2Cal(event);
  }

  static Future<void> openAnkiImport() async {
    final uri = Uri.parse('ankidroid://');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static Future<void> openMap(String query) async {
    final uri = Uri.parse('geo:0,0?q=${Uri.encodeComponent(query)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> makePhoneCall(String phoneNumber) async {
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
