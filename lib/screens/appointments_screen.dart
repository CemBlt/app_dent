import 'package:flutter/material.dart';

import '../models/appointment.dart';
import '../models/doctor.dart';
import '../models/hospital.dart';
import '../models/service.dart';
import '../services/json_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  List<Appointment> _appointments = [];
  List<Hospital> _hospitals = [];
  List<Doctor> _doctors = [];
  List<Service> _services = [];
  bool _isLoading = true;
  int _selectedTab = 0; // 0: Bekleyen, 1: Geçmiş

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!AuthService.isAuthenticated) {
      setState(() {
        _appointments = [];
        _hospitals = [];
        _doctors = [];
        _services = [];
        _isLoading = false;
      });
      return;
    }

    final userId = AuthService.currentUserId;
    if (userId == null) {
      setState(() {
        _appointments = [];
        _hospitals = [];
        _doctors = [];
        _services = [];
        _isLoading = false;
      });
      return;
    }

    final appointments = await JsonService.getUserAppointments(userId);
    final hospitals = await JsonService.getHospitals();
    final doctors = await JsonService.getDoctors();
    final services = await JsonService.getServices();

    setState(() {
      _appointments = appointments;
      _hospitals = hospitals;
      _doctors = doctors;
      _services = services;
      _isLoading = false;
    });
  }

  List<Appointment> get _pendingAppointments {
    return _appointments.where((apt) => apt.status == 'pending').toList()
      ..sort((a, b) {
        final dateA = DateTime.parse('${a.date} ${a.time}');
        final dateB = DateTime.parse('${b.date} ${b.time}');
        return dateA.compareTo(dateB);
      });
  }

  List<Appointment> get _pastAppointments {
    return _appointments
        .where((apt) => apt.status == 'completed' || apt.status == 'cancelled')
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.parse('${a.date} ${a.time}');
        final dateB = DateTime.parse('${b.date} ${b.time}');
        return dateB.compareTo(dateA);
      });
  }

  Hospital? _getHospital(String hospitalId) {
    try {
      return _hospitals.firstWhere((h) => h.id == hospitalId);
    } catch (e) {
      return null;
    }
  }

  Doctor? _getDoctor(String doctorId) {
    try {
      return _doctors.firstWhere((d) => d.id == doctorId);
    } catch (e) {
      return null;
    }
  }

  Service? _getService(String serviceId) {
    try {
      return _services.firstWhere((s) => s.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'completed':
        return 'Tamamlandı';
      case 'cancelled':
        return 'İptal Edildi';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppTheme.warningOrange;
      case 'completed':
        return AppTheme.successGreen;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.grayText;
    }
  }

  void _cancelAppointment(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Randevuyu İptal Et', style: AppTheme.headingSmall),
        content: Text(
          'Bu randevuyu iptal etmek istediğinize emin misiniz?',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hayır',
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.grayText),
            ),
          ),
          TextButton(
            onPressed: () {
              // İptal işlemi (şimdilik sadece UI'dan kaldır)
              setState(() {
                _appointments.removeWhere((apt) => apt.id == appointment.id);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Randevu iptal edildi'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            },
            child: Text(
              'Evet',
              style: AppTheme.bodyMedium.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
                          Text(
                            'Randevularım',
                            style: AppTheme.headingLarge.copyWith(
                              color: AppTheme.darkText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Tab Bar
                    Container(
                      color: AppTheme.white,
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildTabButton(
                              0,
                              'Bekleyen',
                              _pendingAppointments.length,
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              1,
                              'Geçmiş',
                              _pastAppointments.length,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // List
                    Expanded(
                      child: !AuthService.isAuthenticated
                          ? _buildNotLoggedInView()
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: _selectedTab == 0
                                  ? _buildAppointmentsList(_pendingAppointments)
                                  : _buildAppointmentsList(_pastAppointments),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String label, int count) {
    final isSelected = _selectedTab == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTab = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? AppTheme.tealBlue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: AppTheme.bodyMedium.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.tealBlue : AppTheme.grayText,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.tealBlue.withOpacity(0.1)
                      : AppTheme.iconGray.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  count.toString(),
                  style: AppTheme.bodySmall.copyWith(
                    color: isSelected ? AppTheme.tealBlue : AppTheme.grayText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotLoggedInView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 64,
              color: AppTheme.iconGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Giriş Yapın',
              style: AppTheme.headingMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Randevularınızı görmek için giriş yapın',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.grayText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(
                      onLoginSuccess: () {
                        Navigator.pop(context);
                        _loadData();
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tealBlue,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Giriş Yap',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsList(List<Appointment> appointments) {
    if (appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: AppTheme.iconGray,
            ),
            const SizedBox(height: 16),
            Text(
              'Randevu bulunamadı',
              style: AppTheme.bodyLarge.copyWith(color: AppTheme.grayText),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildAppointmentCard(appointment);
      },
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final hospital = _getHospital(appointment.hospitalId);
    final doctor = _getDoctor(appointment.doctorId);
    final service = _getService(appointment.service);

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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(appointment.status),
                    style: AppTheme.bodySmall.copyWith(
                      color: _getStatusColor(appointment.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (appointment.status == 'pending')
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: AppTheme.iconGray),
                    onPressed: () {
                      _showAppointmentOptions(appointment);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Tarih ve Saat
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: AppTheme.tealBlue),
                const SizedBox(width: 8),
                Text(
                  _formatDate(appointment.date),
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.access_time, size: 18, color: AppTheme.tealBlue),
                const SizedBox(width: 8),
                Text(
                  appointment.time,
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Hastane
            if (hospital != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.local_hospital,
                    size: 18,
                    color: AppTheme.iconGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(hospital.name, style: AppTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Doktor
            if (doctor != null) ...[
              Row(
                children: [
                  Icon(Icons.person, size: 18, color: AppTheme.iconGray),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${doctor.fullName} - ${doctor.specialty}',
                      style: AppTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Hizmet
            if (service != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 18,
                    color: AppTheme.iconGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(service.name, style: AppTheme.bodyMedium),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            // Notlar
            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.note, size: 16, color: AppTheme.iconGray),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(appointment.notes, style: AppTheme.bodySmall),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAppointmentOptions(Appointment appointment) {
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
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.tealBlue),
              title: Text('Düzenle', style: AppTheme.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                // Düzenleme sayfasına yönlendirme
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: Text('İptal Et', style: AppTheme.bodyMedium),
              onTap: () {
                Navigator.pop(context);
                _cancelAppointment(appointment);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final dateTime = DateTime.parse(date);
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
        'Aralık',
      ];
      return '${dateTime.day} ${months[dateTime.month - 1]} ${dateTime.year}';
    } catch (e) {
      return date;
    }
  }
}
