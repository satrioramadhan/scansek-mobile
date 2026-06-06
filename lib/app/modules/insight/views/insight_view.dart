import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/insight_controller.dart';

class InsightView extends GetView<InsightController> {
  const InsightView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA), // Book paper background
      appBar: AppBar(
        title: const Text(
          'Ensiklopedia ScanSek',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // The fix: Wrap the gradient container in ClipRRect so it respects the AppBar's shape radius.
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF80CBC4), Color(0xFF4DB6AC)], // Teal gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: controller.pageController,
              onPageChanged: (index) => controller.currentPage.value = index,
              physics: const BouncingScrollPhysics(),
              children: [
                _buildHal1Cover(),
                _buildHal2Dashboard(),
                _buildHal3Navigasi(),
                _buildHal4InputScan(),
                _buildHal5ManualAir(),
                _buildHal6Aktivitas(),
                _buildHal7Menu(),
                _buildHal8RiwayatProfil(),
                _buildHal9Penutup(),
              ],
            ),
          ),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() => Text(
              'Halaman ${controller.currentPage.value + 1} dari 9',
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            )),
          ],
        ),
      ),
    );
  }

  // --- HALAMAN BUKU ---

  Widget _buildHal1Cover() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE0F2F1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.menu_book_rounded, size: 80, color: Color(0xFF00796B)),
          ),
          const SizedBox(height: 40),
          const Text(
            'Ensiklopedia\nScanSek',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF26A69A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ScanSek hadir sebagai asisten cerdas untuk "Mindful Eating". Aplikasi ini berfokus membantu Anda memangkas asupan gula berlebih dan memenuhi target energi harian tanpa diet ekstrem yang menyiksa.\n\nPelajari cara memanfaatkan fitur-fitur pintar di dalamnya untuk mencapai tubuh idealmu.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF64748B),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Geser untuk membuka', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Color(0xFF94A3B8), size: 18),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHal2Dashboard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChapterHeader('BAB 1', 'Dashboard & Ringkasan'),
          const SizedBox(height: 24),
          _buildParagraph('Dashboard adalah pusat komando keseharianmu. Di sini kamu bisa memantau tiga pilar utama kesehatanmu secara cepat melalui "Card" informasi.'),
          const SizedBox(height: 24),
          _buildInfoSection(
            title: 'Letak Fitur',
            content: 'Tab Pertama (Kiri Bawah) di Navigasi Utama.',
            icon: Icons.location_on_rounded,
            color: const Color(0xFFEF5350),
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            number: 1,
            color: const Color(0xFF4FC3F7),
            title: 'Ringkasan Kesehatan (Kalori)',
            description: 'Memantau berapa kalori yang sudah masuk, kalori yang terbakar dari aktivitas, dan sisa kuota kalori harianmu.',
          ),
          _buildStepItem(
            number: 2,
            color: const Color(0xFFEF9A9A),
            title: 'Card Gula',
            description: 'Pilar terpenting di ScanSek. Melihat total gramasi gula harian agar tidak menembus batas maksimal.',
          ),
          _buildStepItem(
            number: 3,
            color: const Color(0xFF64B5F6),
            title: 'Card Air',
            description: 'Lingkaran hidrasi biru. Penuhi target air harianmu di sini agar metabolisme pembakaran lemak tidak macet.',
          ),
        ],
      ),
    );
  }

  Widget _buildHal3Navigasi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChapterHeader('BAB 2', 'Navigasi & Tombol Ajaib'),
          const SizedBox(height: 24),
          _buildParagraph('Aplikasi ini dilengkapi 5 Tab navigasi bawah dan satu "Tombol Ajaib" berwarna hijau di tengah.'),
          const SizedBox(height: 24),
          _buildInfoSection(
            title: 'Tombol Tengah Ajaib (FAB)',
            content: 'Tombol melayang berwarna hijau di tengah akan berganti ikon setiap 2 detik secara otomatis. Tunggu ikon yang sesuai dengan kebutuhanmu, lalu klik!',
            icon: Icons.lightbulb_rounded,
            color: const Color(0xFFFFA726),
          ),
          const SizedBox(height: 16),
          _buildBulletItem(icon: Icons.qr_code_scanner_rounded, color: const Color(0xFF4FC3F7), text: 'Ikon Scanner: Membuka fitur AI Scan Pro.'),
          _buildBulletItem(icon: Icons.restaurant_rounded, color: const Color(0xFFFFB74D), text: 'Ikon Garpu & Pisau: Menambah makanan manual.'),
          _buildBulletItem(icon: Icons.directions_run_rounded, color: const Color(0xFF81C784), text: 'Ikon Lari: Memulai rekam aktivitas olahraga (GPS).'),
          _buildBulletItem(icon: Icons.local_drink_rounded, color: const Color(0xFF64B5F6), text: 'Ikon Air: Membuka Quick Add minum air.'),
        ],
      ),
    );
  }

  Widget _buildHal4InputScan() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChapterHeader('BAB 3', 'Input Scan & AI Pro'),
          const SizedBox(height: 24),
          _buildInfoSection(
            title: 'Fungsi & Manfaat',
            content: 'Teknologi AI untuk membebaskanmu dari kerepotan menebak angka kalori dan gula secara manual. Memiliki konversi pintar dari Gram ke Sendok Teh agar kamu sadar betapa bahayanya gula.',
            icon: Icons.lightbulb_rounded,
            color: const Color(0xFFFFA726),
          ),
          _buildInfoSection(
            title: 'Letak Fitur',
            content: 'Tunggu tombol tengah bawah berubah menjadi ikon Scanner, lalu klik.',
            icon: Icons.location_on_rounded,
            color: const Color(0xFFEF5350),
          ),
          const SizedBox(height: 16),
          _buildSubChapter('Cara Penggunaan AI:'),
          const SizedBox(height: 16),
          _buildStepItem(
            number: 1,
            color: const Color(0xFF4FC3F7),
            title: 'Scan Label Kemasan',
            description: 'Arahkan kamera ke tabel "Informasi Nilai Gizi". Kamu bisa memilih mode AI OCR (ML Kit Cepat) atau AI Pro untuk akurasi maksimal.',
          ),
          _buildStepItem(
            number: 2,
            color: const Color(0xFFBA68C8),
            title: 'Scan Makanan Fisik',
            description: 'Di layar Scan, cukup geser toggle "Gunakan AI Pro". Lalu arahkan kamera ke piring makananmu dan foto. AI akan mengenali dan menaksir kalorinya.',
          ),
          _buildStepItem(
            number: 3,
            color: const Color(0xFFFFB74D),
            title: 'Konversi Gula ke Sendok',
            description: 'Hasil scan akan menampilkan peringatan jumlah sendok teh. Misal: 25 gram gula = ±5 Sendok Teh. Jangan sampai kecolongan!',
          ),
        ],
      ),
    );
  }

  Widget _buildHal5ManualAir() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChapterHeader('BAB 4', 'Pencatatan Presisi & Air'),
          const SizedBox(height: 24),
          _buildSubChapter('Pencatatan Manual'),
          _buildInfoSection(
            title: 'Fungsi & Letak',
            content: 'Bagi pengguna mahir yang tahu persis gramasi gizi. Klik tombol tengah saat ikon Garpu/Pisau (atau matikan toggle AI Pro di menu Tambah).',
            icon: Icons.settings_rounded,
            color: const Color(0xFF81C784),
          ),
          _buildParagraph('Masukkan nama makanan, angka kalori, dan gula sesuai takaranmu, lalu simpan ke jurnal harian.'),
          const SizedBox(height: 32),
          _buildSubChapter('Water Tracker'),
          _buildInfoSection(
            title: 'Fungsi & Letak',
            content: 'Menjaga cairan tubuh. Letaknya ada di Dashboard utama atau lewat tombol tengah saat menjadi ikon Air.',
            icon: Icons.water_drop_rounded,
            color: const Color(0xFF29B6F6),
          ),
          _buildParagraph('Setiap habis minum, gunakan tombol Quick Add (250ml untuk gelas, 500ml untuk botol) untuk mengisi lingkaran target birumu.'),
        ],
      ),
    );
  }

  Widget _buildHal6Aktivitas() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChapterHeader('BAB 5', 'Aktivitas & Langkah Kaki'),
          const SizedBox(height: 24),
          _buildInfoSection(
            title: 'Fungsi & Manfaat',
            content: 'Setiap gerak tubuh membakar kalori. Kalori yang terbakar ini akan memotong asupan kalori yang kamu makan, memberikan kelonggaran ekstra untuk jatah makanmu.',
            icon: Icons.directions_walk_rounded,
            color: const Color(0xFF4DB6AC),
          ),
          _buildInfoSection(
            title: 'Letak Fitur',
            content: 'Tab ke-4 (Ikon Sepatu) di Navigasi Utama, atau klik tombol tengah saat ikon Lari (untuk memulai aktivitas GPS).',
            icon: Icons.location_on_rounded,
            color: const Color(0xFFEF5350),
          ),
          const SizedBox(height: 16),
          _buildStepItem(
            number: 1,
            color: const Color(0xFF81C784),
            title: 'Langkah Otomatis',
            description: 'Bawa HP kamu berjalan. ScanSek mengambil data sensor bawaan HP untuk menghitung langkah dan membakar kalorinya otomatis.',
          ),
          _buildStepItem(
            number: 2,
            color: const Color(0xFF9575CD),
            title: 'Olahraga Khusus (GPS)',
            description: 'Klik tombol Lari di tengah, dan mulai rekam rute lari atau sepedamu untuk pencatatan kalori terbakar yang lebih intens.',
          ),
        ],
      ),
    );
  }

  Widget _buildHal7Menu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChapterHeader('BAB 6', 'Menu Navigasi Ekstra'),
          const SizedBox(height: 24),
          _buildParagraph('Di bagian bawah halaman Dashboard utama, kamu akan menemukan 3 menu penting pembantu disiplin dietmu:'),
          const SizedBox(height: 24),
          _buildStepItem(
            number: 1,
            color: const Color(0xFFFFB74D),
            title: 'Fitur Pengingat',
            description: 'Nyalakan alarm! Atur pengingat jam sarapan, makan siang, makan malam, hingga jadwal minum air agar kamu tidak telat makan/minum.',
          ),
          _buildStepItem(
            number: 2,
            color: const Color(0xFF81C784),
            title: 'Fitur Target Harian',
            description: 'Merasa target kalori terlalu ketat atau longgar? Sesuaikan sendiri target harian Kalori, Gula, dan Airmu di menu ini.',
          ),
          _buildStepItem(
            number: 3,
            color: const Color(0xFFBA68C8),
            title: 'Grafik Analisis Rapor',
            description: 'Lihat progres mingguanmu. Ada Grafik Batang untuk melihat konsistensi harian dari target gizi dan aktivitasmu.',
          ),
        ],
      ),
    );
  }

  Widget _buildHal8RiwayatProfil() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChapterHeader('BAB 7', 'Riwayat & Profil'),
          const SizedBox(height: 24),
          _buildSubChapter('Tab Riwayat Makanan (History)'),
          _buildInfoSection(
            title: 'Fungsi & Letak',
            content: 'Tab ke-2 (Ikon Jam) di Navigasi Bawah. Berisi daftar apa saja yang sudah masuk ke perutmu.',
            icon: Icons.history_rounded,
            color: const Color(0xFF4FC3F7),
          ),
          _buildParagraph('Di tab ini, kamu bisa meninjau ulang makanan/minuman yang dikonsumsi, mengedit data yang salah input, atau menghapusnya.'),
          const SizedBox(height: 32),
          _buildSubChapter('Tab Profil (User)'),
          _buildInfoSection(
            title: 'Fungsi & Letak',
            content: 'Tab Terakhir (Ikon Orang) di Navigasi Bawah. Tempat mengatur identitas tubuhmu.',
            icon: Icons.person_rounded,
            color: const Color(0xFFE57373),
          ),
          _buildParagraph('Gunakan halaman Profil untuk mengupdate Berat Badan dan Tinggi Badan terkini. Sistem akan membaca data ini untuk menyesuaikan kembali target kalorimu.'),
        ],
      ),
    );
  }

  Widget _buildHal9Penutup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE8F5E9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.rocket_launch_rounded, size: 80, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 40),
          const Text(
            'Siap Beraksi!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Kesehatan adalah perjalanan maraton, bukan lari sprint yang instan.\n\nJangan membebani diri dengan ekspektasi tidak realistis. Gunakan ScanSek setiap hari untuk membangun habit kesadaran nutrisi kecil yang akan berdampak besar di masa depan.\n\nSemangat, bro!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF475569),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF26A69A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Tutup Buku Panduan',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF475569),
        fontSize: 15,
        height: 1.6,
      ),
    );
  }

  Widget _buildChapterHeader(String chapter, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chapter,
          style: const TextStyle(
            color: Color(0xFF26A69A), // Teal
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 24,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }

  Widget _buildSubChapter(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1E293B),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildInfoSection({required String title, required String content, required IconData icon, required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({required int number, required Color color, required String title, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem({required IconData icon, required Color color, required String text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
