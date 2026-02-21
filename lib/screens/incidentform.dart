import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'report_detail_page.dart';

class IncidentFormPage extends StatefulWidget {
  final File imageFile;

  const IncidentFormPage({super.key, required this.imageFile});

  @override
  State<IncidentFormPage> createState() => _IncidentFormPageState();
}

class _IncidentFormPageState extends State<IncidentFormPage> {
  final _incidentCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _urgency = 'low';
  bool _submitting = false;

  double? _lat;
  double? _lng;
  String _addressText = '';

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  @override
  void dispose() {
    _incidentCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() => _addressText = 'Location service disabled');
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _addressText = 'Location permission denied');
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _lat = pos.latitude;
      _lng = pos.longitude;

      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      final p = placemarks.isNotEmpty ? placemarks.first : null;

      final text = p == null
          ? 'Unknown location'
          : [
              if ((p.street ?? '').trim().isNotEmpty) p.street,
              if ((p.locality ?? '').trim().isNotEmpty) p.locality,
              if ((p.administrativeArea ?? '').trim().isNotEmpty)
                p.administrativeArea,
            ].whereType<String>().join(', ');

      if (!mounted) return;
      setState(() => _addressText = text.isEmpty ? 'Unknown location' : text);
    } catch (_) {
      if (!mounted) return;
      setState(() => _addressText = 'Unable to detect location');
    }
  }

  /// ✅ Upload to Supabase bucket that matches your screenshot:
  /// bucket: "incidents"
  /// path: "images/incidents/<timestamp>.jpg"
  Future<String> _uploadToSupabase(File file) async {
    final supabase = Supabase.instance.client;
    final bytes = await file.readAsBytes();

    final filePath =
        'images/incidents/${DateTime.now().millisecondsSinceEpoch}.jpg';

    await supabase.storage
        .from('incidents')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: false,
          ),
        );

    return supabase.storage.from('incidents').getPublicUrl(filePath);
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _show('You must be logged in.');
      return;
    }
    if (_submitting) return;

    final name = _incidentCtrl.text.trim();
    final desc = _descCtrl.text.trim();

    if (name.isEmpty) {
      _show('Incident name is required.');
      return;
    }
    if (_lat == null || _lng == null) {
      _show('Location is required. Please enable GPS and try again.');
      return;
    }

    setState(() => _submitting = true);

    try {
      // optional profile fields (safe even if missing)
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() ?? <String, dynamic>{};

      final citizenName = (userData['fullName'] ?? '').toString();
      final citizenPhone = (userData['phone'] ?? '').toString();

      final imageUrl = await _uploadToSupabase(widget.imageFile);

      // ✅ Save to "incidents" collection (matches your screenshot)
      final ref = FirebaseFirestore.instance.collection('incidents').doc();
      final now = FieldValue.serverTimestamp();

      await ref.set({
        // IDs / owner
        'incidentId': ref.id,
        'citizenUid': user.uid,
        'citizenName': citizenName,
        'citizenPhone': citizenPhone,

        // screenshot fields
        'name': name,
        'description': desc,
        'address': _addressText,
        'imageUrl': imageUrl,
        'latitude': _lat,
        'longitude': _lng,

        // progress fields (screenshot)
        'progress': {'accepted': false, 'onAction': false},

        // optional extra fields (safe for admin dashboard use)
        'urgency': _urgency,
        'status': 'pending',

        'createdAt': now,
        'updatedAt': now,
      });

      // ✅ timeline subcollection (your screenshot shows "timeline")
      await ref.collection('timeline').add({
        'type': 'created',
        'message': 'Citizen submitted an incident.',
        'createdAt': now,
        'createdByUid': user.uid,
        'createdByRole': 'citizen',
      });

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ReportDetailPage(reportId: ref.id, viewerRole: 'citizen'),
        ),
      );
    } catch (e) {
      _show('Submit failed: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _show(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1F3A),
        foregroundColor: Colors.white,
        title: const Text('Report Incident'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(widget.imageFile, height: 220, fit: BoxFit.cover),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _incidentCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: _dec('Incident name', Icons.report),
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            value: _urgency,
            decoration: _dec('Urgency level', Icons.priority_high),
            dropdownColor: const Color(0xFF1A1F3A),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low')),
              DropdownMenuItem(value: 'medium', child: Text('Medium')),
              DropdownMenuItem(value: 'high', child: Text('High')),
              DropdownMenuItem(value: 'critical', child: Text('Critical')),
            ],
            onChanged: (v) => setState(() => _urgency = v ?? 'low'),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F3A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _addressText.isEmpty
                        ? 'Detecting location...'
                        : _addressText,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                IconButton(
                  onPressed: _loadLocation,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _descCtrl,
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: _dec(
              'Description (optional)',
              Icons.description_outlined,
            ),
          ),
          const SizedBox(height: 18),

          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _submitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Report'),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
    prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.7)),
    filled: true,
    fillColor: const Color(0xFF1A1F3A),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
  );
}
