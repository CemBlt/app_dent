import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/service.dart';
import '../models/appointment.dart';
import '../services/json_service.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final String? preselectedHospitalId;
  
  const CreateAppointmentScreen({
    super.key,
    this.preselectedHospitalId,
  });

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  List<Hospital> _allHospitals = [];
  List<Hospital> _filteredHospitals = [];
  List<Doctor> _allDoctors = [];
  List<Doctor> _filteredDoctors = [];
  List<Service> _services = [];
  List<Appointment> _existingAppointments = [];
  
  String? _selectedCity;
  String? _selectedDistrict;
  Hospital? _selectedHospital;
  Doctor? _selectedDoctor;
  Service? _selectedService;
  DateTime? _selectedDate;
  String? _selectedTime;
  final TextEditingController _notesController = TextEditingController();
  
  bool _isLoading = true;
  List<String> _availableTimes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final hospitals = await JsonService.getHospitals();
    final doctors = await JsonService.getDoctors();
    final services = await JsonService.getServices();
    final appointments = await JsonService.getAppointments();

    setState(() {
      _allHospitals = hospitals;
      _allDoctors = doctors;
      _services = services;
      _existingAppointments = appointments;
      
      // Eğer preselectedHospitalId varsa, hastaneyi seç
      if (widget.preselectedHospitalId != null) {
        try {
          final preselectedHospital = hospitals.firstWhere(
            (h) => h.id == widget.preselectedHospitalId,
          );
          // İl ve ilçe bilgilerini ayarla
          final addressInfo = _parseAddress(preselectedHospital.address);
          _selectedCity = addressInfo['city'];
          _selectedDistrict = addressInfo['district'];
          _selectedHospital = preselectedHospital;
          _updateFilteredHospitals();
          _onHospitalSelected(preselectedHospital);
        } catch (e) {
          // Hastane bulunamadı
        }
      }
      
      _isLoading = false;
    });
  }

  // Adres formatından il ve ilçe çıkar (format: "İlçe, İl")
  Map<String, String> _parseAddress(String address) {
    final parts = address.split(',').map((e) => e.trim()).toList();
    if (parts.length >= 2) {
      return {'district': parts[0], 'city': parts[1]};
    }
    return {'district': address, 'city': ''};
  }

  // Tüm illeri getir
  List<String> get _cities {
    final cities = <String>{};
    for (var hospital in _allHospitals) {
      final addressInfo = _parseAddress(hospital.address);
      if (addressInfo['city']!.isNotEmpty) {
        cities.add(addressInfo['city']!);
      }
    }
    return cities.toList()..sort();
  }

  // Seçilen ile göre ilçeleri getir
  List<String> get _districts {
    if (_selectedCity == null) return [];
    
    final districts = <String>{};
    for (var hospital in _allHospitals) {
      final addressInfo = _parseAddress(hospital.address);
      if (addressInfo['city'] == _selectedCity && addressInfo['district']!.isNotEmpty) {
        districts.add(addressInfo['district']!);
      }
    }
    return districts.toList()..sort();
  }

  void _onCitySelected(String? city) {
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedHospital = null;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      _filteredHospitals = [];
      _filteredDoctors = [];
      
      if (city != null) {
        _updateFilteredHospitals();
      }
    });
  }

  void _onDistrictSelected(String? district) {
    setState(() {
      _selectedDistrict = district;
      _selectedHospital = null;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      _filteredDoctors = [];
      
      if (district != null) {
        _updateFilteredHospitals();
      }
    });
  }

  void _updateFilteredHospitals() {
    _filteredHospitals = _allHospitals.where((hospital) {
      final addressInfo = _parseAddress(hospital.address);
      final matchesCity = _selectedCity == null || addressInfo['city'] == _selectedCity;
      final matchesDistrict = _selectedDistrict == null || addressInfo['district'] == _selectedDistrict;
      return matchesCity && matchesDistrict;
    }).toList();
  }

  void _onHospitalSelected(Hospital? hospital) {
    setState(() {
      _selectedHospital = hospital;
      _selectedDoctor = null;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
      
      if (hospital != null) {
        _filteredDoctors = _allDoctors
            .where((doctor) => doctor.hospitalId == hospital.id)
            .toList();
      } else {
        _filteredDoctors = [];
      }
    });
  }

  void _onDoctorSelected(Doctor? doctor) {
    setState(() {
      _selectedDoctor = doctor;
      _selectedDate = null;
      _selectedTime = null;
      _availableTimes = [];
    });
  }

  Future<void> _selectDate() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Önce doktor seçiniz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime firstDate = now;
    final DateTime lastDate = now.add(const Duration(days: 90));

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.tealBlue,
              onPrimary: AppTheme.white,
              surface: AppTheme.white,
              onSurface: AppTheme.darkText,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _selectedTime = null;
        _availableTimes = _getAvailableTimes(picked);
      });
    }
  }

  List<String> _getAvailableTimes(DateTime date) {
    if (_selectedDoctor == null) return [];

    final dayOfWeek = _getDayOfWeek(date.weekday);
    final doctorWorkingHours = _selectedDoctor!.workingHours[dayOfWeek] as Map<String, dynamic>?;
    
    if (doctorWorkingHours == null || doctorWorkingHours['isAvailable'] != true) {
      return [];
    }

    final startTime = doctorWorkingHours['start'] as String?;
    final endTime = doctorWorkingHours['end'] as String?;
    
    if (startTime == null || endTime == null) return [];

    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    
    List<String> times = [];
    DateTime current = start;
    
    while (current.isBefore(end) || current == start) {
      final timeStr = '${current.hour.toString().padLeft(2, '0')}:${current.minute.toString().padLeft(2, '0')}';
      
      // Dolu saatleri kontrol et
      if (!_isTimeBooked(date, timeStr)) {
        times.add(timeStr);
      }
      
      current = current.add(const Duration(minutes: 30));
      if (current.isAfter(end)) break;
    }
    
    return times;
  }

  bool _isTimeBooked(DateTime date, String time) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    
    return _existingAppointments.any((apt) {
      return apt.date == dateStr &&
          apt.time == time &&
          apt.doctorId == _selectedDoctor?.id &&
          apt.status != 'cancelled';
    });
  }

  DateTime _parseTime(String time) {
    final parts = time.split(':');
    return DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
  }

  String _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool _isFormValid() {
    return _selectedCity != null &&
        _selectedDistrict != null &&
        _selectedHospital != null &&
        _selectedDoctor != null &&
        _selectedService != null &&
        _selectedDate != null &&
        _selectedTime != null;
  }

  void _createAppointment() {
    if (!_isFormValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lütfen tüm alanları doldurunuz'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Randevu oluşturma işlemi (şimdilik sadece mesaj)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Randevu başarıyla oluşturuldu'),
        backgroundColor: AppTheme.successGreen,
      ),
    );

    // Geri dön
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _notesController.dispose();
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
                              'Randevu Oluştur',
                              style: AppTheme.headingLarge.copyWith(
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Container(
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
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // İl Seçimi
                                Text(
                                  'İl',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStringDropdown(
                                  value: _selectedCity,
                                  items: _cities,
                                  onChanged: _onCitySelected,
                                  hint: 'İl seçiniz',
                                ),
                                const SizedBox(height: 20),
                                // İlçe Seçimi
                                Text(
                                  'İlçe',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildStringDropdown(
                                  value: _selectedDistrict,
                                  items: _districts,
                                  onChanged: _onDistrictSelected,
                                  hint: 'İlçe seçiniz',
                                  enabled: _selectedCity != null,
                                ),
                                const SizedBox(height: 20),
                                // Hastane Seçimi
                                Text(
                                  'Hastane',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDropdown<Hospital>(
                                  value: _selectedHospital,
                                  items: _filteredHospitals,
                                  onChanged: _onHospitalSelected,
                                  getLabel: (hospital) => hospital.name,
                                  enabled: _selectedDistrict != null,
                                ),
                                const SizedBox(height: 20),
                                // Doktor Seçimi
                                Text(
                                  'Doktor',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDropdown<Doctor>(
                                  value: _selectedDoctor,
                                  items: _filteredDoctors,
                                  onChanged: _onDoctorSelected,
                                  getLabel: (doctor) => '${doctor.fullName} - ${doctor.specialty}',
                                  enabled: _selectedHospital != null,
                                ),
                                const SizedBox(height: 20),
                                // Hizmet Seçimi
                                Text(
                                  'Hizmet',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDropdown<Service>(
                                  value: _selectedService,
                                  items: _services,
                                  onChanged: (service) {
                                    setState(() {
                                      _selectedService = service;
                                    });
                                  },
                                  getLabel: (service) => service.name,
                                ),
                                const SizedBox(height: 20),
                                // Tarih Seçimi
                                Text(
                                  'Tarih',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDatePicker(),
                                const SizedBox(height: 20),
                                // Saat Seçimi
                                Text(
                                  'Saat',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildTimeDropdown(),
                                const SizedBox(height: 20),
                                // Notlar
                                Text(
                                  'Notlar (Opsiyonel)',
                                  style: AppTheme.bodyMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _notesController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Randevu ile ilgili notlarınızı yazabilirsiniz...',
                                    hintStyle: TextStyle(color: AppTheme.iconGray),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppTheme.dividerLight),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(color: AppTheme.dividerLight),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(color: AppTheme.tealBlue, width: 2),
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Randevu Oluştur Butonu
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: _isFormValid()
                              ? const LinearGradient(
                                  colors: [AppTheme.tealBlue, AppTheme.deepCyan],
                                )
                              : null,
                          color: _isFormValid() ? null : AppTheme.iconGray,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: _isFormValid()
                              ? [
                                  BoxShadow(
                                    color: AppTheme.tealBlue.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _isFormValid() ? _createAppointment : null,
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: AppTheme.white,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Randevu Oluştur',
                                    style: AppTheme.headingSmall.copyWith(
                                      color: AppTheme.white,
                                    ),
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
        ),
      ),
    );
  }

  Widget _buildStringDropdown({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppTheme.dividerLight : AppTheme.iconGray.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(
              item,
              style: AppTheme.bodyMedium,
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.iconGray),
        ),
        style: AppTheme.bodyMedium,
        dropdownColor: AppTheme.white,
        icon: Icon(Icons.arrow_drop_down, color: enabled ? AppTheme.tealBlue : AppTheme.iconGray),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    required String Function(T) getLabel,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppTheme.dividerLight : AppTheme.iconGray.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              getLabel(item),
              style: AppTheme.bodyMedium,
            ),
          );
        }).toList(),
        onChanged: enabled ? onChanged : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: 'Seçiniz...',
          hintStyle: TextStyle(color: AppTheme.iconGray),
        ),
        style: AppTheme.bodyMedium,
        dropdownColor: AppTheme.white,
        icon: Icon(Icons.arrow_drop_down, color: enabled ? AppTheme.tealBlue : AppTheme.iconGray),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.inputFieldGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _selectedDoctor != null ? _selectDate : null,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: _selectedDoctor != null
                      ? AppTheme.tealBlue
                      : AppTheme.iconGray,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDate != null
                        ? _formatDate(_selectedDate!)
                        : 'Tarih seçiniz',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _selectedDate != null
                          ? AppTheme.darkText
                          : AppTheme.iconGray,
                    ),
                  ),
                ),
                if (_selectedDate != null)
                  IconButton(
                    icon: Icon(Icons.clear, size: 18, color: AppTheme.iconGray),
                    onPressed: () {
                      setState(() {
                        _selectedDate = null;
                        _selectedTime = null;
                        _availableTimes = [];
                      });
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: _selectedDate != null && _availableTimes.isNotEmpty
            ? AppTheme.inputFieldGray
            : AppTheme.inputFieldGray.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedDate != null && _availableTimes.isNotEmpty
              ? AppTheme.dividerLight
              : AppTheme.iconGray.withOpacity(0.3),
        ),
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedTime,
        items: _availableTimes.map((time) {
          return DropdownMenuItem<String>(
            value: time,
            child: Text(time, style: AppTheme.bodyMedium),
          );
        }).toList(),
        onChanged: _selectedDate != null && _availableTimes.isNotEmpty
            ? (value) {
                setState(() {
                  _selectedTime = value;
                });
              }
            : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          hintText: _selectedDate == null
              ? 'Önce tarih seçiniz'
              : _availableTimes.isEmpty
                  ? 'Uygun saat bulunamadı'
                  : 'Saat seçiniz',
          hintStyle: TextStyle(color: AppTheme.iconGray),
        ),
        style: AppTheme.bodyMedium,
        dropdownColor: AppTheme.white,
        icon: Icon(
          Icons.access_time,
          color: _selectedDate != null && _availableTimes.isNotEmpty
              ? AppTheme.tealBlue
              : AppTheme.iconGray,
        ),
      ),
    );
  }
}

