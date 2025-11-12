import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/hospital.dart';
import '../models/doctor.dart';
import '../models/tip.dart';
import '../models/appointment.dart';
import '../models/service.dart';
import '../models/user.dart';

class JsonService {
  // Hastaneleri getir
  static Future<List<Hospital>> getHospitals() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/hospitals.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Hospital.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Doktorları getir
  static Future<List<Doctor>> getDoctors() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/doctors.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Doctor.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Belirli bir hastanenin doktorlarını getir
  static Future<List<Doctor>> getDoctorsByHospital(String hospitalId) async {
    final allDoctors = await getDoctors();
    return allDoctors.where((doctor) => doctor.hospitalId == hospitalId).toList();
  }

  // Popüler doktorları getir (örnek: ilk 4 doktor)
  static Future<List<Doctor>> getPopularDoctors() async {
    final allDoctors = await getDoctors();
    return allDoctors.take(4).toList();
  }

  // İpuçlarını getir
  static Future<List<Tip>> getTips() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/tips.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Tip.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Hastane ara
  static Future<List<Hospital>> searchHospitals(String query) async {
    final allHospitals = await getHospitals();
    if (query.isEmpty) return allHospitals;
    
    final lowerQuery = query.toLowerCase();
    return allHospitals.where((hospital) {
      return hospital.name.toLowerCase().contains(lowerQuery) ||
          hospital.address.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Randevuları getir
  static Future<List<Appointment>> getAppointments() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/appointments.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Appointment.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Kullanıcının randevularını getir
  static Future<List<Appointment>> getUserAppointments(String userId) async {
    final allAppointments = await getAppointments();
    return allAppointments
        .where((appointment) => appointment.userId == userId)
        .toList();
  }

  // Hizmetleri getir
  static Future<List<Service>> getServices() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/services.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => Service.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Hizmet getir
  static Future<Service?> getService(String serviceId) async {
    final allServices = await getServices();
    try {
      return allServices.firstWhere((service) => service.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  // Kullanıcıları getir
  static Future<List<User>> getUsers() async {
    try {
      final String response =
          await rootBundle.loadString('assets/data/users.json');
      final List<dynamic> data = json.decode(response);
      return data.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  // Kullanıcı getir
  static Future<User?> getUser(String userId) async {
    final allUsers = await getUsers();
    try {
      return allUsers.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }
}


