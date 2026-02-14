import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';


class RecipeImage extends StatelessWidget {
  const RecipeImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.loadingBuilder,
    this.errorBuilder,
  });

  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Widget, ImageChunkEvent?)? loadingBuilder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  static Widget _defaultErrorBuilder(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        'assets/icons/recipe.svg',
        width: 28,
        height: 28,
        colorFilter: ColorFilter.mode(
          Colors.grey.shade500,
          BlendMode.srcIn,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return SizedBox(
        width: width,
        height: height,
        child: errorBuilder?.call(context, Object(), null) ?? _defaultErrorBuilder(context),
      );
    }

    final url = imageUrl!;

    if (url.startsWith('data:')) {
      try {
        final base64Str = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (context, error, stackTrace) =>
              errorBuilder?.call(context, error, stackTrace) ?? _defaultErrorBuilder(context),
        );
      } catch (_) {
        return SizedBox(
          width: width,
          height: height,
          child: errorBuilder?.call(context, Object(), null) ?? _defaultErrorBuilder(context),
        );
      }
    }

    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: loadingBuilder,
      errorBuilder: (context, error, stackTrace) =>
          errorBuilder?.call(context, error, stackTrace) ?? _defaultErrorBuilder(context),
    );
  }
}
