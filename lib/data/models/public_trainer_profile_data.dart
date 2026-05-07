import 'package:zirofit_fl/data/models/profile.dart';
import 'package:zirofit_fl/data/models/package.dart';
import 'package:zirofit_fl/data/models/service.dart';
import 'package:zirofit_fl/data/models/transformation_photo.dart';
import 'package:zirofit_fl/data/models/testimonial.dart';
import 'package:zirofit_fl/data/models/social_link.dart';

/// Aggregates all data for a public trainer profile viewable by clients.
///
/// Corresponds to the response from `GET /api/trainers/{username}`.
class PublicTrainerProfileData {
  final Profile profile;
  final List<Package> packages;
  final List<Service> services;
  final List<TransformationPhoto> transformations;
  final List<Testimonial> testimonials;
  final List<SocialLink> socialLinks;

  const PublicTrainerProfileData({
    required this.profile,
    this.packages = const [],
    this.services = const [],
    this.transformations = const [],
    this.testimonials = const [],
    this.socialLinks = const [],
  });

  factory PublicTrainerProfileData.fromJson(Map<String, dynamic> json) {
    final profile =
        Profile.fromJson(json['profile'] as Map<String, dynamic>);

    final List<Package> packages;
    final rawPackages = json['packages'] as List?;
    if (rawPackages != null) {
      packages = rawPackages
          .map((e) => Package.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      packages = [];
    }

    final List<Service> services;
    final rawServices = json['services'] as List?;
    if (rawServices != null) {
      services = rawServices
          .map((e) => Service.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      services = [];
    }

    final List<TransformationPhoto> transformations;
    final rawTransformations = json['transformations'] as List?;
    if (rawTransformations != null) {
      transformations = rawTransformations
          .map((e) => TransformationPhoto.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      transformations = [];
    }

    final List<Testimonial> testimonials;
    final rawTestimonials = json['testimonials'] as List?;
    if (rawTestimonials != null) {
      testimonials = rawTestimonials
          .map((e) => Testimonial.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      testimonials = [];
    }

    final List<SocialLink> socialLinks;
    final rawSocialLinks = json['social_links'] as List?;
    if (rawSocialLinks != null) {
      socialLinks = rawSocialLinks
          .map((e) => SocialLink.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      socialLinks = [];
    }

    return PublicTrainerProfileData(
      profile: profile,
      packages: packages,
      services: services,
      transformations: transformations,
      testimonials: testimonials,
      socialLinks: socialLinks,
    );
  }

  Map<String, dynamic> toJson() => {
        'profile': profile.toJson(),
        'packages': packages.map((e) => e.toJson()).toList(),
        'services': services.map((e) => e.toJson()).toList(),
        'transformations': transformations.map((e) => e.toJson()).toList(),
        'testimonials': testimonials.map((e) => e.toJson()).toList(),
        'social_links': socialLinks.map((e) => e.toJson()).toList(),
      };
}
