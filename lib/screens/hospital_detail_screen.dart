import 'package:flutter/material.dart';
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/service.dart';
import '../services/json_service.dart';
import '../theme/app_theme.dart';
import 'create_appointment_screen.dart';

class HospitalDetailScreen extends StatefulWidget {
  final Hospital hospital;

  const HospitalDetailScreen({
    super.key,
    required this.hospital,
  });

  @override
  State<HospitalDetailScreen> createState() => _HospitalDetailScreenState();
}

class _HospitalDetailScreenState extends State<HospitalDetailScreen> {
  List<Doctor> _doctors = [];
  List<Service> _services = [];
  bool _isLoading = true;
  int _currentImageIndex = 0;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.hospital.gallery != null && widget.hospital.gallery!.isNotEmpty) {
      _pageController = PageController();
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final doctors = await JsonService.getDoctorsByHospital(widget.hospital.id);
    
    // Hizmetleri yükle
    final allServices = await JsonService.getServices();
    final hospitalServices = allServices.where((service) {
      return widget.hospital.services.contains(service.id);
    }).toList();

    setState(() {
      _doctors = doctors;
      _services = hospitalServices;
      _isLoading = false;
    });
  }

  String _getDayName(String day) {
    const dayNames = {
      'monday': 'Pazartesi',
      'tuesday': 'Salı',
      'wednesday': 'Çarşamba',
      'thursday': 'Perşembe',
      'friday': 'Cuma',
      'saturday': 'Cumartesi',
      'sunday': 'Pazar',
    };
    return dayNames[day] ?? day;
  }

  String _formatWorkingHours(Map<String, dynamic>? hours) {
    if (hours == null || hours['isAvailable'] == false) {
      return 'Kapalı';
    }
    final start = hours['start'] ?? '';
    final end = hours['end'] ?? '';
    return '$start - $end';
  }

  List<String> _getGalleryImages() {
    final gallery = widget.hospital.gallery ?? [];
    // Maksimum 5 fotoğraf göster
    return gallery.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    final galleryImages = _getGalleryImages();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/other_page.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    // Header
                    SliverAppBar(
                      expandedHeight: 200,
                      pinned: true,
                      backgroundColor: AppTheme.tealBlue,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        title: Text(
                          widget.hospital.name,
                          style: AppTheme.headingMedium.copyWith(
                            color: AppTheme.white,
                          ),
                        ),
                        background: galleryImages.isNotEmpty
                            ? _buildImageCarousel(galleryImages)
                            : widget.hospital.image != null
                                ? Image.asset(
                                    widget.hospital.image!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppTheme.lightTurquoise,
                                    child: const Icon(
                                      Icons.local_hospital,
                                      size: 80,
                                      color: AppTheme.white,
                                    ),
                                  ),
                      ),
                    ),
                    // İçerik
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Fotoğraf Galerisi (Eğer varsa)
                            if (galleryImages.isNotEmpty) ...[
                              _buildGallerySection(galleryImages),
                              const SizedBox(height: 24),
                            ],
                            // Hastane Bilgileri
                            _buildInfoSection(),
                            const SizedBox(height: 24),
                            // Çalışma Saatleri
                            _buildWorkingHoursSection(),
                            const SizedBox(height: 24),
                            // Hizmetler
                            if (_services.isNotEmpty) ...[
                              _buildServicesSection(),
                              const SizedBox(height: 24),
                            ],
                            // Doktorlar
                            if (_doctors.isNotEmpty) ...[
                              _buildDoctorsSection(),
                              const SizedBox(height: 24),
                            ],
                            // Randevu Oluştur Butonu
                            _buildAppointmentButton(),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return PageView.builder(
      controller: _pageController,
      itemCount: images.length,
      onPageChanged: (index) {
        setState(() {
          _currentImageIndex = index;
        });
      },
      itemBuilder: (context, index) {
        return Image.asset(
          images[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppTheme.lightTurquoise,
              child: const Icon(
                Icons.image,
                size: 80,
                color: AppTheme.white,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGallerySection(List<String> images) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotoğraflar',
          style: AppTheme.headingSmall,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: PageController(),
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    images[index],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.inputFieldGray,
                        child: const Icon(
                          Icons.image,
                          size: 60,
                          color: AppTheme.iconGray,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Sayfa göstergesi
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            images.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentImageIndex == index
                    ? AppTheme.tealBlue
                    : AppTheme.iconGray.withOpacity(0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hastane Bilgileri',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, widget.hospital.address),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, widget.hospital.phone),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email, widget.hospital.email),
          if (widget.hospital.description.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              widget.hospital.description,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.grayText,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.tealBlue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: AppTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildWorkingHoursSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çalışma Saatleri',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          ...widget.hospital.workingHours.entries.map((entry) {
            final day = _getDayName(entry.key);
            final hours = entry.value as Map<String, dynamic>;
            final isAvailable = hours['isAvailable'] == true;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    day,
                    style: AppTheme.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    _formatWorkingHours(hours),
                    style: AppTheme.bodyMedium.copyWith(
                      color: isAvailable
                          ? AppTheme.successGreen
                          : AppTheme.grayText,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hizmetler',
            style: AppTheme.headingSmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightTurquoise.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.tealBlue.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  service.name,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.tealBlue,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Doktorlar',
                style: AppTheme.headingSmall,
              ),
              Text(
                '${_doctors.length} doktor',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.grayText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _doctors.length,
              itemBuilder: (context, index) {
                final doctor = _doctors[index];
                return _buildDoctorCard(doctor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.mediumTurquoise,
              image: doctor.image != null
                  ? DecorationImage(
                      image: AssetImage(doctor.image!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: doctor.image == null
                ? const Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.white,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            doctor.name,
            style: AppTheme.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            doctor.specialty,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.grayText,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateAppointmentScreen(
                preselectedHospitalId: widget.hospital.id,
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          'Randevu Oluştur',
          style: AppTheme.bodyLarge.copyWith(
            color: AppTheme.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

