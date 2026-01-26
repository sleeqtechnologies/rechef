import 'package:flutter/material.dart';

import '../constants/app_spacing.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color? backgroundColor;
  final double? elevation;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 0,
  }) : assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor:
          backgroundColor ?? Theme.of(context).appBarTheme.backgroundColor,
      elevation: elevation ?? Theme.of(context).appBarTheme.elevation,
      automaticallyImplyLeading: false,
      title:
          titleWidget ??
          (title != null
              ? Padding(
                  padding: AppSpacing.appBarPadding,
                  child: Align(
                    alignment: centerTitle
                        ? Alignment.center
                        : Alignment.centerLeft,
                    child: Text(
                      title!,
                      style: Theme.of(context).appBarTheme.titleTextStyle?.copyWith(
                            fontSize: 24,
                          ) ??
                          TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Roobert',
                            color: Theme.of(context).appBarTheme.iconTheme?.color,
                          ),
                    ),
                  ),
                )
              : null),
      titleSpacing: 0,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
