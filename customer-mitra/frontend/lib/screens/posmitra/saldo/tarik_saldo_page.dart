// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'pin_verification_page.dart';
// import '/services/posmitra/posmitra_service.dart';

// class TarikSaldoPage extends StatefulWidget {
//   final double currentBalance;

//   const TarikSaldoPage({
//     Key? key,
//     this.currentBalance = 200000,
//   }) : super(key: key);

//   @override
//   State<TarikSaldoPage> createState() => _TarikSaldoPageState();
// }

// class _TarikSaldoPageState extends State<TarikSaldoPage> {
//   final TextEditingController _amountController = TextEditingController();
//   final TextEditingController _bankController = TextEditingController();
//   final TextEditingController _accountNumberController = TextEditingController();
  
//   String? errorMessage;
//   String userName = '-';
//   bool isLoadingProfile = true;

//   @override
//   void initState() {
//     super.initState();
//     _loadUserProfile();
//   }

//   @override
//   void dispose() {
//     _amountController.dispose();
//     _bankController.dispose();
//     _accountNumberController.dispose();
//     super.dispose();
//   }

//   // ✅ Load user profile dari database
// // ✅ Load user profile dari database
// Future<void> _loadUserProfile() async {
//   try {
//     final prefs = await SharedPreferences.getInstance();
//     final token = prefs.getString('api_token');

//     if (token == null || token.isEmpty) {
//       setState(() {
//         userName = 'User';
//         isLoadingProfile = false;
//       });
//       return;
//     }

//     // ✅ Gunakan getProfile yang sudah ada
//     final response = await PosMitraService.getProfile(token);
    
//     if (response['success'] == true) {
//       final userData = response['data']?['user'] as Map<String, dynamic>?;
//       setState(() {
//         userName = userData?['name'] ?? 'User';
//         isLoadingProfile = false;
//       });
//     } else {
//       setState(() {
//         userName = 'User';
//         isLoadingProfile = false;
//       });
//     }
//   } catch (e) {
//     print('Error loading profile: $e');
//     setState(() {
//       userName = 'User';
//       isLoadingProfile = false;
//     });
//   }
// }
//   void _validateAndProceed() {
//     setState(() {
//       errorMessage = null;
//     });

//     final inputText = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    
//     if (inputText.isEmpty) {
//       setState(() {
//         errorMessage = 'Masukkan nominal saldo yang akan ditarik';
//       });
//       return;
//     }

//     final amount = double.tryParse(inputText);
    
//     if (amount == null) {
//       setState(() {
//         errorMessage = 'Nominal tidak valid';
//       });
//       return;
//     }

//     if (amount > widget.currentBalance) {
//       setState(() {
//         errorMessage = 'Jumlah saldo tidak mencukupi';
//       });
//       return;
//     }

//     if (amount < 50000) {
//       setState(() {
//         errorMessage = 'Minimal penarikan adalah Rp 50.000';
//       });
//       return;
//     }

//     // ✅ Validasi bank dan nomor rekening
//     final bank = _bankController.text.trim();
//     final accountNumber = _accountNumberController.text.trim();

//     if (bank.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Masukkan nama bank')),
//       );
//       return;
//     }

//     if (accountNumber.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Masukkan nomor rekening')),
//       );
//       return;
//     }

//     // Success - navigate to PIN verification
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => PinVerificationPage(
//           amount: amount,
//           bankName: bank,
//           accountNumber: accountNumber,
//         ),
//       ),
//     );
//   }

//   String _formatCurrency(double amount) {
//     final formatted = amount.toStringAsFixed(0);
//     final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
//     return formatted.replaceAllMapped(regex, (match) => '.');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF5F5F5),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Tarik Saldo',
//           style: TextStyle(
//             color: Color(0xFF212121),
//             fontSize: 18,
//             fontWeight: FontWeight.w600,
//           ),
//         ),
//         centerTitle: false,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Informasi Saldo Card
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.06),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Informasi Saldo',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF212121),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             const Text(
//                               'Nama',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Color(0xFF757575),
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                             const Text(
//                               'Saldo',
//                               style: TextStyle(
//                                 fontSize: 14,
//                                 color: Color(0xFF757575),
//                                 fontWeight: FontWeight.w400,
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 8),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             // ✅ Nama dari database
//                             isLoadingProfile
//                                 ? const Text(
//                                     'Loading...',
//                                     style: TextStyle(
//                                       fontSize: 15,
//                                       color: Color(0xFF757575),
//                                       fontWeight: FontWeight.w400,
//                                     ),
//                                   )
//                                 : Text(
//                                     userName,
//                                     style: const TextStyle(
//                                       fontSize: 15,
//                                       color: Color(0xFF212121),
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                             Text(
//                               'Rp ${_formatCurrency(widget.currentBalance)}',
//                               style: const TextStyle(
//                                 fontSize: 15,
//                                 color: Color(0xFF212121),
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   // ✅ Informasi Rekening Card (Editable)
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.06),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Informasi Rekening',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w700,
//                             color: Color(0xFF212121),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
                        
//                         // Input Nama Bank
//                         const Text(
//                           'Nama Bank',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Color(0xFF757575),
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         TextField(
//                           controller: _bankController,
//                           style: const TextStyle(
//                             fontSize: 15,
//                             color: Color(0xFF212121),
//                             fontWeight: FontWeight.w500,
//                           ),
//                           decoration: InputDecoration(
//                             hintText: 'Contoh: BRI, BCA, Mandiri',
//                             hintStyle: TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey[400],
//                               fontWeight: FontWeight.w400,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xFFF5F5F5),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFF1E3A8A),
//                                 width: 1.5,
//                               ),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 14,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 16),
                        
//                         // Input Nomor Rekening
//                         const Text(
//                           'Nomor Rekening',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Color(0xFF757575),
//                             fontWeight: FontWeight.w400,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         TextField(
//                           controller: _accountNumberController,
//                           keyboardType: TextInputType.number,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly,
//                           ],
//                           style: const TextStyle(
//                             fontSize: 15,
//                             color: Color(0xFF212121),
//                             fontWeight: FontWeight.w500,
//                           ),
//                           decoration: InputDecoration(
//                             hintText: 'Masukkan nomor rekening',
//                             hintStyle: TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey[400],
//                               fontWeight: FontWeight.w400,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xFFF5F5F5),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: const BorderSide(
//                                 color: Color(0xFF1E3A8A),
//                                 width: 1.5,
//                               ),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 14,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 16),
                  
//                   // Masukkan Jumlah
//                   Container(
//                     padding: const EdgeInsets.all(20),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.06),
//                           blurRadius: 8,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Masukkan Jumlah',
//                           style: TextStyle(
//                             fontSize: 14,
//                             color: Color(0xFF212121),
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                         const SizedBox(height: 12),
//                         TextField(
//                           controller: _amountController,
//                           keyboardType: TextInputType.number,
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly,
//                           ],
//                           style: const TextStyle(
//                             fontSize: 15,
//                             color: Color(0xFF212121),
//                             fontWeight: FontWeight.w500,
//                           ),
//                           decoration: InputDecoration(
//                             hintText: 'Masukkan nominal saldo yang akan ditarik',
//                             hintStyle: TextStyle(
//                               fontSize: 13,
//                               color: Colors.grey[400],
//                               fontWeight: FontWeight.w400,
//                             ),
//                             filled: true,
//                             fillColor: const Color(0xFFF5F5F5),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide.none,
//                             ),
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: errorMessage != null
//                                   ? const BorderSide(
//                                       color: Color(0xFFEF5350),
//                                       width: 1,
//                                     )
//                                   : BorderSide.none,
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                               borderSide: BorderSide(
//                                 color: errorMessage != null
//                                     ? const Color(0xFFEF5350)
//                                     : const Color(0xFF1E3A8A),
//                                 width: 1.5,
//                               ),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(
//                               horizontal: 16,
//                               vertical: 14,
//                             ),
//                           ),
//                           onChanged: (value) {
//                             if (errorMessage != null) {
//                               setState(() {
//                                 errorMessage = null;
//                               });
//                             }
//                           },
//                         ),
//                         if (errorMessage != null) ...[
//                           const SizedBox(height: 8),
//                           Text(
//                             errorMessage!,
//                             style: const TextStyle(
//                               fontSize: 12,
//                               color: Color(0xFFEF5350),
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           // Lanjut Button
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.06),
//                   blurRadius: 10,
//                   offset: const Offset(0, -2),
//                 ),
//               ],
//             ),
//             child: SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _validateAndProceed,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF1E3A8A),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 0,
//                 ),
//                 child: const Text(
//                   'Lanjut',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                     color: Colors.white,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pin_verification_page.dart';
import '/services/posmitra/posmitra_service.dart';

class TarikSaldoPage extends StatefulWidget {
  final double currentBalance;

  const TarikSaldoPage({
    Key? key,
    this.currentBalance = 200000,
  }) : super(key: key);

  @override
  State<TarikSaldoPage> createState() => _TarikSaldoPageState();
}

class _TarikSaldoPageState extends State<TarikSaldoPage> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  
  String? errorMessage;
  String userName = '-';
  bool isLoadingProfile = true;
  bool hasAccountInfo = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _bankController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    super.dispose();
  }

  // ✅ Load user profile dan data rekening dari database
  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('api_token');

      if (token == null || token.isEmpty) {
        setState(() {
          userName = 'User';
          isLoadingProfile = false;
        });
        return;
      }

      // ✅ Ambil data profil termasuk rekening bank
      final response = await PosMitraService.getProfile(token);
      
      if (response['success'] == true) {
        final userData = response['data']?['user'] as Map<String, dynamic>?;
        
        setState(() {
          userName = userData?['name'] ?? 'User';
          
          // ✅ Isi data rekening bank jika ada
          final bankName = userData?['bank_name'];
          final accountNumber = userData?['bank_account_number'];
          final accountName = userData?['bank_account_name'];
          
          if (bankName != null && bankName.isNotEmpty) {
            _bankController.text = bankName;
            hasAccountInfo = true;
          }
          
          if (accountNumber != null && accountNumber.isNotEmpty) {
            _accountNumberController.text = accountNumber;
          }
          
          if (accountName != null && accountName.isNotEmpty) {
            _accountNameController.text = accountName;
          }
          
          isLoadingProfile = false;
        });
      } else {
        setState(() {
          userName = 'User';
          isLoadingProfile = false;
        });
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        userName = 'User';
        isLoadingProfile = false;
      });
    }
  }

  void _validateAndProceed() {
    setState(() {
      errorMessage = null;
    });

    final inputText = _amountController.text.replaceAll('.', '').replaceAll(',', '');
    
    if (inputText.isEmpty) {
      setState(() {
        errorMessage = 'Masukkan nominal saldo yang akan ditarik';
      });
      return;
    }

    final amount = double.tryParse(inputText);
    
    if (amount == null) {
      setState(() {
        errorMessage = 'Nominal tidak valid';
      });
      return;
    }

    if (amount > widget.currentBalance) {
      setState(() {
        errorMessage = 'Jumlah saldo tidak mencukupi';
      });
      return;
    }

    if (amount < 50000) {
      setState(() {
        errorMessage = 'Minimal penarikan adalah Rp 50.000';
      });
      return;
    }

    // ✅ Validasi bank, nomor rekening, dan atas nama
    final bank = _bankController.text.trim();
    final accountNumber = _accountNumberController.text.trim();
    final accountName = _accountNameController.text.trim();

    if (bank.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama bank')),
      );
      return;
    }

    if (accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nomor rekening')),
      );
      return;
    }

    if (accountName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nama pemilik rekening')),
      );
      return;
    }

    // Success - navigate to PIN verification
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PinVerificationPage(
          amount: amount,
          bankName: bank,
          accountNumber: accountNumber,
          accountName: accountName,
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    final formatted = amount.toStringAsFixed(0);
    final regex = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return formatted.replaceAllMapped(regex, (match) => '.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Tarik Saldo',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: isLoadingProfile
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Informasi Saldo Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informasi Saldo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF212121),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Nama',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF757575),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const Text(
                                    'Saldo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF757575),
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    userName,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF212121),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Rp ${_formatCurrency(widget.currentBalance)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF212121),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // ✅ Informasi Rekening Card (Editable atau Read-only)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Informasi Rekening',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF212121),
                                    ),
                                  ),
                                  if (hasAccountInfo)
                                    TextButton.icon(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/pengaturan');
                                      },
                                      icon: const Icon(
                                        Icons.edit,
                                        size: 16,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                      label: const Text(
                                        'Ubah',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1E3A8A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Input Nama Bank
                              const Text(
                                'Nama Bank',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _bankController,
                                enabled: !hasAccountInfo,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF212121),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Contoh: BRI, BCA, Mandiri',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: hasAccountInfo 
                                      ? Colors.grey[100]
                                      : const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E3A8A),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Input Nomor Rekening
                              const Text(
                                'Nomor Rekening',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _accountNumberController,
                                enabled: !hasAccountInfo,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF212121),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan nomor rekening',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: hasAccountInfo 
                                      ? Colors.grey[100]
                                      : const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E3A8A),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              // Input Atas Nama
                              const Text(
                                'Atas Nama',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF757575),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _accountNameController,
                                enabled: !hasAccountInfo,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF212121),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Nama pemilik rekening',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: hasAccountInfo 
                                      ? Colors.grey[100]
                                      : const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF1E3A8A),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Masukkan Jumlah
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Masukkan Jumlah',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF212121),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _amountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Color(0xFF212121),
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Masukkan nominal saldo yang akan ditarik',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[400],
                                    fontWeight: FontWeight.w400,
                                  ),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: errorMessage != null
                                        ? const BorderSide(
                                            color: Color(0xFFEF5350),
                                            width: 1,
                                          )
                                        : BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: errorMessage != null
                                          ? const Color(0xFFEF5350)
                                          : const Color(0xFF1E3A8A),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (errorMessage != null) {
                                    setState(() {
                                      errorMessage = null;
                                    });
                                  }
                                },
                              ),
                              if (errorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFEF5350),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Lanjut Button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _validateAndProceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lanjut',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}