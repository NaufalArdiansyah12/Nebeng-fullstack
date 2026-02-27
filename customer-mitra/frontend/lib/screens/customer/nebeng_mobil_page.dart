import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'nebeng_mobil/widgets/form_section.dart';
import 'nebeng_mobil/widgets/history_section.dart';
import 'nebeng_mobil/pages/location_picker_page.dart';
import '../../services/api_service.dart';
import '../../widgets/custom_calendar_widget.dart';
import 'nebeng_mobil/pages/trip_list_page.dart';
import 'nebeng_mobil/utils/theme.dart';

class NebengMobilPage extends StatefulWidget {
  const NebengMobilPage({Key? key}) : super(key: key);

  @override
  State<NebengMobilPage> createState() => _NebengMobilPageState();
}

class _NebengMobilPageState extends State<NebengMobilPage> {
  String? lokasiAwal;
  String? lokasiAwalAddress;
  int? lokasiAwalId;
  String? lokasiTujuan;
  String? lokasiTujuanAddress;
  int? lokasiTujuanId;
  DateTime? tanggalKeberangkatan;
  List<Map<String, String>> _addressHistory = [];
  bool _loadingHistory = false;
  @override

  void initState() {
    super.initState();
    _loadAddressHistory();
  }

  Future<void> _loadAddressHistory() async {
    setState(() {
      _loadingHistory = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token != null && token.isNotEmpty) {
        final bookings = await ApiService.fetchBookings(
          token: token,
          type: 'mobil',
        );

        // Extract unique locations from last bookings
        final Set<String> seenAddresses = {};
        final List<Map<String, String>> history = [];

        for (var booking in bookings) {
          final ride = booking['ride'] ?? {};

          // Get origin
          final originName = ride['origin'] ?? '';
          final originAddress = ride['origin_address'] ?? '';
          if (originName.isNotEmpty && !seenAddresses.contains(originName)) {
            history.add({
              'name': originName.toString(),
              'address': originAddress.toString(),
            });
            seenAddresses.add(originName);
          }

          // Get destination
          final destName = ride['destination'] ?? '';
          final destAddress = ride['destination_address'] ?? '';
          if (destName.isNotEmpty && !seenAddresses.contains(destName)) {
            history.add({
              'name': destName.toString(),
              'address': destAddress.toString(),
            });
            seenAddresses.add(destName);
          }

          // Limit to 5 most recent unique addresses
          if (history.length >= 5) break;
        }

        setState(() {
          _addressHistory = history;
          _loadingHistory = false;
        });
      } else {
        setState(() {
          _addressHistory = [];
          _loadingHistory = false;
        });
      }
    } catch (e) {
      print('Error loading address history: $e');
      setState(() {
        _addressHistory = [];
        _loadingHistory = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NebengMobilTheme.primaryBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: NebengMobilTheme.backgroundColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      FormSection(
                        lokasiAwal: lokasiAwal,
                        lokasiAwalAddress: lokasiAwalAddress,
                        lokasiTujuan: lokasiTujuan,
                        lokasiTujuanAddress: lokasiTujuanAddress,
                        tanggalKeberangkatan: tanggalKeberangkatan,
                        onLokasiAwalTap: () => _showLocationPicker(true),
                        onLokasiTujuanTap: () => _showLocationPicker(false),
                        onTanggalTap: _showDatePicker,
                      ),
                      const SizedBox(height: 24),
                      if (_loadingHistory)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_addressHistory.isNotEmpty)
                        HistorySection(
                          historiAlamat: _addressHistory,
                          onHistoryTap: _showHistorySelectionDialog,
                        ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      color: NebengMobilTheme.backgroundColor,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleNextButton,
            style: ElevatedButton.styleFrom(
              backgroundColor: NebengMobilTheme.primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'next_button'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed: () => Navigator.pop(context),
              color: NebengMobilTheme.primaryBlue,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'nebeng_mobil'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(bool isStartLocation) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final raw = await ApiService.fetchLocations();
      final daftar = raw
          .map((e) => {
                'id': e['id'],
                'name': e['name']?.toString() ?? '',
                'address': (e['address'] ?? e['city'] ?? '').toString(),
              })
          .toList();
      Navigator.pop(context);

      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        MaterialPageRoute(
          builder: (context) => LocationPickerPage(
            title: isStartLocation
                ? 'select_city_or_post_origin'.tr()
                : 'select_city_or_post'.tr(),
            daftarLokasi: daftar,
            onLocationSelected: (location) {},
          ),
        ),
      );

      if (result != null) {
        setState(() {
          if (isStartLocation) {
            lokasiAwal = result['name'];
            lokasiAwalAddress = result['address'];
            lokasiAwalId = result['id'];
          } else {
            lokasiTujuan = result['name'];
            lokasiTujuanAddress = result['address'];
            lokasiTujuanId = result['id'];
          }
        });
      }
    } catch (e) {
      Navigator.pop(context);
      final useSample = await _showFetchErrorDialog(e.toString());
      if (useSample) {
        final daftar = [
          {
            'id': 1,
            'name': 'Terminal Blok M - Jakarta',
            'address': 'Jl. Blok M No.1'
          },
          {
            'id': 2,
            'name': 'Stasiun Gambir - Jakarta',
            'address': 'Jl. Stasiun Gambir'
          },
          {
            'id': 3,
            'name': 'Stasiun Bandung - Bandung',
            'address': 'Jl. Stasiun Bandung'
          },
        ];
        final result = await Navigator.of(context).push<Map<String, dynamic>>(
          MaterialPageRoute(
            builder: (context) => LocationPickerPage(
              title: isStartLocation
                  ? 'select_city_or_post_origin'.tr()
                  : 'select_city_or_post'.tr(),
              daftarLokasi: daftar,
              onLocationSelected: (location) {},
            ),
          ),
        );

        if (result != null) {
          setState(() {
            if (isStartLocation) {
              lokasiAwal = result['name'];
              lokasiAwalAddress = result['address'];
              lokasiAwalId = result['id'];
            } else {
              lokasiTujuan = result['name'];
              lokasiTujuanAddress = result['address'];
              lokasiTujuanId = result['id'];
            }
          });
        }
      }
    }
  }

  Future<bool> _showFetchErrorDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('failed_to_get_location'.tr()),
            content: Text(
                'error_fetching_locations'.tr(namedArgs: {'message': message})),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('use_example'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showDatePicker() async {
    final picked = await showModalBottomSheet<DateTime?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Wrap(
            children: [
              CustomCalendarWidget(
                initialDate: tanggalKeberangkatan ?? DateTime.now(),
                selectedDate: tanggalKeberangkatan,
                disablePast: true,
              ),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        tanggalKeberangkatan = picked;
      });
    }
  }

  void _showHistorySelectionDialog(Map<String, String> location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('select_location_as'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: NebengMobilTheme.greenIcon.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: NebengMobilTheme.greenIcon,
                    size: 20,
                  ),
                ),
                title: Text('starting_location'.tr()),
                onTap: () {
                  setState(() {
                    lokasiAwal = location['name'];
                    lokasiAwalAddress = location['address'];
                  });
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: NebengMobilTheme.orangeIcon.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: NebengMobilTheme.orangeIcon,
                    size: 20,
                  ),
                ),
                title: Text('destination_location'.tr()),
                onTap: () {
                  setState(() {
                    lokasiTujuan = location['name'];
                    lokasiTujuanAddress = location['address'];
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleNextButton() {
    if (lokasiAwal == null ||
        lokasiTujuan == null ||
        tanggalKeberangkatan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('please_complete_all_data'.tr()),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TripListPage(
          lokasiAwal: lokasiAwal!,
          lokasiTujuan: lokasiTujuan!,
          tanggalKeberangkatan: tanggalKeberangkatan!,
          originLocationId: lokasiAwalId,
          destinationLocationId: lokasiTujuanId,
        ),
      ),
    );
  }
}
