import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/favorite.dart';
import '../models/hospital.dart';
import '../models/service.dart';
import '../services/json_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'create_appointment_screen.dart';

class AppointmentOptionsScreen extends StatefulWidget {
  const AppointmentOptionsScreen({super.key});

  @override
  State<AppointmentOptionsScreen> createState() => _AppointmentOptionsScreenState();
}

class _AppointmentOptionsScreenState extends State<AppointmentOptionsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  List<Service> _services = [];
  List<Hospital> _hospitals = [];
  List<Doctor> _doctors = [];
  List<Appointment> _appointments = [];
  Set<String> _favoriteHospitalIds = {};
  Set<String> _favoriteDoctorIds = {};
  Set<String> _favoriteServiceIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final servicesFuture = JsonService.getServices();
    final hospitalsFuture = JsonService.getHospitals();
    final doctorsFuture = JsonService.getDoctors();
    final appointmentsFuture = JsonService.getAppointments();
    final favHospFuture = JsonService.getFavoriteIdsByType(FavoriteType.hospital);
    final favDoctorFuture = JsonService.getFavoriteIdsByType(FavoriteType.doctor);
    final favServiceFuture = JsonService.getFavoriteIdsByType(FavoriteType.service);

    final services = await servicesFuture;
    final hospitals = await hospitalsFuture;
    final doctors = await doctorsFuture;
    final appointments = await appointmentsFuture;
    final favoriteHospitals = await favHospFuture;
    final favoriteDoctors = await favDoctorFuture;
    final favoriteServices = await favServiceFuture;

    services.sort((a, b) {
      final normalizedA = a.name.toLowerCase();
      final normalizedB = b.name.toLowerCase();
      final isGeneralA =
          normalizedA.contains('genel muayene') || normalizedA.contains('kontrol');
      final isGeneralB =
          normalizedB.contains('genel muayene') || normalizedB.contains('kontrol');

      if (isGeneralA && !isGeneralB) return -1;
      if (!isGeneralA && isGeneralB) return 1;

      final aFav = favoriteServices.contains(a.id);
      final bFav = favoriteServices.contains(b.id);
      if (aFav != bFav) return aFav ? -1 : 1;

      return a.name.compareTo(b.name);
    });

    setState(() {
      _services = services;
      _hospitals = hospitals;
      _doctors = doctors;
      _appointments = appointments;
      _favoriteHospitalIds = favoriteHospitals;
      _favoriteDoctorIds = favoriteDoctors;
      _favoriteServiceIds = favoriteServices;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPrimary,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _AppointmentWizard(
                      services: _services,
                      hospitals: _hospitals,
                      doctors: _doctors,
                      appointments: _appointments,
                      favoriteServiceIds: _favoriteServiceIds,
                      favoriteHospitalIds: _favoriteHospitalIds,
                      favoriteDoctorIds: _favoriteDoctorIds,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: BoxDecoration(
        gradient: AppTheme.medicalGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.calendar_today_rounded,
                        color: AppTheme.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Randevu Oluştur',
                        style: AppTheme.headingLarge.copyWith(
                          color: AppTheme.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Size en uygun yöntemi seçin',
                  style: AppTheme.bodyMedium.copyWith(
                    color: AppTheme.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// Adım adım randevu oluşturma wizard'ı
class _AppointmentWizard extends StatefulWidget {
  final List<Service> services;
  final List<Hospital> hospitals;
  final List<Doctor> doctors;
  final List<Appointment> appointments;
  final Set<String> favoriteServiceIds;
  final Set<String> favoriteHospitalIds;
  final Set<String> favoriteDoctorIds;

  const _AppointmentWizard({
    required this.services,
    required this.hospitals,
    required this.doctors,
    required this.appointments,
    required this.favoriteServiceIds,
    required this.favoriteHospitalIds,
    required this.favoriteDoctorIds,
  });

  @override
  State<_AppointmentWizard> createState() => _AppointmentWizardState();
}

class _AppointmentWizardState extends State<_AppointmentWizard> {
  Service? _selectedService;
  Hospital? _selectedHospital;
  Doctor? _selectedDoctor;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedCity;
  String? _selectedDistrict;
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // İlerleme göstergesi
          _buildProgressIndicator(),
          const SizedBox(height: 32),
          
          // Adım 1: Hizmet Seçimi
          _buildStepCard(
            stepNumber: 1,
            title: 'Hizmet Seçin',
            subtitle: 'Randevu almak istediğiniz hizmeti seçin',
            icon: Icons.medical_services_rounded,
            child: _buildServiceSelection(),
          ),
          const SizedBox(height: 20),
          
          // Adım 2: Konum/Hastane Seçimi (Hizmet seçildikten sonra görünür)
          if (_selectedService != null) ...[
            _buildStepCard(
              stepNumber: 2,
              title: 'Hastane Seçin',
              subtitle: 'İl, ilçe veya konumunuza göre hastane seçin',
              icon: Icons.local_hospital_rounded,
              child: _buildHospitalSelection(),
            ),
            const SizedBox(height: 20),
          ],
          
          // Adım 3: Doktor Seçimi (Hastane seçildikten sonra görünür)
          if (_selectedHospital != null) ...[
            _buildStepCard(
              stepNumber: 3,
              title: 'Doktor Seçin',
              subtitle: 'Randevu almak istediğiniz doktoru seçin',
              icon: Icons.person_outline_rounded,
              child: _buildDoctorSelection(),
            ),
            const SizedBox(height: 20),
          ],
          
          // Adım 4: Tarih ve Saat Seçimi (Doktor seçildikten sonra görünür)
          if (_selectedDoctor != null) ...[
            _buildStepCard(
              stepNumber: 4,
              title: 'Tarih ve Saat Seçin',
              subtitle: 'Randevu için uygun tarih ve saati seçin',
              icon: Icons.calendar_today_rounded,
              child: _buildDateTimeSelection(),
            ),
            const SizedBox(height: 20),
          ],
          
          // Randevu Oluştur Butonu (Tüm adımlar tamamlandığında görünür)
          if (_selectedService != null &&
              _selectedHospital != null &&
              _selectedDoctor != null &&
              _selectedDate != null &&
              _selectedTime != null) ...[
            _buildCreateButton(),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalSteps = 4;
    final completedSteps = [
      _selectedService != null,
      _selectedHospital != null,
      _selectedDoctor != null,
      _selectedDate != null && _selectedTime != null,
    ].where((completed) => completed).length;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'İlerleme',
                style: AppTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$completedSteps / $totalSteps',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.medicalBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: completedSteps / totalSteps,
              minHeight: 8,
              backgroundColor: AppTheme.backgroundSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.medicalBlue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.medicalGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$stepNumber',
                      style: AppTheme.headingSmall.copyWith(
                        color: AppTheme.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, color: AppTheme.medicalBlue, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: AppTheme.headingSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.mediumText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSelection() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: widget.services.map((service) {
        final isSelected = _selectedService?.id == service.id;
        final isFavorite = widget.favoriteServiceIds.contains(service.id);
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedService = service;
              _selectedHospital = null;
              _selectedDoctor = null;
              _selectedDate = null;
              _selectedTime = null;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.medicalBlue
                  : AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppTheme.medicalBlue
                    : AppTheme.borderGray.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isFavorite)
                  Icon(
                    Icons.star_rounded,
                    color: isSelected
                        ? AppTheme.white
                        : AppTheme.warningOrange,
                    size: 18,
                  ),
                if (isFavorite) const SizedBox(width: 6),
                Text(
                  service.name,
                  style: AppTheme.bodyMedium.copyWith(
                    color: isSelected
                        ? AppTheme.white
                        : AppTheme.darkText,
                    fontWeight: isSelected || isFavorite
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHospitalSelection() {
    // Filtrelenmiş hastaneler
    List<Hospital> filteredHospitals = widget.hospitals.where((hospital) {
      if (!hospital.services.contains(_selectedService!.id)) return false;
      if (_selectedCity != null && hospital.province != _selectedCity) return false;
      if (_selectedDistrict != null && hospital.district != _selectedDistrict) return false;
      if (_currentPosition != null && hospital.latitude != null && hospital.longitude != null) {
        final distance = LocationService.distanceInKm(
          startLat: _currentPosition!.latitude,
          startLng: _currentPosition!.longitude,
          endLat: hospital.latitude!,
          endLng: hospital.longitude!,
        );
        if (distance > 10) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) {
        final favCompare = _compareFavorites(
          a.id,
          b.id,
          widget.favoriteHospitalIds,
        );
        if (favCompare != 0) return favCompare;
        return a.name.compareTo(b.name);
      });

    // Şehirler listesi
    final cities = <String>{};
    for (final hospital in widget.hospitals) {
      if (hospital.services.contains(_selectedService!.id) &&
          hospital.province != null &&
          hospital.province!.isNotEmpty) {
        cities.add(hospital.province!);
      }
    }
    final sortedCities = cities.toList()..sort();

    // İlçeler listesi
    final districts = <String>{};
    if (_selectedCity != null) {
      for (final hospital in widget.hospitals) {
        if (hospital.province == _selectedCity &&
            hospital.district != null &&
            hospital.district!.isNotEmpty &&
            hospital.services.contains(_selectedService!.id)) {
          districts.add(hospital.district!);
        }
      }
    }
    final sortedDistricts = districts.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Konum butonu
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isLoadingLocation
                    ? null
                    : () async {
                        setState(() {
                          _isLoadingLocation = true;
                        });
                        try {
                          final position =
                              await LocationService.determinePosition();
                          if (position != null) {
                            setState(() {
                              _currentPosition = position;
                              _selectedCity = null;
                              _selectedDistrict = null;
                            });
                          } else {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Konum izni verilmedi.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Konum alınamadı: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isLoadingLocation = false;
                            });
                          }
                        }
                      },
                icon: _isLoadingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(
                  _currentPosition != null
                      ? 'Konumunuz kullanılıyor'
                      : 'Konumumu Kullan',
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                    color: AppTheme.medicalBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // İl seçimi
        if (sortedCities.isNotEmpty) ...[
          Text(
            'İl Seçin (Opsiyonel)',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedCity,
            decoration: InputDecoration(
              hintText: 'Tüm İller',
              prefixIcon: Icon(Icons.location_city_rounded,
                  color: AppTheme.medicalBlue),
              filled: true,
              fillColor: AppTheme.inputBackground,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tüm İller'),
              ),
              ...sortedCities.map((city) => DropdownMenuItem<String>(
                    value: city,
                    child: Text(city),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCity = value;
                _selectedDistrict = null;
                _selectedHospital = null;
                _selectedDoctor = null;
                _selectedDate = null;
                _selectedTime = null;
                _currentPosition = null;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        
        // İlçe seçimi
        if (sortedDistricts.isNotEmpty) ...[
          Text(
            'İlçe Seçin (Opsiyonel)',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: InputDecoration(
              hintText: 'Tüm İlçeler',
              prefixIcon: Icon(Icons.location_on_rounded,
                  color: AppTheme.medicalBlue),
              filled: true,
              fillColor: AppTheme.inputBackground,
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Tüm İlçeler'),
              ),
              ...sortedDistricts.map((district) => DropdownMenuItem<String>(
                    value: district,
                    child: Text(district),
                  )),
            ],
            onChanged: (value) {
              setState(() {
                _selectedDistrict = value;
                _selectedHospital = null;
                _selectedDoctor = null;
                _selectedDate = null;
                _selectedTime = null;
              });
            },
          ),
          const SizedBox(height: 16),
        ],
        
        // Hastane listesi
        if (filteredHospitals.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    color: AppTheme.mediumText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Seçilen kriterlere uygun hastane bulunamadı.',
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.mediumText,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredHospitals.map((hospital) {
            final isSelected = _selectedHospital?.id == hospital.id;
            final isFavorite =
                widget.favoriteHospitalIds.contains(hospital.id);
            double? distance;
            if (_currentPosition != null &&
                hospital.latitude != null &&
                hospital.longitude != null) {
              distance = LocationService.distanceInKm(
                startLat: _currentPosition!.latitude,
                startLng: _currentPosition!.longitude,
                endLat: hospital.latitude!,
                endLng: hospital.longitude!,
              );
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.medicalBlue.withValues(alpha: 0.1)
                    : AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.medicalBlue
                      : AppTheme.borderGray.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedHospital = hospital;
                      _selectedDoctor = null;
                      _selectedDate = null;
                      _selectedTime = null;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: AppTheme.medicalBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.local_hospital_rounded,
                            color: AppTheme.medicalBlue,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  if (isFavorite)
                                    Icon(
                                      Icons.star_rounded,
                                      color: AppTheme.warningOrange,
                                      size: 16,
                                    ),
                                  if (isFavorite) const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hospital.name,
                                      style: AppTheme.bodyMedium.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppTheme.medicalBlue
                                            : AppTheme.darkText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: AppTheme.mediumText,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${hospital.province ?? ''} ${hospital.district ?? ''}',
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.mediumText,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (distance != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.medicalBlue
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${distance.toStringAsFixed(1)} km',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.medicalBlue,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.medicalBlue,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildDoctorSelection() {
    // Seçilen hastanede çalışan ve seçilen hizmeti verebilen doktorlar
    final filteredDoctors = widget.doctors.where((doctor) {
      if (doctor.hospitalId != _selectedHospital!.id) return false;
      if (!doctor.services.contains(_selectedService!.id)) return false;
      return true;
    }).toList()
      ..sort((a, b) {
        final favCompare = _compareFavorites(
          a.id,
          b.id,
          widget.favoriteDoctorIds,
        );
        if (favCompare != 0) return favCompare;
        return a.fullName.compareTo(b.fullName);
      });

    if (filteredDoctors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.mediumText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu hastanede seçilen hizmeti veren doktor bulunamadı.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.mediumText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredDoctors.map((doctor) {
        final isSelected = _selectedDoctor?.id == doctor.id;
        final isFavorite = widget.favoriteDoctorIds.contains(doctor.id);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.medicalBlue.withValues(alpha: 0.1)
                : AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppTheme.medicalBlue
                  : AppTheme.borderGray.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDoctor = doctor;
                  _selectedDate = null;
                  _selectedTime = null;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.medicalBlue.withValues(alpha: 0.2),
                            AppTheme.medicalGreen.withValues(alpha: 0.2),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: doctor.image != null
                          ? ClipOval(
                              child: Image.network(
                                doctor.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person_rounded,
                                  color: AppTheme.medicalBlue,
                                  size: 24,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: AppTheme.medicalBlue,
                              size: 24,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isFavorite)
                                Icon(
                                  Icons.star_rounded,
                                  color: AppTheme.warningOrange,
                                  size: 16,
                                ),
                              if (isFavorite) const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  doctor.fullName,
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppTheme.medicalBlue
                                        : AppTheme.darkText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            doctor.specialty,
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.mediumText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppTheme.medicalBlue,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarih seçimi
        Text(
          'Tarih',
          style: AppTheme.bodySmall.copyWith(
            color: AppTheme.mediumText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final now = DateTime.now();
            final firstDate = now;
            final lastDate = now.add(const Duration(days: 90));
            
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: _selectedDate ?? now,
              firstDate: firstDate,
              lastDate: lastDate,
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: AppTheme.medicalBlue,
                      onPrimary: AppTheme.white,
                      surface: AppTheme.white,
                      onSurface: AppTheme.darkText,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
                _selectedTime = null;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.inputBackground,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.borderGray.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: AppTheme.medicalBlue,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                        : 'Tarih seçin',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _selectedDate != null
                          ? AppTheme.darkText
                          : AppTheme.mediumText,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppTheme.iconSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        
        // Saat seçimi (Tarih seçildikten sonra)
        if (_selectedDate != null) ...[
          const SizedBox(height: 16),
          Text(
            'Saat',
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.mediumText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _buildTimeSelector(),
        ],
      ],
    );
  }

  Widget _buildTimeSelector() {
    // Mevcut randevuları kontrol et
    final bookedTimes = widget.appointments
        .where((apt) =>
            apt.doctorId == _selectedDoctor?.id &&
            apt.date ==
                '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}' &&
            apt.status != 'cancelled')
        .map((apt) => apt.time)
        .toSet();

    // Çalışma saatleri (örnek: 09:00 - 17:00, 30 dakika aralıklarla)
    final availableTimes = <String>[];
    for (int hour = 9; hour < 18; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final timeString = '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        if (!bookedTimes.contains(timeString)) {
          availableTimes.add(timeString);
        }
      }
    }

    if (availableTimes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundSecondary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppTheme.mediumText),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bu tarihte müsait saat bulunamadı.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.mediumText,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: availableTimes.map((time) {
        final isSelected = _selectedTime == time;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedTime = time;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.medicalBlue
                  : AppTheme.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppTheme.medicalBlue
                    : AppTheme.borderGray.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1.5,
              ),
            ),
            child: Text(
              time,
              style: AppTheme.bodyMedium.copyWith(
                color: isSelected
                    ? AppTheme.white
                    : AppTheme.darkText,
                fontWeight: isSelected
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCreateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.medicalGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.medicalBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateAppointmentScreen(
                  preselectedServiceId: _selectedService!.id,
                  preselectedHospitalId: _selectedHospital!.id,
                  preselectedDoctorId: _selectedDoctor!.id,
                  preselectedDate: _selectedDate,
                  preselectedTime: _selectedTime,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Randevuyu Oluştur',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _compareFavorites(String aId, String bId, Set<String> favorites) {
    final aFav = favorites.contains(aId);
    final bFav = favorites.contains(bId);
    if (aFav == bFav) return 0;
    return aFav ? -1 : 1;
  }
}
