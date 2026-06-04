class BMICategory {
  final String name;
  final double minBMI;
  final double maxBMI;
  final double defaultCalories;
  final double defaultSugar;
  final int defaultWater;
  final double defaultBurn;
  final String welcomeMessage;

  BMICategory({
    required this.name,
    required this.minBMI,
    required this.maxBMI,
    required this.defaultCalories,
    required this.defaultSugar,
    required this.defaultWater,
    required this.defaultBurn,
    required this.welcomeMessage,
  });
}

class BMIHelper {
  static final List<BMICategory> categories = [
    BMICategory(
      name: 'Kurus',
      minBMI: 0.0,
      maxBMI: 18.5,
      defaultCalories: 2500,
      defaultSugar: 50,
      defaultWater: 2000,
      defaultBurn: 300.0,
      welcomeMessage:
          '''BMI kamu masuk kategori Kurus (Underweight). Berdasarkan pedoman kesehatan, sistem mengatur surplus kalori agar badanmu mencapai proporsi ideal.

• Kalori = 2500 kkal (Target Surplus)
• Gula = 50g (Batas Maksimal WHO)
• Air = 2000 ml (Standar Hidrasi)
• Bakar Kalori = 300 kkal (Fokus perkuat massa otot, bukan membuang lemak)

Yuk, banyakin makan bergizi! Semangat sehat berawal dari sekarang!

*kamu bisa edit target sendiri di fitur target''',
    ),
    BMICategory(
      name: 'Normal',
      minBMI: 18.5,
      maxBMI: 25.0,
      defaultCalories: 2000,
      defaultSugar: 50,
      defaultWater: 2000,
      defaultBurn: 400.0,
      welcomeMessage:
          '''BMI kamu masuk kategori Normal. Sistem menjadikan pedoman Kemenkes RI dan WHO sebagai target default harianmu untuk menjaga kestabilan.

• Kalori = 2000 kkal (Target AKG Kemenkes)
• Gula = 50g (Batas Maksimal WHO)
• Air = 2000 ml (Standar Kemenkes)
• Bakar Kalori = 400 kkal (Standar Jantung Sehat AHA)

Pertahankan hidup sehat! Semangat sehat berawal dari sekarang!

*kamu bisa edit target sendiri di fitur target''',
    ),
    BMICategory(
      name: 'Gemuk (Overweight)',
      minBMI: 25.0,
      maxBMI: 27.0,
      defaultCalories: 1800,
      defaultSugar: 25,
      defaultWater: 2500,
      defaultBurn: 500.0,
      welcomeMessage:
          '''BMI kamu tergolong Gemuk (Overweight). Sistem menetapkan defisit kalori ringan (diet aman) untuk mengembalikan keseimbangan BMI-mu tanpa menyiksa.

• Kalori = 1800 kkal (Defisit Ringan)
• Gula = 25g (Batas Ketat WHO)
• Air = 2500 ml (Bantu dorong metabolisme)
• Bakar Kalori = 500 kkal (Fokus pembakaran lemak AHA)

Semangat sehat berawal dari sekarang!

*kamu bisa edit target sendiri di fitur target''',
    ),
    BMICategory(
      name: 'Obesitas Tingkat 1',
      minBMI: 27.0,
      maxBMI: 30.0,
      defaultCalories: 1500,
      defaultSugar: 15,
      defaultWater: 3000,
      defaultBurn: 600.0,
      welcomeMessage:
          '''BMI kamu tergolong Obesitas Tingkat 1. Sesuai pedoman klinis (WHO & Kemenkes RI), sistem menerapkan terapi Fat Loss Progresif untuk menekan Systemic Insulin Resistance.

• Kalori = 1500 kkal (Defisit Sedang)
• Gula = 15g (Batas Ketat, Waspada Diabetes!)
• Air = 3000 ml (Induksi Water-Induced Thermogenesis)
• Bakar Kalori = 600 kkal (Target Fat Loss aktif AHA)

Waktunya bakar lemak viseral, semangat sehat berawal dari sekarang!

*kamu bisa edit target sendiri di fitur target''',
    ),
    BMICategory(
      name: 'Obesitas Tingkat 2',
      minBMI: 30.0,
      maxBMI: 100.0,
      defaultCalories: 1200,
      defaultSugar: 10,
      defaultWater: 3500,
      defaultBurn: 700.0,
      welcomeMessage:
          '''BMI kamu tergolong Obesitas Tingkat 2. Sistem mengaktifkan mode target ketat. Fokus utamamu adalah memangkas lemak viseral dan membanjiri tubuh dengan hidrasi sehat.

• Kalori = 1200 kkal (Defisit Ketat Terukur)
• Gula = 10g (Sangat Ketat, putus rantai kecanduan gula!)
• Air = 3500 ml (Wajib untuk detoksifikasi lipolisis)
• Bakar Kalori = 700 kkal (Fokus bakar kalori masif)

Biar racun-racunnya luntur, semangat sehat berawal dari sekarang!

*kamu bisa edit target sendiri di fitur target''',
    ),
  ];

  static double hitungBMI(double beratKg, double tinggiCm) {
    if (tinggiCm == 0) return 0;
    double tinggiM = tinggiCm / 100;
    return beratKg / (tinggiM * tinggiM);
  }

  static BMICategory getCategory(double bmi) {
    for (var cat in categories) {
      if (bmi >= cat.minBMI && bmi < cat.maxBMI) {
        return cat;
      }
    }
    return categories[1]; // Fallback to Normal
  }
}
