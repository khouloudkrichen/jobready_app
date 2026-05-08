import 'package:flutter/material.dart';

class AppDesign {
  static const navy = Color(0xFF071A2F);
  static const navySoft = Color(0xFF102A46);
  static const violet = Color(0xFF8A22D6);
  static const violetSoft = Color(0xFFA855F7);
  static const ink = Color(0xFF111827);
  static const muted = Color(0xFF6B7280);
  static const bg = Color(0xFFF5F8FF);
  static const card = Colors.white;
  static const darkBg = Color(0xFF0B1220);
  static const darkCard = Color(0xFF111827);
  static const darkBorder = Color(0xFF243244);
  static const darkText = Color(0xFFF8FAFC);
  static const darkMuted = Color(0xFF94A3B8);

  static const gradient = LinearGradient(
    colors: [navy, violet],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static BoxShadow softShadow({double opacity = 0.08}) {
    return BoxShadow(
      color: const Color(0xFF0F172A).withOpacity(opacity),
      blurRadius: 24,
      offset: const Offset(0, 12),
    );
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color pageBg(BuildContext context) => isDark(context) ? darkBg : bg;

  static Color cardColor(BuildContext context) =>
      isDark(context) ? darkCard : card;

  static Color textColor(BuildContext context) =>
      isDark(context) ? darkText : ink;

  static Color mutedText(BuildContext context) =>
      isDark(context) ? darkMuted : muted;

  static Color borderColor(BuildContext context) =>
      isDark(context) ? darkBorder : const Color(0xFFE7ECF5);
}

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final bool dark;

  const AppScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.bottomNavigationBar,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = dark || AppDesign.isDark(context);
    return Scaffold(
      backgroundColor: isDark ? AppDesign.darkBg : AppDesign.bg,
      appBar: appBar,
      body: body,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Border? border;
  final double radius;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.border,
    this.radius = 22,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppDesign.isDark(context);
    final card = Container(
      width: double.infinity,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppDesign.cardColor(context),
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: AppDesign.borderColor(context)),
        boxShadow: isDark ? [] : [AppDesign.softShadow(opacity: 0.055)],
      ),
      child: child,
    );

    if (onTap == null) return card;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: card,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: onPressed == null
              ? LinearGradient(colors: [Colors.grey.shade400, Colors.grey])
              : AppDesign.gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppDesign.violet.withOpacity(0.24),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 19),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;

  const SectionTitle({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppDesign.textColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: TextStyle(
                color: AppDesign.mutedText(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconBadge({
    super.key,
    required this.icon,
    this.color = AppDesign.violet,
    this.size = 42,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class AppStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const AppStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppDesign.violet,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBadge(icon: icon, color: color, size: 36),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: AppDesign.textColor(context),
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppDesign.mutedText(context),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class PillTabShell extends StatelessWidget {
  final List<Widget> tabs;
  final TabController? controller;

  const PillTabShell({super.key, required this.tabs, this.controller});

  @override
  Widget build(BuildContext context) {
    final isDark = AppDesign.isDark(context);
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF182235) : const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: controller,
        tabs: tabs,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: AppDesign.textColor(context),
        unselectedLabelColor: AppDesign.mutedText(context),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
        indicator: BoxDecoration(
          color: isDark ? const Color(0xFF243244) : Colors.white,
          borderRadius: BorderRadius.circular(11),
          boxShadow: [AppDesign.softShadow(opacity: 0.06)],
        ),
      ),
    );
  }
}
