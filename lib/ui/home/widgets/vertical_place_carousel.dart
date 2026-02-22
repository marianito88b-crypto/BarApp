import 'package:flutter/material.dart';
import 'package:barapp/models/place.dart';
import 'package:barapp/ui/home/widgets/place_card.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VerticalPlaceCarousel extends StatefulWidget {
  final List<Place> places;
  final List<String> followingIds;
  final Function(Place, bool) onFollowToggle;
  final Function(Place) onTap;

  const VerticalPlaceCarousel({
    super.key,
    required this.places,
    required this.followingIds,
    required this.onFollowToggle,
    required this.onTap,
  });

  @override
  State<VerticalPlaceCarousel> createState() => _VerticalPlaceCarouselState();
}

class _VerticalPlaceCarouselState extends State<VerticalPlaceCarousel> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.60);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      physics: const BouncingScrollPhysics(),
      pageSnapping: false,
      itemCount: widget.places.length,
      onPageChanged: (int index) => setState(() => _currentPage = index),
      itemBuilder: (context, index) {
        final place = widget.places[index];
        final bool isFollowing = widget.followingIds.contains(place.id);

        return AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            double value = 1.0;
            
            // 🔥 CLAVE: Calculamos el índice activo en tiempo real
            int focusedIndex = _currentPage; 
            
            if (_pageController.position.haveDimensions) {
              value = _pageController.page! - index;
              value = (1 - (value.abs() * 0.3)).clamp(0.85, 1.0);
              // Actualiza automáticamente si se filtra la lista
              focusedIndex = _pageController.page!.round(); 
            } else {
              value = (index == _currentPage) ? 1.0 : 0.85;
            }
            
            final curve = Curves.easeOut.transform(value);
            
            return Center(
              child: Transform.scale(
                scale: curve, 
                child: SizedBox(
                  height: 280, 
                  child: PlaceCard(
                    place: place,
                    // Compara con el índice real, no con el guardado en la memoria vieja
                    isFocused: index == focusedIndex, 
                    imageProvider: _getImageProvider(place),
                    isFollowing: isFollowing,
                    followersCount: place.followersCount ?? 0,
                    onFollowTap: () => widget.onFollowToggle(place, isFollowing),
                    onTap: () => widget.onTap(place),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  ImageProvider _getImageProvider(Place place) {
    if (place.coverImageUrl != null && place.coverImageUrl!.isNotEmpty) {
      return CachedNetworkImageProvider(place.coverImageUrl!);
    } else if (place.imageUrls.isNotEmpty) {
      return CachedNetworkImageProvider(place.imageUrls.first);
    } else {
      return const AssetImage('assets/images/restaurant.png');
    }
  }
}