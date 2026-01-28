import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TestFirestorePage extends StatelessWidget {
  const TestFirestorePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Test Firestore')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                print('🧪 Testing Firestore connection...');
                try {
                  final result = await FirebaseFirestore.instance
                      .collection('conversations')
                      .get()
                      .timeout(Duration(seconds: 10));

                  print('✅ SUCCESS! Got ${result.docs.length} documents');
                  for (var doc in result.docs) {
                    print('📄 ${doc.id}: ${doc.data()}');
                  }

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          Text('✅ Success! ${result.docs.length} documents'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e, stackTrace) {
                  print('❌ ERROR: $e');
                  print('Stack: $stackTrace');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 5),
                    ),
                  );
                }
              },
              child: Text('Test Firestore GET'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                print('🧪 Testing Firestore Stream...');
                try {
                  final stream = FirebaseFirestore.instance
                      .collection('conversations')
                      .snapshots();

                  stream.listen(
                    (snapshot) {
                      print('✅ STREAM DATA: ${snapshot.docs.length} documents');
                      for (var doc in snapshot.docs) {
                        print('📄 ${doc.id}: ${doc.data()}');
                      }
                    },
                    onError: (error) {
                      print('❌ STREAM ERROR: $error');
                    },
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stream started - check console')),
                  );
                } catch (e) {
                  print('❌ ERROR: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('❌ Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Test Firestore STREAM'),
            ),
          ],
        ),
      ),
    );
  }
}
