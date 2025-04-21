import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CustomExpansionTile extends StatelessWidget {
  final Widget? leading;
  final Widget title;
  final Widget? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? contentPadding;
  final void Function(bool)? onExpansionChanged;
  final bool initiallyExpanded;
  final int animationIndex;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final Color? iconColor;
  final Color? expandedIconColor;
  final Color? backgroundColor;
  final Color? collapsedBackgroundColor;

  const CustomExpansionTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.children,
    this.padding,
    this.contentPadding,
    this.onExpansionChanged,
    this.initiallyExpanded = false,
    this.animationIndex = 0,
    this.titleStyle,
    this.subtitleStyle,
    this.iconColor,
    this.expandedIconColor,
    this.backgroundColor,
    this.collapsedBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          listTileTheme: const ListTileThemeData(),
        ),
        child: ExpansionTile(
          leading: leading,
          title: DefaultTextStyle(
            style: titleStyle ??
                Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ) ??
                const TextStyle(fontWeight: FontWeight.w600),
            child: title,
          ),
          subtitle: subtitle != null
              ? DefaultTextStyle(
                  style: subtitleStyle ??
                      Theme.of(context).textTheme.bodySmall ??
                      const TextStyle(fontSize: 12),
                  child: subtitle!,
                )
              : null,
          trailing: trailing,
          children: [
            Padding(
              padding: contentPadding ?? const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
          onExpansionChanged: onExpansionChanged,
          initiallyExpanded: initiallyExpanded,
          iconColor: expandedIconColor ?? iconColor,
          collapsedIconColor: iconColor,
          backgroundColor: backgroundColor,
          collapsedBackgroundColor: collapsedBackgroundColor,
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 0.5,
          end: 0,
          duration: 400.ms,
          delay: (100 * animationIndex).ms,
          curve: Curves.easeOut,
        )
        .fadeIn(
          duration: 400.ms,
          delay: (100 * animationIndex).ms,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .then()
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }
}
