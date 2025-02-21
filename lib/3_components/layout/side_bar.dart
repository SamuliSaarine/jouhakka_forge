import 'package:flutter/material.dart';
import 'package:jouhakka_forge/0_models/component.dart';
import 'package:jouhakka_forge/0_models/page.dart';
import 'package:jouhakka_forge/2_services/session.dart';
import 'package:jouhakka_forge/3_components/buttons/my_icon_button.dart';
import 'package:jouhakka_forge/3_components/layout/root_selector_list.dart';
import 'package:jouhakka_forge/4_views/page_design_view.dart';
import 'package:jouhakka_forge/5_style/colors.dart';

class SideBar extends StatefulWidget {
  final Function(Widget view) onViewChange;
  const SideBar({super.key, required this.onViewChange});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  Widget? panel;
  int index = 0;
  List<MenuOption> topMenu = [];
  List<MenuOption> bottomMenu = [];

  @override
  void initState() {
    super.initState();
    topMenu = [
      //Pages
      MenuOption(
        "Pages",
        icon: Icons.devices_outlined,
        panelBuilder: () => RootSelectorPanel<UIPage>(
            Session.currentProject.value!.pages, onSelection: (page) {
          Session.lastPage.value = page;
          widget.onViewChange(PageDesignView(page));
        }),
        viewBuilder: () {
          UIPage? page = Session.lastPage.value ??
              Session.currentProject.value!.pages.first;
          if (page != null) {
            Session.lastPage.value = page;
            return PageDesignView(page);
          } else {
            return const Center(
              child: Text("No Pages Found"),
            );
          }
        },
      ),
      //Components
      MenuOption(
        "Components",
        icon: Icons.widgets_outlined,
        panelBuilder: () => RootSelectorPanel<UIComponent>(
          Session.currentProject.value!.components,
          onSelection: (component) => widget.onViewChange(const Placeholder()),
        ),
        viewBuilder: () => const Center(
          child: Text("No Components Found"),
        ),
      ),
      //Assets
      MenuOption(
        "Assets",
        icon: Icons.image_outlined,
        panelBuilder: () => Center(
          child:
              Text("No Assets Found", style: TextStyle(color: MyColors.text)),
        ),
        viewBuilder: () => const Center(
          child: Text("No Assets Found"),
        ),
      ),
      //Project
      MenuOption(
        "Project",
        icon: Icons.settings_applications_outlined,
        panelBuilder: () => const Center(
          child: Text("No Project Found"),
        ),
        viewBuilder: () => const Center(
          child: Text("No Project Found"),
        ),
      ),
    ];

    bottomMenu = [
      //Settings
      MenuOption(
        "Preferences",
        icon: Icons.tune_outlined,
        panelBuilder: () => const Center(
          child: Text("No Settings Found"),
        ),
        viewBuilder: () => const Center(
          child: Text("No Settings Found"),
        ),
      ),
      //Help
      MenuOption(
        "Help",
        icon: Icons.help_outline,
        panelBuilder: () => const Center(
          child: Text("No Help Found"),
        ),
        viewBuilder: () => const Center(
          child: Text("No Help Found"),
        ),
      ),
      //Exit
      MenuOption(
        "Exit",
        icon: Icons.exit_to_app_outlined,
        panelBuilder: () => const Center(
          child: Text("No Exit Found"),
        ),
        viewBuilder: () => const Center(
          child: Text("No Exit Found"),
        ),
      ),
    ];

    panel = topMenu[0].panelBuilder();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Row(
        children: [
          ColoredBox(
            color: MyColors.background,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Spacer(),
                  //Top Menu
                  for (int i = 0; i < topMenu.length; i++)
                    _menuButton(topMenu[i], i),
                  const Spacer(),
                  //Bottom Menu
                  for (int i = 0; i < bottomMenu.length; i++)
                    _menuButton(bottomMenu[i], topMenu.length + i),
                ],
              ),
            ),
          ),
          if (panel != null) ...[
            const VerticalDivider(
              width: 1,
            ),
            Expanded(child: panel!)
          ],
        ],
      ),
    );
  }

  Widget _menuButton(MenuOption item, int index) {
    return MyIconButton(
      icon: item.icon,
      tooltip: item.title,
      isSelected: this.index == index,
      decoration: MyIconButtonDecoration(
        iconColor: InteractiveColorSettings(color: MyColors.text),
        backgroundColor: const InteractiveColorSettings(
          color: Colors.transparent,
          hoverColor: MyColors.mildDifference,
          selectedColor: MyColors.strongDifference,
        ),
        size: 24,
        padding: 8,
        borderRadius: 4,
      ),
      primaryAction: (_) {
        Widget panelWidget = item.panelBuilder();
        setState(() {
          this.index = index;
          panel = panelWidget;
        });
        if (item.viewBuilder != null) {
          widget.onViewChange(item.viewBuilder!());
        }
      },
      secondaryAction: (_) {
        Widget panelWidget = item.panelBuilder();
        setState(() {
          this.index = index;
          panel = panelWidget;
        });
      },
    );
  }
}

class MenuOption {
  final String title;
  final IconData icon;
  final Widget Function() panelBuilder;
  final Widget Function()? viewBuilder;
  const MenuOption(
    this.title, {
    required this.icon,
    required this.panelBuilder,
    required this.viewBuilder,
  });
}
