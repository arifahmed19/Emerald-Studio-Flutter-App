class PassportStandard {
  final String country;
  final String name;
  final double widthMm; // width in mm
  final double heightMm; // height in mm
  final String description;
  final String flag; // emoji flag

  PassportStandard({
    required this.country,
    required this.name,
    required this.widthMm,
    required this.heightMm,
    required this.description,
    required this.flag,
  });

  static List<PassportStandard> get defaultStandards => [
    PassportStandard(
      country: 'USA',
      name: 'US Passport',
      widthMm: 51,
      heightMm: 51,
      description: '2x2 inches (51x51 mm)',
      flag: '🇺🇸',
    ),
    PassportStandard(
      country: 'UK',
      name: 'UK Passport',
      widthMm: 35,
      heightMm: 45,
      description: '35x45 mm',
      flag: '🇬🇧',
    ),
    PassportStandard(
      country: 'EU',
      name: 'Schengen / EU Passport',
      widthMm: 35,
      heightMm: 45,
      description: '35x45 mm',
      flag: '🇪🇺',
    ),
    PassportStandard(
      country: 'India',
      name: 'Indian Passport',
      widthMm: 35,
      heightMm: 45,
      description: '35x45 mm',
      flag: '🇮🇳',
    ),
    PassportStandard(
      country: 'Canada',
      name: 'Canadian Passport',
      widthMm: 50,
      heightMm: 70,
      description: '50x70 mm',
      flag: '🇨🇦',
    ),
    PassportStandard(
      country: 'China',
      name: 'Chinese Passport',
      widthMm: 33,
      heightMm: 48,
      description: '33x48 mm',
      flag: '🇨🇳',
    ),
     PassportStandard(
      country: 'Australia',
      name: 'Australian Passport',
      widthMm: 35,
      heightMm: 45,
      description: '35x45 mm',
      flag: '🇦🇺',
    ),
  ];
}
