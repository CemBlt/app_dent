import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../services/json_service.dart';
import 'doctor_detail_screen.dart';

class AllDoctorsScreen extends StatefulWidget {
  const AllDoctorsScreen({super.key});

  @override
  State<AllDoctorsScreen> createState() => _AllDoctorsScreenState();
}

class _AllDoctorsScreenState extends State<AllDoctorsScreen> {
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  List<Hospital> _hospitals = [];
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'rating'; // rating, name, specialty
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doctors = await JsonService.getDoctors();
    final hospitals = await JsonService.getHospitals();

    // İlk 20 doktoru al
    final limitedDoctors = doctors.take(20).toList();

    setState(() {
      _allDoctors = limitedDoctors;
      _hospitals = hospitals;
      _filteredDoctors = limitedDoctors;
      _isLoading = false;
    });
    _applySorting();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDoctors = _allDoctors;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredDoctors = _allDoctors.where((doctor) {
          final hospital = _getHospitalByDoctor(doctor);
          return doctor.fullName.toLowerCase().contains(lowerQuery) ||
              doctor.specialty.toLowerCase().contains(lowerQuery) ||
              (hospital != null && hospital.name.toLowerCase().contains(lowerQuery));
        }).toList();
      }
      _applySorting();
    });
  }

  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'rating':
          // Şimdilik sabit puan kullanıyoruz, gerçek puan sistemi eklendiğinde güncellenir
          _filteredDoctors.sort((a, b) => b.fullName.compareTo(a.fullName));
          break;
        case 'name':
          _filteredDoctors.sort((a, b) => a.fullName.compareTo(b.fullName));
          break;
        case 'specialty':
          _filteredDoctors.sort((a, b) => a.specialty.compareTo(b.specialty));
          break;
      }
    });
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sıralama',
              style: AppTheme.headingSmall,
            ),
            const SizedBox(height: 20),
            _buildSortOption('rating', 'En Yüksek Puan', Icons.star),
            _buildSortOption('name', 'Alfabetik', Icons.sort_by_alpha),
            _buildSortOption('specialty', 'Uzmanlık', Icons.medical_services),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.tealBlue : AppTheme.iconGray),
      title: Text(
        label,
        style: AppTheme.bodyMedium.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.tealBlue : AppTheme.darkText,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppTheme.tealBlue)
          : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        _applySorting();
        Navigator.pop(context);
      },
    );
  }

  String _getSortLabel() {
    switch (_sortBy) {
      case 'rating':
        return 'En Yüksek Puan';
      case 'name':
        return 'Alfabetik';
      case 'specialty':
        return 'Uzmanlık';
      default:
        return 'Sırala';
    }
  }

  Hospital? _getHospitalByDoctor(Doctor doctor) {
    try {
      return _hospitals.firstWhere((h) => h.id == doctor.hospitalId);
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.lightTurquoise,
                            AppTheme.mediumTurquoise,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Popüler Doktorlar',
                              style: AppTheme.headingLarge.copyWith(
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Arama ve Sıralama
                    Container(
                      color: AppTheme.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Arama Kutusu
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.inputFieldGray,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Doktor ara...',
                                hintStyle: TextStyle(color: AppTheme.iconGray),
                                prefixIcon: Icon(Icons.search, color: AppTheme.iconGray),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.clear, color: AppTheme.iconGray),
                                        onPressed: () {
                                          setState(() {
                                            _searchController.clear();
                                            _onSearchChanged('');
                                          });
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                              ),
                              onChanged: _onSearchChanged,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Sıralama Butonu
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppTheme.lightTurquoise,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: _showSortOptions,
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.sort,
                                              color: AppTheme.tealBlue,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _getSortLabel(),
                                              style: AppTheme.bodyMedium.copyWith(
                                                color: AppTheme.tealBlue,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.arrow_drop_down,
                                              color: AppTheme.tealBlue,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Doktor Listesi
                    Expanded(
                      child: _filteredDoctors.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 64,
                                    color: AppTheme.iconGray,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Doktor bulunamadı',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: AppTheme.grayText,
                                    ),
                                  ),
                                  if (_searchController.text.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Arama kriterlerinizi değiştirmeyi deneyin',
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.grayText,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _filteredDoctors.length,
                                itemBuilder: (context, index) {
                                  final doctor = _filteredDoctors[index];
                                  return _buildDoctorCard(doctor);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final hospital = _getHospitalByDoctor(doctor);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorDetailScreen(
                  doctor: doctor,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Doktor Fotoğrafı
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.lightTurquoise,
                    shape: BoxShape.circle,
                  ),
                  child: doctor.image != null
                      ? ClipOval(
                          child: Image.asset(
                            doctor.image!,
                            fit: BoxFit.cover,
                            width: 80,
                            height: 80,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.person,
                                size: 40,
                                color: AppTheme.tealBlue,
                              );
                            },
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 40,
                          color: AppTheme.tealBlue,
                        ),
                ),
                const SizedBox(width: 16),
                // Doktor Bilgileri
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        doctor.fullName,
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.medical_services,
                            size: 14,
                            color: AppTheme.iconGray,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              doctor.specialty,
                              style: AppTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (hospital != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.local_hospital,
                              size: 14,
                              color: AppTheme.iconGray,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                hospital.name,
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.grayText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 14,
                            color: AppTheme.accentYellow,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: AppTheme.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.iconGray,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

