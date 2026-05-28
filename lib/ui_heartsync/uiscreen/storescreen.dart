import 'dart:async';
import 'package:flutter/material.dart';
import 'package:heartsync/ui_heartsync/UIColor/appcolors.dart';
import 'package:heartsync/ui_heartsync/UIColor/screenscaffold.dart';
import 'package:heartsync/ui_heartsync/UIColor/uicard.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Heart Store',
      subtitle: 'Gift suggestions for your love 🎁',
      children: [
        TextField(
          decoration: InputDecoration(
            hintText: 'Search for gifts...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: AppColors.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFEF5BA2))),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(colors: [Color(0xFFEF5A79), Color(0xFFA35BEA)]),
            boxShadow: const [BoxShadow(color: Color(0x261F2937), blurRadius: 12, offset: Offset(0, 6))],
          ),
          child: const Text("📈  Valentine's Day is coming!\nPrepare gifts for your loved one 💝", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              _CatChip('All', selected: true),
              _CatChip('Valentine'),
              _CatChip('Anniversary'),
              _CatChip('Birthday'),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: .68,
          children: const [
            _Product(name: 'Rose Gift Box', price: '\$35', sold: '234 sold', img: 'https://images.unsplash.com/photo-1723274154450-654d2250ccbb?q=80&w=1080', rating: '4.8'),
            _Product(name: 'Premium Silver Necklace', price: '\$52', sold: '156 sold', img: 'https://images.unsplash.com/photo-1643300866907-032b3baeeb1f?q=80&w=1080', rating: '4.9'),
            _Product(name: 'Luxury Perfume', price: '\$88', sold: '98 sold', img: 'https://images.unsplash.com/photo-1747052881000-a640a4981dd0?q=80&w=1080', rating: '4.7'),
            _Product(name: 'Valentine Chocolate Box', price: '\$19', sold: '412 sold', img: 'https://images.unsplash.com/photo-1620527792840-30bee250b846?q=80&w=1080', rating: '4.6'),
          ],
        ),
      ],
    );
  }
}

class _CatChip extends StatelessWidget {
  final String text;
  final bool selected;
  const _CatChip(this.text, {this.selected = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: selected ? const Color(0xFFEF5BA2) : AppColors.card,
        border: Border.all(color: selected ? const Color(0xFFEF5BA2) : AppColors.border),
      ),
      child: Text(text, style: TextStyle(color: selected ? Colors.white : const Color(0xFF374151), fontWeight: FontWeight.w600)),
    );
  }
}

class _Product extends StatelessWidget {
  final String name;
  final String price;
  final String sold;
  final String img;
  final String rating;
  const _Product({required this.name, required this.price, required this.sold, required this.img, required this.rating});
  @override
  Widget build(BuildContext context) {
    return UiCard(
      padding: EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), child: Image.network(img, fit: BoxFit.cover))),
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), borderRadius: BorderRadius.circular(999)),
                  child: Text('⭐ $rating', style: const TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 8, 9, 3),
          child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, color: Color(0xFF374151))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9),
          child: Text(price, style: const TextStyle(color: Color(0xFFE11D48), fontWeight: FontWeight.w800, fontSize: 31 / 1.5)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(9, 4, 9, 9),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(sold, style: const TextStyle(color: AppColors.subtitle, fontSize: 13)),
            Container(
              width: 22,
              height: 22,
              decoration: const BoxDecoration(color: Color(0xFFFFE4EE), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border, color: AppColors.active, size: 15),
            ),
          ]),
        )
      ]),
    );
  }
}