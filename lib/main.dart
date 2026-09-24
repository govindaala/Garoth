import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://dcbtdftgjyokioqcpumv.supabase.co',
    anonKey: 'sb_publishable_u6nxcL145Z-HsaKiOlfjoQ_DCvKJrGO',
  );

  runApp(const GuidelineApp());
}

final supabase = Supabase.instance.client;

class GuidelineApp extends StatelessWidget {
  const GuidelineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'कलेक्टर गाइडलाइन पोर्टल',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E3A8A),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<String> districts = [];
  List<String> tehsils = [];
  List<String> villages = [];
  List<String> wards = [];

  String? selectedDistrict;
  String? selectedTehsil;
  String? selectedVillage;
  String? selectedWard;

  Map<String, dynamic>? selectedRecord;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadDistricts();
  }

  // 1. ज़िला लोड करें
  Future<void> loadDistricts() async {
    try {
      final data = await supabase.from('guidelines').select('district');
      final unique = data.map((e) => e['district'].toString()).toSet().toList();
      setState(() {
        districts = unique;
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  // 2. तहसील लोड करें
  Future<void> loadTehsils(String district) async {
    final data = await supabase.from('guidelines').select('tehsil').eq('district', district);
    final unique = data.map((e) => e['tehsil'].toString()).toSet().toList();
    setState(() {
      tehsils = unique;
      selectedTehsil = null;
      villages = [];
      selectedVillage = null;
      wards = [];
      selectedWard = null;
      selectedRecord = null;
    });
  }

  // 3. गाँव / शहर लोड करें
  Future<void> loadVillages(String tehsil) async {
    final data = await supabase
        .from('guidelines')
        .select('village')
        .eq('district', selectedDistrict!)
        .eq('tehsil', tehsil);
    final unique = data.map((e) => e['village'].toString()).toSet().toList();
    setState(() {
      villages = unique;
      selectedVillage = null;
      wards = [];
      selectedWard = null;
      selectedRecord = null;
    });
  }

  // 4. वार्ड / मोहल्ला लोड करें
  Future<void> loadWards(String village) async {
    final data = await supabase
        .from('guidelines')
        .select('ward')
        .eq('district', selectedDistrict!)
        .eq('tehsil', selectedTehsil!)
        .eq('village', village);
    final unique = data.map((e) => e['ward'].toString()).toSet().toList();
    setState(() {
      wards = unique;
      selectedWard = null;
      selectedRecord = null;
    });
  }

  // 5. पूर्ण गाइडलाइन डेटा लोड करें
  Future<void> fetchRecord(String ward) async {
    setState(() => isLoading = true);
    final data = await supabase
        .from('guidelines')
        .select()
        .eq('district', selectedDistrict!)
        .eq('tehsil', selectedTehsil!)
        .eq('village', selectedVillage!)
        .eq('ward', ward)
        .limit(1);

    if (data.isNotEmpty) {
      setState(() {
        selectedRecord = data[0];
      });
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'कलेक्टर गाइडलाइन मूल्यांकन',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'स्थान का चयन करें (Location Filter)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                    ),
                    const SizedBox(height: 12),
                    buildDropdownField('ज़िला', districts, selectedDistrict, (val) {
                      setState(() => selectedDistrict = val);
                      if (val != null) loadTehsils(val);
                    }),
                    const SizedBox(height: 10),
                    buildDropdownField('तहसील', tehsils, selectedTehsil, (val) {
                      setState(() => selectedTehsil = val);
                      if (val != null) loadVillages(val);
                    }),
                    const SizedBox(height: 10),
                    buildDropdownField('गाँव / शहर', villages, selectedVillage, (val) {
                      setState(() => selectedVillage = val);
                      if (val != null) loadWards(val);
                    }),
                    const SizedBox(height: 10),
                    buildDropdownField('वार्ड / मोहल्ला / कालोनी', wards, selectedWard, (val) {
                      setState(() => selectedWard = val);
                      if (val != null) fetchRecord(val);
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (selectedRecord != null)
              buildValuationReport(selectedRecord!),
          ],
        ),
      ),
    );
  }

  Widget buildDropdownField(
    String hint,
    List<String> items,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          value: selectedValue,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 14)));
          }).toList(),
          onChanged: items.isEmpty ? null : onChanged,
        ),
      ),
    );
  }

  Widget buildValuationReport(Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${data['village']} - ${data['ward']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'तहसील: ${data['tehsil']} | ज़िला: ${data['district']}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'हल्का नं: ${data['halka_no'] ?? '-'}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // दर ग्रिड (Rates 2x2 Grid)
        Row(
          children: [
            Expanded(
              child: buildRateBox('🏠 आवासीय दर', '₹ ${data['residential_rate']}', 'प्रति वर्ग मीटर', Colors.blue.shade50, Colors.blue.shade900),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: buildRateBox('🏢 व्यावसायिक दर', '₹ ${data['commercial_rate']}', 'प्रति वर्ग मीटर', Colors.amber.shade50, Colors.amber.shade900),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: buildRateBox('🌾 कृषि (सिंचित)', '₹ ${data['agri_irrigated']}', 'प्रति हेक्टेयर', Colors.green.shade50, Colors.green.shade900),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: buildRateBox('🚜 कृषि (असिंचित)', '₹ ${data['agri_unirrigated']}', 'प्रति हेक्टेयर', Colors.orange.shade50, Colors.orange.shade900),
            ),
          ],
        ),

        const SizedBox(height: 12),

        if (data['details'] != null && data['details'].toString().isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'विशेष विवरण: ${data['details']}',
                    style: const TextStyle(fontSize: 13, color: Colors.blueGrey),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget buildRateBox(String title, String rate, String unit, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 6),
          Text(rate, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 2),
          Text(unit, style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7))),
        ],
      ),
    );
  }
}
