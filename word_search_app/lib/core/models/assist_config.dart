/// AssistConfig — pluggable assist settings for a puzzle session.
/// Pure Dart — zero Flutter UI dependencies.
library;

import 'package:equatable/equatable.dart';

/// Configures which assist mechanics are active and what their limits are.
class AssistConfig extends Equatable {
  const AssistConfig({
    this.allowedHintTiers = const [1, 2, 3, 4, 5, 6],
    this.proximityEnabled = true,
    this.timeLimitSeconds = 240,
    this.bonusTimePerWord = 15,
    this.isShifting = false,
    this.densityTarget = 0.65,
  });

  /// Which hint tiers (1–6) are unlockable during this session.
  final List<int> allowedHintTiers;

  /// Whether the proximity radar assist is active.
  final bool proximityEnabled;

  /// Total time limit in seconds for Timed Attack mode.
  final int timeLimitSeconds;

  /// Bonus seconds added to the clock each time a word is found.
  final int bonusTimePerWord;

  /// Whether Dynamic Mode is active (filler characters periodically re-shuffle).
  final bool isShifting;

  /// Target letter-fill density used when calculating grid dimensions (0–1).
  final double densityTarget;

  AssistConfig copyWith({
    List<int>? allowedHintTiers,
    bool? proximityEnabled,
    int? timeLimitSeconds,
    int? bonusTimePerWord,
    bool? isShifting,
    double? densityTarget,
  }) =>
      AssistConfig(
        allowedHintTiers: allowedHintTiers ?? this.allowedHintTiers,
        proximityEnabled: proximityEnabled ?? this.proximityEnabled,
        timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
        bonusTimePerWord: bonusTimePerWord ?? this.bonusTimePerWord,
        isShifting: isShifting ?? this.isShifting,
        densityTarget: densityTarget ?? this.densityTarget,
      );

  factory AssistConfig.fromJson(Map<String, dynamic> json) => AssistConfig(
        allowedHintTiers: (json['allowed_hint_tiers'] as List<dynamic>?)
                ?.cast<int>() ??
            const [1, 2, 3, 4, 5, 6],
        proximityEnabled: json['proximity_enabled'] as bool? ?? true,
        timeLimitSeconds: json['time_limit_seconds'] as int? ?? 240,
        bonusTimePerWord: json['bonus_time_per_word'] as int? ?? 15,
        isShifting: json['is_shifting'] as bool? ?? false,
        densityTarget: (json['density_target'] as num?)?.toDouble() ?? 0.65,
      );

  Map<String, dynamic> toJson() => {
        'allowed_hint_tiers': allowedHintTiers,
        'proximity_enabled': proximityEnabled,
        'time_limit_seconds': timeLimitSeconds,
        'bonus_time_per_word': bonusTimePerWord,
        'is_shifting': isShifting,
        'density_target': densityTarget,
      };

  @override
  List<Object?> get props => [
        allowedHintTiers,
        proximityEnabled,
        timeLimitSeconds,
        bonusTimePerWord,
        isShifting,
        densityTarget,
      ];
}

