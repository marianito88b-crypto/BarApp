import 'package:flutter/material.dart';

/// Representa un elemento de navegación del panel de dueño.
class NavItem {
  final String label;
  final IconData iconOutlined;
  final IconData iconSelected;
  final Widget widget;

  NavItem(
    this.label,
    this.iconOutlined,
    this.iconSelected,
    this.widget,
  );
}

/// Barra de navegación flotante tipo píldora para el panel móvil.
class OwnerNavBar extends StatelessWidget {
  final List<NavItem> items;
  final int currentIndex;
  final void Function(int) onTap;
  final Map<String, dynamic> placeData;
  final bool Function(String, Map<String, dynamic>) isFeatureEnabled;

  const OwnerNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    required this.placeData,
    required this.isFeatureEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E).withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.orangeAccent.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
        border: Border.all(
          color: Colors.orangeAccent,
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          itemBuilder: (context, index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            final isLocked = !isFeatureEnabled(item.label, placeData);

            final color = isLocked
                ? Colors.grey.withValues(alpha: 0.5)
                : (isSelected ? Colors.orangeAccent : Colors.white54);

            return Center(
              child: InkWell(
                onTap: () => onTap(index),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 70,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topRight,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isSelected ? item.iconSelected : item.iconOutlined,
                              color: color,
                              size: 24,
                            ),
                          ),
                          if (isLocked)
                            const Positioned(
                              right: -2,
                              top: -2,
                              child: Icon(
                                Icons.lock,
                                color: Colors.orangeAccent,
                                size: 12,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 9,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
