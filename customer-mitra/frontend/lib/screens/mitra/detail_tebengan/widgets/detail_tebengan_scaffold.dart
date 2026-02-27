import 'package:flutter/material.dart';
import '../../widgets/mitra_service_type_badge.dart';
import '../widgets/header_card.dart';
import '../widgets/info_mitra_card.dart';
import '../widgets/penumpang_motor_section.dart';
import '../widgets/penumpang_mobil_section.dart';
import '../widgets/penumpang_barang_section.dart';
import '../widgets/penumpang_titip_barang_section.dart';
import '../widgets/customer_rating_section.dart';
import '../widgets/qr_code_section.dart';
import '../../mitra_tracking_map/models/tracking_state.dart';

class DetailTebenganScaffold extends StatelessWidget {
  final Map<String, dynamic> item;
  final TrackingState state;
  final String headerDate;
  final String kode;
  final String statusLabel;
  final Color statusBgColor;
  final String origin;
  final String destination;
  final String incomeLabel;
  final dynamic income;
  final String Function(dynamic) formatPrice;
  final String ownerName;
  final String transportasi;
  final String plat;
  final String vehicleModel;
  final String warna;
  final String kursi;
  final String rideType;
  final Map<String, dynamic> ride;
  final VoidCallback onMarkMenujuPenjemputan;
  final Function(Map<String, dynamic>) onChatPressed;
  final VoidCallback onCancelRide;
  final bool isCheckingRating;
  final bool hasRating;
  final int selectedRating;
  final Set<String> selectedFeedback;
  final dynamic proofImage;
  final bool isSubmittingRating;
  final String customerName;
  final List<String> feedbackOptions;
  final Function(int) onRatingChanged;
  final Function(String) onFeedbackToggled;
  final VoidCallback onPickImage;
  final VoidCallback onSubmitRating;
  final String currentStatus;

  const DetailTebenganScaffold({
    Key? key,
    required this.item,
    required this.state,
    required this.headerDate,
    required this.kode,
    required this.statusLabel,
    required this.statusBgColor,
    required this.origin,
    required this.destination,
    required this.incomeLabel,
    required this.income,
    required this.formatPrice,
    required this.ownerName,
    required this.transportasi,
    required this.plat,
    required this.vehicleModel,
    required this.warna,
    required this.kursi,
    required this.rideType,
    required this.ride,
    required this.onMarkMenujuPenjemputan,
    required this.onChatPressed,
    required this.onCancelRide,
    required this.isCheckingRating,
    required this.hasRating,
    required this.selectedRating,
    required this.selectedFeedback,
    required this.proofImage,
    required this.isSubmittingRating,
    required this.customerName,
    required this.feedbackOptions,
    required this.onRatingChanged,
    required this.onFeedbackToggled,
    required this.onPickImage,
    required this.onSubmitRating,
    required this.currentStatus,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context)),
        title: const Text('Detail Tebengan',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 18)),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: Colors.grey[200],
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeaderCard(
                headerDate: headerDate,
                kode: kode,
                statusLabel: statusLabel,
                statusBgColor: statusBgColor,
                origin: origin,
                destination: destination,
                incomeLabel: incomeLabel,
                income: income,
                formatPrice: formatPrice,
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              // Show "Mulai Tebengan" button for status paid
              Builder(builder: (context) {
                final status = (ride['status'] ?? '').toString().toLowerCase();

                if (status == 'paid') {
                  // Compute departure readiness also from ride's date/time as a fallback
                  bool effectiveIsDepartureReady = state.isDepartureReady;
                  try {
                    final departureDate =
                        ride['departure_date']?.toString() ?? '';
                    final departureTime =
                        ride['departure_time']?.toString() ?? '';
                    if (departureDate.isNotEmpty && departureTime.isNotEmpty) {
                      // Try robust parsing first
                      DateTime? dt =
                          DateTime.tryParse('$departureDate $departureTime');
                      if (dt == null) {
                        // Fallback: try ISO-like with 'T' between date and time
                        dt = DateTime.tryParse(
                            '${departureDate}T$departureTime');
                      }
                      if (dt == null) {
                        // Last resort: manual split parsing
                        final dateParts = departureDate.split('-');
                        final timeParts = departureTime.split(':');
                        if (dateParts.length >= 3 && timeParts.length >= 2) {
                          dt = DateTime(
                            int.parse(dateParts[0]),
                            int.parse(dateParts[1]),
                            int.parse(dateParts[2]),
                            int.parse(timeParts[0]),
                            int.parse(timeParts[1]),
                          );
                        }
                      }
                      if (dt != null) {
                        effectiveIsDepartureReady = effectiveIsDepartureReady ||
                            !dt.isAfter(DateTime.now());
                      }
                    }
                  } catch (_) {
                    // ignore parse errors and fall back to state
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: effectiveIsDepartureReady
                                ? onMarkMenujuPenjemputan
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor: Colors.grey[400],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.play_arrow,
                                    color: Colors.white),
                                const SizedBox(width: 8),
                                Text(
                                  effectiveIsDepartureReady
                                      ? 'Mulai Tebengan'
                                      : 'Menunggu Waktu Keberangkatan',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: onCancelRide,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(
                                  color: Colors.red, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cancel_outlined, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Batalkan Tebengan',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              InfoMitraCard(
                ownerName: ownerName,
                transportasi: transportasi,
                plat: plat,
                vehicleModel: vehicleModel,
                warna: warna,
                kursi: kursi,
                isPublicTransport: rideType == 'titip',
              ),
              const SizedBox(height: 20),
              // Service Type Badge for Motor & Mobil
              if (rideType == 'motor' || rideType == 'mobil') ...[
                MitraServiceTypeBadge(
                  serviceType: ride['service_type']?.toString(),
                ),
                const SizedBox(height: 20),
              ],

              // Informasi Penebeng - berbeda untuk setiap jenis
              if (rideType == 'motor')
                PenumpangMotorSection(
                  ride: ride,
                  onChatPressed: (booking) {
                    if (booking != null) onChatPressed(booking);
                  },
                )
              else if (rideType == 'mobil')
                PenumpangMobilSection(ride: ride)
              else if (rideType == 'barang')
                PenumpangBarangSection(ride: ride)
              else if (rideType == 'titip')
                PenumpangTitipBarangSection(ride: ride),
              const SizedBox(height: 20),
              // Customer Rating Section
              CustomerRatingSection(
                status: (ride['status'] ?? '').toString().toLowerCase(),
                isCheckingRating: isCheckingRating,
                hasRating: hasRating,
                selectedRating: selectedRating,
                selectedFeedback: selectedFeedback,
                proofImage: proofImage,
                isSubmittingRating: isSubmittingRating,
                customerName: customerName,
                feedbackOptions: feedbackOptions,
                onRatingChanged: onRatingChanged,
                onFeedbackToggled: onFeedbackToggled,
                onPickImage: onPickImage,
                onSubmitRating: onSubmitRating,
              ),
              // QR Code Section
              if (currentStatus == 'sudah_sampai_tujuan')
                QrCodeSection(
                  qrCodeData: ride['qr_code_data'] as String?,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
