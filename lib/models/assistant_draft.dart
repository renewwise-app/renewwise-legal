import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_priority.dart';

/// User-facing category chip mapped to [RenewalCategory].
class AssistantCategoryOption {
  const AssistantCategoryOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.category,
    this.customEventType,
  });

  final String id;
  final String label;
  final IconData icon;
  final RenewalCategory category;
  final String? customEventType;

  String get displayLabel => customEventType ?? label;
}

abstract final class AssistantCategories {
  static const all = [
    AssistantCategoryOption(
      id: 'passport',
      label: 'Passport',
      icon: Icons.flight_outlined,
      category: RenewalCategory.passport,
    ),
    AssistantCategoryOption(
      id: 'driving_licence',
      label: 'Driving Licence',
      icon: Icons.badge_outlined,
      category: RenewalCategory.drivingLicence,
    ),
    AssistantCategoryOption(
      id: 'insurance',
      label: 'Insurance',
      icon: Icons.shield_outlined,
      category: RenewalCategory.insurance,
    ),
    AssistantCategoryOption(
      id: 'vehicle',
      label: 'Vehicle',
      icon: Icons.directions_car_outlined,
      category: RenewalCategory.vehicle,
    ),
    AssistantCategoryOption(
      id: 'medical',
      label: 'Medical',
      icon: Icons.medical_services_outlined,
      category: RenewalCategory.other,
      customEventType: 'Medical',
    ),
    AssistantCategoryOption(
      id: 'emi',
      label: 'EMI',
      icon: Icons.account_balance_outlined,
      category: RenewalCategory.loanEmi,
    ),
    AssistantCategoryOption(
      id: 'subscription',
      label: 'Subscription',
      icon: Icons.subscriptions_outlined,
      category: RenewalCategory.subscription,
    ),
    AssistantCategoryOption(
      id: 'shopping',
      label: 'Shopping',
      icon: Icons.shopping_bag_outlined,
      category: RenewalCategory.other,
      customEventType: 'Shopping',
    ),
    AssistantCategoryOption(
      id: 'birthday',
      label: 'Birthday',
      icon: Icons.cake_outlined,
      category: RenewalCategory.other,
      customEventType: 'Birthday',
    ),
    AssistantCategoryOption(
      id: 'anniversary',
      label: 'Anniversary',
      icon: Icons.favorite_outline,
      category: RenewalCategory.other,
      customEventType: 'Anniversary',
    ),
    AssistantCategoryOption(
      id: 'other',
      label: 'Other',
      icon: Icons.category_outlined,
      category: RenewalCategory.other,
    ),
  ];

  static AssistantCategoryOption? byId(String? id) {
    if (id == null) return null;
    try {
      return all.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<AssistantCategoryOption> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((c) => c.label.toLowerCase().contains(q))
        .toList(growable: false);
  }

  static AssistantCategoryOption custom(String name) {
    return AssistantCategoryOption(
      id: 'custom_${name.hashCode}',
      label: name,
      icon: Icons.label_outline,
      category: RenewalCategory.other,
      customEventType: name,
    );
  }
}

enum AssistantStep {
  welcome,
  question1,
  question2,
  question3,
  question4,
  question5,
  review,
  success,
}

class AssistantAttachment {
  const AssistantAttachment({
    required this.id,
    required this.path,
    required this.name,
    this.isImage = true,
  });

  final String id;
  final String path;
  final String name;
  final bool isImage;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'isImage': isImage,
      };

  factory AssistantAttachment.fromJson(Map<String, dynamic> json) =>
      AssistantAttachment(
        id: json['id'] as String,
        path: json['path'] as String,
        name: json['name'] as String,
        isImage: json['isImage'] as bool? ?? true,
      );
}

/// In-progress conversational event data (SharedPreferences only).
class AssistantDraft {
  const AssistantDraft({
    this.step = AssistantStep.welcome,
    this.title = '',
    this.categoryId,
    this.customCategoryName,
    this.renewalDate,
    this.amount,
    this.priority = RenewalPriority.medium,
    this.reminderSchedule = const [30, 7, 1],
    this.customReminderDates = const [],
    this.reminderTimeMinutes = 540,
    this.customizeReminders = false,
    this.attachments = const [],
    this.notes = '',
    this.tags = const [],
    this.updatedAt,
  });

  final AssistantStep step;
  final String title;
  final String? categoryId;
  final String? customCategoryName;
  final DateTime? renewalDate;
  final double? amount;
  final RenewalPriority priority;
  final List<int> reminderSchedule;
  final List<DateTime> customReminderDates;
  final int reminderTimeMinutes;
  final bool customizeReminders;
  final List<AssistantAttachment> attachments;
  final String notes;
  final List<String> tags;
  final DateTime? updatedAt;

  AssistantCategoryOption? get categoryOption {
    if (customCategoryName != null && customCategoryName!.trim().isNotEmpty) {
      return AssistantCategories.custom(customCategoryName!.trim());
    }
    return AssistantCategories.byId(categoryId);
  }

  bool get hasContent =>
      title.trim().isNotEmpty ||
      categoryId != null ||
      renewalDate != null ||
      notes.trim().isNotEmpty ||
      attachments.isNotEmpty;

  bool get canContinueQuestion1 =>
      title.trim().isNotEmpty && categoryOption != null;

  bool get canContinueQuestion2 => renewalDate != null;

  AssistantDraft copyWith({
    AssistantStep? step,
    String? title,
    String? categoryId,
    String? customCategoryName,
    bool clearCustomCategory = false,
    DateTime? renewalDate,
    double? amount,
    bool clearAmount = false,
    RenewalPriority? priority,
    List<int>? reminderSchedule,
    List<DateTime>? customReminderDates,
    int? reminderTimeMinutes,
    bool? customizeReminders,
    List<AssistantAttachment>? attachments,
    String? notes,
    List<String>? tags,
    DateTime? updatedAt,
  }) {
    return AssistantDraft(
      step: step ?? this.step,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      customCategoryName: clearCustomCategory
          ? null
          : (customCategoryName ?? this.customCategoryName),
      renewalDate: renewalDate ?? this.renewalDate,
      amount: clearAmount ? null : (amount ?? this.amount),
      priority: priority ?? this.priority,
      reminderSchedule: reminderSchedule ?? this.reminderSchedule,
      customReminderDates: customReminderDates ?? this.customReminderDates,
      reminderTimeMinutes: reminderTimeMinutes ?? this.reminderTimeMinutes,
      customizeReminders: customizeReminders ?? this.customizeReminders,
      attachments: attachments ?? this.attachments,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'step': step.name,
        'title': title,
        if (categoryId != null) 'categoryId': categoryId,
        if (customCategoryName != null) 'customCategoryName': customCategoryName,
        if (renewalDate != null)
          'renewalDate': renewalDate!.toIso8601String(),
        if (amount != null) 'amount': amount,
        'priority': priority.name,
        'reminderSchedule': reminderSchedule,
        'customReminderDates':
            customReminderDates.map((d) => d.toIso8601String()).toList(),
        'reminderTimeMinutes': reminderTimeMinutes,
        'customizeReminders': customizeReminders,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'notes': notes,
        'tags': tags,
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  factory AssistantDraft.fromJson(Map<String, dynamic> json) {
    return AssistantDraft(
      step: AssistantStep.values.byName(json['step'] as String? ?? 'welcome'),
      title: json['title'] as String? ?? '',
      categoryId: json['categoryId'] as String?,
      customCategoryName: json['customCategoryName'] as String?,
      renewalDate: json['renewalDate'] != null
          ? DateTime.parse(json['renewalDate'] as String)
          : null,
      amount: (json['amount'] as num?)?.toDouble(),
      priority: RenewalPriority.values.byName(
        json['priority'] as String? ?? RenewalPriority.medium.name,
      ),
      reminderSchedule: (json['reminderSchedule'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          const [30, 7, 1],
      customReminderDates: (json['customReminderDates'] as List<dynamic>?)
              ?.map((e) => DateTime.parse(e as String))
              .toList() ??
          const [],
      reminderTimeMinutes: json['reminderTimeMinutes'] as int? ?? 540,
      customizeReminders: json['customizeReminders'] as bool? ?? false,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map(
                (e) => AssistantAttachment.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      notes: json['notes'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }
}
