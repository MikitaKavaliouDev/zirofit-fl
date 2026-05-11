# lib/features/trainer

**Parent:** Root AGENTS.md covers features overview.

## OVERVIEW
Trainer profile & branding. 19 Dart files for public-facing trainer content.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Profile screen | `screens/trainer_profile_screen.dart` | Main profile |
| Branding | `providers/trainer_branding_provider.dart` | Customization |
| Services | `screens/trainer_services_screen.dart` | Offered services |
| Packages | `screens/trainer_packages_screen.dart` | Pricing tiers |
| Social/links | `screens/trainer_social_links_screen.dart` | External links |

## CONVENTIONS
- Provider per content area (branding, services, packages)
- Public profile accessible without auth via `/public/trainer/:username`

## UNIQUE STYLES
- Transformation photos with before/after comparison
- Testimonials collection
- Custom exercises library
- Assessment templates

## ANTI-PATTERNS
- DO NOT expose sensitive trainer data in public routes
- DO NOT skip role checks in profile editing