import 'package:flutter/material.dart';

class CustomTopBarHelper {
  static Widget? buildLeading({
    required BuildContext context,
    required bool isRtl,
    bool hasBackButton = false,
    Widget? historyButton,
    Widget? searchButton,
  }) {
    final List<Widget> children = [];
    if (hasBackButton && !isRtl) {
      children.add(const BackButton());
    }

    if (isRtl) {
      // RTL Leading is Physical Right. We want Search here.
      if (searchButton != null) children.add(searchButton);
    } else {
      // LTR Leading is Physical Left. We want History here.
      if (historyButton != null) children.add(historyButton);
    }

    if (children.isEmpty) return null;
    if (children.length == 1) return children.first;
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  static List<Widget>? buildActions({
    required BuildContext context,
    required bool isRtl,
    bool hasBackButton = false,
    Widget? historyButton,
    Widget? searchButton,
    List<Widget>? extraActions,
  }) {
    final List<Widget> actions = [];

    if (isRtl && hasBackButton) {
      actions.add(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: BackButton(),
        ),
      );
    }

    if (isRtl) {
      // RTL Actions is Physical Left. We want History here.
      if (historyButton != null) actions.add(historyButton);
    } else {
      // LTR Actions is Physical Right. We want Search here.
      if (searchButton != null) actions.add(searchButton);
    }

    if (extraActions != null) {
      actions.addAll(extraActions);
    }

    return actions.isEmpty ? null : actions;
  }
}
